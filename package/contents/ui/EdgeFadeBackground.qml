// EdgeFadeBackground.qml
// Canvas-based edge-fade background without visible seams.
//
// Rendering strategy:
//   1. Fill entire canvas with centerAlpha (solid base).
//   2. Use destination-out to erase alpha toward the edges.
//      Sides: linearGradient from centre-boundary (erase=0) to edge (erase=max).
//      Corners: radialGradient from corner-centre (r=0, erase=0) outward to (r=fw, erase=max).
//      This means the INNER part of the corner stays opaque, the OUTER corner fades.
//   3. Restore composite mode.

import QtQuick

Item {
    id: root

    property color baseColor:   "black"
    property real  centerAlpha: 0.4
    property real  edgeAlpha:   1.0     // 1.0 = edge fully transparent
    property real  fadeWidth:   30
    property real  curve:       0.0     // -1..+1
    property real  radius:      0

    readonly property real _fw:  Math.max(0, Math.min(fadeWidth, Math.min(width, height) * 0.45))
    readonly property real _ea:  Math.max(0.0, Math.min(1.0, edgeAlpha))
    readonly property real _exp: Math.max(0.25, 2.0 + curve * 2.0)

    // How much alpha to erase at position t∈[0,1], t=0 = centre-boundary, t=1 = outer edge
    function _eraseAlpha(t) {
        if (centerAlpha <= 0) return 0
        var s       = Math.pow(Math.max(0, Math.min(1, t)), _exp)
        var targetA = centerAlpha * (1.0 - _ea * s)
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

            // ─ 1. Clip to rounded rect ──────────────────────────────────────
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

            // ─ 2. Base fill ──────────────────────────────────────────────
            ctx.globalCompositeOperation = "source-over"
            ctx.fillStyle = "rgba(" + br + "," + bg + "," + bb + "," + root.centerAlpha + ")"
            ctx.fillRect(0, 0, w, h)

            if (fw > 0 && root._ea > 0) {
                ctx.globalCompositeOperation = "destination-out"
                var steps = 10
                var i, t, g

                // Build erase gradient: stop i/steps at t = i/steps (t=0 no erase, t=1 max erase)
                function eraseGrad(grad) {
                    for (i = 0; i <= steps; i++) {
                        t = i / steps
                        grad.addColorStop(t, "rgba(0,0,0," + root._eraseAlpha(t) + ")")
                    }
                    return grad
                }

                // Sides: gradient goes from inner edge (t=0) to outer edge (t=1)
                // Top: inner boundary at y=fw, outer at y=0
                g = ctx.createLinearGradient(0, fw, 0, 0)
                eraseGrad(g)
                ctx.fillStyle = g; ctx.fillRect(fw, 0, w - fw * 2, fw)

                // Bottom: inner at y=h-fw, outer at y=h
                g = ctx.createLinearGradient(0, h - fw, 0, h)
                eraseGrad(g)
                ctx.fillStyle = g; ctx.fillRect(fw, h - fw, w - fw * 2, fw)

                // Left: inner at x=fw, outer at x=0
                g = ctx.createLinearGradient(fw, 0, 0, 0)
                eraseGrad(g)
                ctx.fillStyle = g; ctx.fillRect(0, fw, fw, h - fw * 2)

                // Right: inner at x=w-fw, outer at x=w
                g = ctx.createLinearGradient(w - fw, 0, w, 0)
                eraseGrad(g)
                ctx.fillStyle = g; ctx.fillRect(w - fw, fw, fw, h - fw * 2)

                // Corners: radialGradient from corner-centre outward.
                // r=0 (centre of corner zone) → t=0 (no erase = opaque)
                // r=fw (outer corner edge)     → t=1 (max erase = transparent)
                // Top-left
                g = ctx.createRadialGradient(fw, fw, 0, fw, fw, fw)
                eraseGrad(g)
                ctx.fillStyle = g; ctx.fillRect(0, 0, fw, fw)

                // Top-right
                g = ctx.createRadialGradient(w - fw, fw, 0, w - fw, fw, fw)
                eraseGrad(g)
                ctx.fillStyle = g; ctx.fillRect(w - fw, 0, fw, fw)

                // Bottom-left
                g = ctx.createRadialGradient(fw, h - fw, 0, fw, h - fw, fw)
                eraseGrad(g)
                ctx.fillStyle = g; ctx.fillRect(0, h - fw, fw, fw)

                // Bottom-right
                g = ctx.createRadialGradient(w - fw, h - fw, 0, w - fw, h - fw, fw)
                eraseGrad(g)
                ctx.fillStyle = g; ctx.fillRect(w - fw, h - fw, fw, fw)
            }

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
