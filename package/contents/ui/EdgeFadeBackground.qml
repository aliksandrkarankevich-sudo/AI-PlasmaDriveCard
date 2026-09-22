// EdgeFadeBackground.qml
// Canvas-based edge fade background. Works in Qt6 without any external
// dependencies or precompiled shaders.
//
// Rendering model: 9 zones
//   4 corners  — radialGradient from center point outward
//   4 sides    — linearGradient perpendicular to the edge
//   1 center   — solid fill
// No zone overlaps, no corner darkening.
//
// NOTE (future): A QSB-compiled ShaderEffect would deliver the same quality
// at GPU cost (zero CPU) and supports animations without requestPaint().
// Steps when ready:
//   1. Write EdgeFade.frag (GLSL #version 440, layout std140 uniforms)
//   2. qsb --glsl "100 es,120,150" --hlsl 50 --msl 12 \
//          -o package/contents/ui/EdgeFade.frag.qsb EdgeFade.frag
//   3. Replace Canvas block with:
//        ShaderEffect {
//            anchors.fill: parent
//            fragmentShader: Qt.resolvedUrl("EdgeFade.frag.qsb")
//            property real fw: root._fwNorm
//            // ...uniforms
//        }
//   Requires: qt6-shadertools (build-time only, .qsb ships in the package)

import QtQuick

Item {
    id: root

    // ── Public API ──────────────────────────────────────────────────────────
    property color baseColor:   "black"
    property real  centerAlpha: 0.4     // alpha of the solid center region
    property real  edgeAlpha:   1.0     // 0 = no fade, 1 = fully transparent edge
    property real  fadeWidth:   30      // px from each edge
    property real  curve:       0.0     // -1..+1, controls gradient falloff shape
    property real  radius:      0       // corner radius, px

    // ── Internal helpers ────────────────────────────────────────────────────
    readonly property real _fw:  Math.max(0, Math.min(fadeWidth, Math.min(width, height) * 0.45))
    readonly property real _ea:  Math.max(0.0, Math.min(1.0, edgeAlpha))
    readonly property real _exp: Math.max(0.25, 2.0 + curve * 2.0)

    // Helper: RGBA string for canvas
    function _rgba(a) {
        var r = Math.round(baseColor.r * 255)
        var g = Math.round(baseColor.g * 255)
        var b = Math.round(baseColor.b * 255)
        return "rgba(" + r + "," + g + "," + b + "," + Math.max(0, Math.min(1, a)) + ")"
    }

    // Helper: alpha at position t∈[0,1] (0=edge, 1=center)
    function _alpha(t) {
        var s = Math.pow(Math.max(0, Math.min(1, t)), _exp)
        var edgeA  = centerAlpha * (1.0 - _ea)
        return edgeA + s * (centerAlpha - edgeA)
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        // Repaint whenever any relevant property changes
        onPaint: {
            var ctx = getContext("2d")
            var w   = width
            var h   = height
            var fw  = root._fw
            var r   = root.radius

            ctx.clearRect(0, 0, w, h)

            // ── Clip to rounded rectangle ──────────────────────────────────
            if (r > 0) {
                ctx.save()
                ctx.beginPath()
                var rr = Math.min(r, w / 2, h / 2)
                ctx.moveTo(rr, 0)
                ctx.lineTo(w - rr, 0)
                ctx.arcTo(w, 0, w, rr, rr)
                ctx.lineTo(w, h - rr)
                ctx.arcTo(w, h, w - rr, h, rr)
                ctx.lineTo(rr, h)
                ctx.arcTo(0, h, 0, h - rr, rr)
                ctx.lineTo(0, rr)
                ctx.arcTo(0, 0, rr, 0, rr)
                ctx.closePath()
                ctx.clip()
            }

            // Build gradient stops (8 levels for a smooth curve)
            function makeStops(grad, fromEdge) {
                var steps = 8
                for (var i = 0; i <= steps; i++) {
                    var t  = fromEdge ? i / steps : 1.0 - i / steps
                    var a  = root._alpha(t)
                    grad.addColorStop(i / steps, root._rgba(a))
                }
                return grad
            }

            // ── 1. Solid center ───────────────────────────────────────────
            ctx.fillStyle = root._rgba(root.centerAlpha)
            ctx.fillRect(fw, fw, w - fw * 2, h - fw * 2)

            if (fw > 0) {
                var g

                // ── 2. Top side ───────────────────────────────────────────
                g = ctx.createLinearGradient(0, 0, 0, fw)
                makeStops(g, true)  // edge→center direction
                ctx.fillStyle = g
                ctx.fillRect(fw, 0, w - fw * 2, fw)

                // ── 3. Bottom side ────────────────────────────────────────
                g = ctx.createLinearGradient(0, h, 0, h - fw)
                makeStops(g, true)
                ctx.fillStyle = g
                ctx.fillRect(fw, h - fw, w - fw * 2, fw)

                // ── 4. Left side ──────────────────────────────────────────
                g = ctx.createLinearGradient(0, 0, fw, 0)
                makeStops(g, true)
                ctx.fillStyle = g
                ctx.fillRect(0, fw, fw, h - fw * 2)

                // ── 5. Right side ─────────────────────────────────────────
                g = ctx.createLinearGradient(w, 0, w - fw, 0)
                makeStops(g, true)
                ctx.fillStyle = g
                ctx.fillRect(w - fw, fw, fw, h - fw * 2)

                // ── 6. Top-left corner ────────────────────────────────────
                g = ctx.createRadialGradient(fw, fw, 0, fw, fw, fw)
                makeStops(g, false)  // center→edge: stop 0 = center alpha
                ctx.fillStyle = g
                ctx.fillRect(0, 0, fw, fw)

                // ── 7. Top-right corner ───────────────────────────────────
                g = ctx.createRadialGradient(w - fw, fw, 0, w - fw, fw, fw)
                makeStops(g, false)
                ctx.fillStyle = g
                ctx.fillRect(w - fw, 0, fw, fw)

                // ── 8. Bottom-left corner ─────────────────────────────────
                g = ctx.createRadialGradient(fw, h - fw, 0, fw, h - fw, fw)
                makeStops(g, false)
                ctx.fillStyle = g
                ctx.fillRect(0, h - fw, fw, fw)

                // ── 9. Bottom-right corner ────────────────────────────────
                g = ctx.createRadialGradient(w - fw, h - fw, 0, w - fw, h - fw, fw)
                makeStops(g, false)
                ctx.fillStyle = g
                ctx.fillRect(w - fw, h - fw, fw, fw)
            }

            if (r > 0) ctx.restore()
        }

        // Trigger repaint when any input property changes
        Connections {
            target: root
            function onBaseColorChanged()   { canvas.requestPaint() }
            function onCenterAlphaChanged() { canvas.requestPaint() }
            function onEdgeAlphaChanged()   { canvas.requestPaint() }
            function onFadeWidthChanged()   { canvas.requestPaint() }
            function onCurveChanged()       { canvas.requestPaint() }
            function onRadiusChanged()      { canvas.requestPaint() }
        }
        onWidthChanged:  requestPaint()
        onHeightChanged: requestPaint()
    }
}
