import QtQuick

Item {
    id: root

    property color baseColor: "#20242b"
    property real backgroundOpacity: 0.4
    property real edgeTransparency: 1.0
    property real fadeWidth: 30
    property real curve: 0.0
    property bool rounded: true
    property real cornerRadius: 15

    function alphaColor(alpha) {
        return "rgba(255,255,255," + Math.max(0, Math.min(1, alpha)) + ")"
    }

    function addFadeStops(gradient, fraction) {
        var edge = Math.max(0, Math.min(1, 1.0 - root.edgeTransparency))
        if (fraction <= 0 || edge >= 0.999) {
            gradient.addColorStop(0.0, "white")
            gradient.addColorStop(1.0, "white")
            return
        }

        var exponent = Math.pow(4.0, Math.max(-1, Math.min(1, root.curve)))
        var steps = 8
        for (var i = 0; i <= steps; ++i) {
            var t = i / steps
            var alpha = edge + (1.0 - edge) * Math.pow(t, exponent)
            gradient.addColorStop(fraction * t, root.alphaColor(alpha))
        }
        for (var j = 0; j <= steps; ++j) {
            var rt = j / steps
            var ralpha = 1.0 - (1.0 - edge) * Math.pow(rt, 1.0 / exponent)
            gradient.addColorStop(1.0 - fraction + fraction * rt, root.alphaColor(ralpha))
        }
    }

    function roundedPath(ctx, width, height, radius) {
        var r = Math.max(0, Math.min(radius, Math.min(width, height) / 2))
        ctx.beginPath()
        if (r <= 0) {
            ctx.rect(0, 0, width, height)
        } else {
            ctx.moveTo(r, 0)
            ctx.lineTo(width - r, 0)
            ctx.quadraticCurveTo(width, 0, width, r)
            ctx.lineTo(width, height - r)
            ctx.quadraticCurveTo(width, height, width - r, height)
            ctx.lineTo(r, height)
            ctx.quadraticCurveTo(0, height, 0, height - r)
            ctx.lineTo(0, r)
            ctx.quadraticCurveTo(0, 0, r, 0)
        }
        ctx.closePath()
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        renderStrategy: Canvas.Cooperative

        onPaint: {
            var ctx = getContext("2d")
            var w = width
            var h = height
            ctx.clearRect(0, 0, w, h)
            if (w <= 0 || h <= 0 || root.backgroundOpacity <= 0) return

            ctx.globalCompositeOperation = "source-over"
            root.roundedPath(ctx, w, h, root.rounded ? root.cornerRadius : 0)
            ctx.fillStyle = "rgba(" + Math.round(root.baseColor.r * 255) + ","
                + Math.round(root.baseColor.g * 255) + ","
                + Math.round(root.baseColor.b * 255) + ","
                + Math.max(0, Math.min(1, root.backgroundOpacity)) + ")"
            ctx.fill()

            var horizontalFraction = Math.min(0.5, Math.max(0, root.fadeWidth) / Math.max(1, w))
            var verticalFraction = Math.min(0.5, Math.max(0, root.fadeWidth) / Math.max(1, h))

            if (horizontalFraction > 0 && root.edgeTransparency > 0) {
                ctx.globalCompositeOperation = "destination-in"
                var horizontal = ctx.createLinearGradient(0, 0, w, 0)
                root.addFadeStops(horizontal, horizontalFraction)
                ctx.fillStyle = horizontal
                ctx.fillRect(0, 0, w, h)
            }

            if (verticalFraction > 0 && root.edgeTransparency > 0) {
                ctx.globalCompositeOperation = "destination-in"
                var vertical = ctx.createLinearGradient(0, 0, 0, h)
                root.addFadeStops(vertical, verticalFraction)
                ctx.fillStyle = vertical
                ctx.fillRect(0, 0, w, h)
            }

            ctx.globalCompositeOperation = "source-over"
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    onBaseColorChanged: canvas.requestPaint()
    onBackgroundOpacityChanged: canvas.requestPaint()
    onEdgeTransparencyChanged: canvas.requestPaint()
    onFadeWidthChanged: canvas.requestPaint()
    onCurveChanged: canvas.requestPaint()
    onRoundedChanged: canvas.requestPaint()
    onCornerRadiusChanged: canvas.requestPaint()
    Component.onCompleted: canvas.requestPaint()
}
