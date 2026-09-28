// EdgeFadeBackground.qml
// Canvas-based edge-fade background without visible seams.
//
// Rendering strategy (seam-free):
//   1. Fill entire canvas with centerAlpha (solid base).
//   2. Paint edge bands on TOP using "destination-out" composite operation.
//      destination-out erases alpha from the already-painted base —
//      result alpha = base_alpha * (1 - src_alpha). No colour added, only
//      transparency punched through. Gradients go from transparent (at the
//      centre boundary) to opaque-enough-to-reach-edgeAlpha (at the edge).
//   3. Corners get the same treatment via radialGradient.
//   4. Restore composite mode to "source-over" for any future layers.
//
// Because we only erase, adjacent zones (side + corner) never double-paint
// colour — there are no RGB seams regardless of baseColor or alpha values.
//
// NOTE (future): A QSB-compiled ShaderEffect would deliver the same quality
// at GPU cost (zero CPU) and supports animations without requestPaint().

import QtQuick

Item {
    id: root

    // ── Public API ───────────────────────────────────────────────────────
    property color baseColor:   "black"
    property real  centerAlpha: 0.4     // alpha of the solid center region
    property real  edgeAlpha:   1.0     // 1.0 = fully transparent edge
    property real  fadeWidth:   30      // px from each edge
    property real  curve:       0.0     // -1..+1, controls gradient falloff
    property real  radius:      0       // corner radius, px

    // ── Internal ────────────────────────────────────────────────────────
    readonly property real _fw:  Math.max(0, Math.min(fadeWidth, Math.min(width, height) * 0.45))
    readonly property real _ea:  Math.max(0.0, Math.min(1.0, edgeAlpha))
    readonly property real _exp: Math.max(0.25, 2.0 + curve * 2.0)

    function _rgba(r, g, b, a) {
        return "rgba(" + r + "," + g + "," + b + "," + Math.max(0, Math.min(1, a)) + ")"
    }

    // Erase-alpha at position t∈[0,1] where 0=centre-boundary, 1=outer-edge.
    // Returns the alpha to punch OUT of the base via destination-out.
    // At t=0 we erase nothing (0); at t=1 we erase enough to land on edgeAlpha.
    function _eraseAlpha(t) {
        var s        = Math.pow(Math.max(0, Math.min(1, t)), _exp)
        // target alpha at this position
        var targetA  = centerAlpha * (1.0 - _ea) + (1.0 - s) * (centerAlpha - centerAlpha * (1.0 - _ea))
        // We need: base * (1 - eraseA) = targetA  =>  eraseA = 1 - targetA/base
        if (centerAlpha <= 0) return 0
        return Math.max(0, Math.min(1, 1.0 - targetA / centerAlpha))
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            var w   = width
            var h   = height
            var fw  = root._fw
            var r   = root.radius
            var br  = Math.round(root.baseColor.r * 255)
            var bg  = Math.round(root.baseColor.g * 255)
            var bb  = Math.round(root.baseColor.b * 255)

            ctx.clearRect(0, 0, w, h)

            // ── 1. Clip to rounded rect ─────────────────────────────────
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

            // ── 2. Base fill ──────────────────────────────────────────
            ctx.globalCompositeOperation = "source-over"
            ctx.fillStyle = root._rgba(br, bg, bb, root.centerAlpha)
            ctx.fillRect(0, 0, w, h)

            if (fw > 0 && root._ea > 0) {
                // ── 3. Erase edges via destination-out ──────────────────
                ctx.globalCompositeOperation = "destination-out"

                var steps = 10
                var i, t, a, g

                // Helper: build an erase gradient with stops
                function eraseGrad(grad, fromCentre) {
                    for (i = 0; i <= steps; i++) {
                        // fromCentre=true: stop 0 at centre-boundary (t=0), stop N at edge (t=1)
                        t = fromCentre ? i / steps : 1.0 - i / steps
                        a = root._eraseAlpha(t)
                        grad.addColorStop(i / steps, "rgba(0,0,0," + a + ")")
                    }
                    return grad
                }

                // Top
                g = ctx.createLinearGradient(0, fw, 0, 0)
                eraseGrad(g, true)
                ctx.fillStyle = g; ctx.fillRect(fw, 0, w - fw * 2, fw)

                // Bottom
                g = ctx.createLinearGradient(0, h - fw, 0, h)
                eraseGrad(g, true)
                ctx.fillStyle = g; ctx.fillRect(fw, h - fw, w - fw * 2, fw)

                // Left
                g = ctx.createLinearGradient(fw, 0, 0, 0)
                eraseGrad(g, true)
                ctx.fillStyle = g; ctx.fillRect(0, fw, fw, h - fw * 2)

                // Right
                g = ctx.createLinearGradient(w - fw, 0, w, 0)
                eraseGrad(g, true)
                ctx.fillStyle = g; ctx.fillRect(w - fw, fw, fw, h - fw * 2)

                // Top-left corner
                g = ctx.createRadialGradient(fw, fw, 0, fw, fw, fw)
                eraseGrad(g, false)  // radial: 0=centre-of-corner(=centre boundary), fw=edge
                ctx.fillStyle = g; ctx.fillRect(0, 0, fw, fw)

                // Top-right corner
                g = ctx.createRadialGradient(w - fw, fw, 0, w - fw, fw, fw)
                eraseGrad(g, false)
                ctx.fillStyle = g; ctx.fillRect(w - fw, 0, fw, fw)

                // Bottom-left corner
                g = ctx.createRadialGradient(fw, h - fw, 0, fw, h - fw, fw)
                eraseGrad(g, false)
                ctx.fillStyle = g; ctx.fillRect(0, h - fw, fw, fw)

                // Bottom-right corner
                g = ctx.createRadialGradient(w - fw, h - fw, 0, w - fw, h - fw, fw)
                eraseGrad(g, false)
                ctx.fillStyle = g; ctx.fillRect(w - fw, h - fw, fw, fw)
            }

            // ── 4. Restore composite mode ────────────────────────────
            ctx.globalCompositeOperation = "source-over"
            if (r > 0) ctx.restore()
        }

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
