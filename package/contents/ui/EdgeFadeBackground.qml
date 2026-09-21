// EdgeFadeBackground.qml
// Four-sided fade: solid centre fading to transparent at all four edges.
// Implementation: solid Rectangle at edgeFinalAlpha + one Canvas that
// paints a 2-D multiplicative fade mask using horizontal and vertical
// ease curves.  No ShaderEffect → compatible with all GPU drivers on
// Plasma 6 / Qt 6.x.
import QtQuick

Item {
    id: root

    // ── Public API ────────────────────────────────────────────────────────────
    property color baseColor:   "black"
    property real  centerAlpha: 0.4   // opacity of the solid centre  (0..1)
    property real  edgeAlpha:   1.0   // 0 = same as centre, 1 = fully transparent edge
    property real  fadeWidth:   30    // px — width of the fade band on each side
    property real  curve:       0.0   // -1..1: >0 slow-start at edge, <0 fast-start at edge
    property real  radius:      0     // corner radius in px

    // ── Derived (read-only) ───────────────────────────────────────────────────
    // Alpha at the very edge after applying edgeAlpha attenuation
    readonly property real _edgeFinal: centerAlpha * Math.max(0.0, 1.0 - Math.max(0.0, Math.min(1.0, edgeAlpha)))

    // How much alpha the overlay needs to ADD at the centre of each fade band
    // so that base + overlay = centerAlpha.  Guard against centerAlpha==0.
    readonly property real _delta: Math.max(0.0, centerAlpha - _edgeFinal)

    // Fade fraction (0..0.48) relative to each axis independently,
    // so the fade band is the same pixel width on all four sides.
    readonly property real _fwH: (fadeWidth <= 0 || _delta < 0.001 || width  < 1) ? 0.0
        : Math.min(0.48, fadeWidth / width)
    readonly property real _fwV: (fadeWidth <= 0 || _delta < 0.001 || height < 1) ? 0.0
        : Math.min(0.48, fadeWidth / height)

    // Map progress t (0=edge, 1=centre) through the curve.
    // curve > 0 → ease-in: slow start at edge, accelerates toward centre
    //             (Math.pow(t, exp>1) is near-zero for small t)
    // curve < 0 → ease-out: fast start at edge, decelerates toward centre
    function _ease(t) {
        var c = Math.max(-1.0, Math.min(1.0, curve))
        if (Math.abs(c) < 0.01) return t
        var exp = (c > 0) ? (1.0 + c * 2.0) : (1.0 / (1.0 - c * 2.0))
        return Math.pow(Math.max(0.0, Math.min(1.0, t)), exp)
    }

    // Pre-computed ease values at the two interior GradientStop positions.
    // Cached as properties so resize events (width/height) do not trigger
    // redundant Math.pow calls — these only recompute when `curve` changes.
    readonly property real _ease35: _ease(0.35)
    readonly property real _ease65: _ease(0.65)

    // ── Layer 1: Solid base at edgeFinalAlpha ─────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._edgeFinal)
    }

    // ── Layer 2: 2-D multiplicative fade via Canvas ───────────────────────────
    // For each pixel (px, py) we compute:
    //   fadeH(px) = _delta * (1 - _ease(distFromEdgeH / fadeWidthPx))   in fade band, else 0
    //   fadeV(py) = _delta * (1 - _ease(distFromEdgeV / fadeWidthPx))   in fade band, else 0
    // The total overlay alpha uses multiplicative composition so corners are
    // correct at any curve value:
    //   overlay(px,py) = fadeH + fadeV - fadeH*fadeV/_delta   (when _delta > 0)
    // This ensures alpha_corner = _edgeFinal (not _edgeFinal + 2*_delta).
    Canvas {
        id: fadeCanvas
        anchors.fill: parent
        visible: root._fwH > 0.0 || root._fwV > 0.0

        // Repaint whenever any visual parameter changes
        onWidthChanged:     requestPaint()
        onHeightChanged:    requestPaint()
        Component.onCompleted: requestPaint()

        Connections {
            target: root
            function on_DeltaChanged()    { fadeCanvas.requestPaint() }
            function on_FwHChanged()      { fadeCanvas.requestPaint() }
            function on_FwVChanged()      { fadeCanvas.requestPaint() }
            function on_Ease35Changed()   { fadeCanvas.requestPaint() }
            function on_Ease65Changed()   { fadeCanvas.requestPaint() }
            function onBaseColorChanged() { fadeCanvas.requestPaint() }
        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            if (root._delta < 0.001) return

            var W  = width
            var H  = height
            var fwHpx = root._fwH * W   // fade band width in pixels (horizontal)
            var fwVpx = root._fwV * H   // fade band height in pixels (vertical)
            var d  = root._delta
            var r  = root.baseColor.r * 255
            var g  = root.baseColor.g * 255
            var b  = root.baseColor.b * 255

            var imgData = ctx.createImageData(W, H)
            var pixels  = imgData.data

            for (var py = 0; py < H; ++py) {
                // Vertical fade factor at this row
                var tv = -1.0   // sentinel: no vertical band
                if (fwVpx > 0.5) {
                    if (py < fwVpx)      tv = root._ease(py / fwVpx)
                    else if (py >= H - fwVpx) tv = root._ease((H - 1 - py) / fwVpx)
                }
                var fV = (tv >= 0.0) ? d * (1.0 - tv) : 0.0

                for (var px = 0; px < W; ++px) {
                    // Horizontal fade factor at this column
                    var th = -1.0
                    if (fwHpx > 0.5) {
                        if (px < fwHpx)      th = root._ease(px / fwHpx)
                        else if (px >= W - fwHpx) th = root._ease((W - 1 - px) / fwHpx)
                    }
                    var fH = (th >= 0.0) ? d * (1.0 - th) : 0.0

                    // Multiplicative combination: avoids double-counting in corners
                    var overlay
                    if (fH > 0.0 && fV > 0.0)
                        overlay = fH + fV - fH * fV / d
                    else
                        overlay = fH + fV

                    var idx = (py * W + px) * 4
                    pixels[idx]     = r
                    pixels[idx + 1] = g
                    pixels[idx + 2] = b
                    pixels[idx + 3] = Math.round(Math.min(1.0, overlay) * 255)
                }
            }
            ctx.putImageData(imgData, 0, 0)
        }
    }
}
