// EdgeFadeBackground.qml
// Four-sided fade: solid centre fading to transparent at all four edges.
// Implementation: one solid Rectangle at edgeFinalAlpha + three additive
// gradient overlays (horizontal, vertical).  No ShaderEffect → compatible
// with all GPU drivers on Plasma 6 / Qt 6.x.
import QtQuick

Item {
    id: root

    // ── Public API ────────────────────────────────────────────────────────────
    property color baseColor:   "black"
    property real  centerAlpha: 0.4   // opacity of the solid centre  (0..1)
    property real  edgeAlpha:   1.0   // 0 = same as centre, 1 = fully transparent edge
    property real  fadeWidth:   30    // px — width of the fade band on each side
    property real  curve:       0.0   // -1..1: <0 slow-start, >0 slow-end
    property real  radius:      0     // corner radius in px

    // ── Derived (read-only) ───────────────────────────────────────────────────
    // Alpha at the very edge after applying edgeAlpha attenuation
    readonly property real _edgeFinal: centerAlpha * Math.max(0.0, 1.0 - Math.max(0.0, Math.min(1.0, edgeAlpha)))

    // How much alpha the gradient overlay needs to ADD at the centre of each fade band
    // so that base + overlay = centerAlpha.  Guard against centerAlpha==0.
    readonly property real _delta: Math.max(0.0, centerAlpha - _edgeFinal)

    // Fade fraction (0..0.48) relative to the shorter dimension
    readonly property real _fw: (fadeWidth <= 0 || _delta < 0.001) ? 0.0
        : Math.min(0.48, fadeWidth / Math.max(1.0, Math.min(width, height)))

    // Map progress t (0=edge, 1=centre) through the curve
    function _ease(t) {
        var c = Math.max(-1.0, Math.min(1.0, curve))
        if (Math.abs(c) < 0.01) return t
        // curve > 0 → ease-in (ramp up quickly away from edge)
        // curve < 0 → ease-out (ramp up slowly away from edge)
        var exp = (c > 0) ? (1.0 + c * 2.0) : (1.0 / (1.0 - c * 2.0))
        return Math.pow(Math.max(0.0, Math.min(1.0, t)), exp)
    }

    // Alpha of the gradient overlay at fractional position p (0..1) for a
    // LEFT-side fade band occupying [0 .. _fw].
    // Returns 0 outside the band and in the centre flat region.
    function _hAlphaLeft(p) {
        if (_fw < 0.001) return 0.0
        if (p > _fw) return 0.0
        var t = _ease(p / _fw)   // 0 at edge, 1 at inner edge of band
        return _delta * (1.0 - t)
    }

    // ── Layer 1: Solid base at edgeFinalAlpha ─────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._edgeFinal)
    }

    // ── Layer 2: Horizontal overlay (left + right fade) ───────────────────────
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        visible: root._fw > 0.0

        gradient: Gradient {
            orientation: Gradient.Horizontal

            // LEFT band: 5 stops from edge inward
            GradientStop { position: 0.0;              color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._delta) }
            GradientStop { position: root._fw * 0.35;  color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._delta * (1.0 - root._ease(0.35))) }
            GradientStop { position: root._fw * 0.65;  color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._delta * (1.0 - root._ease(0.65))) }
            GradientStop { position: root._fw;          color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0.0) }
            // Flat centre — zero overlay
            GradientStop { position: root._fw + 0.001; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0.0) }
            GradientStop { position: 1.0 - root._fw - 0.001; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0.0) }
            // RIGHT band: mirror of left
            GradientStop { position: 1.0 - root._fw;         color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0.0) }
            GradientStop { position: 1.0 - root._fw * 0.65;  color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._delta * (1.0 - root._ease(0.65))) }
            GradientStop { position: 1.0 - root._fw * 0.35;  color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._delta * (1.0 - root._ease(0.35))) }
            GradientStop { position: 1.0;                     color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._delta) }
        }
    }

    // ── Layer 3: Vertical overlay (top + bottom fade) ─────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        visible: root._fw > 0.0

        gradient: Gradient {
            orientation: Gradient.Vertical

            GradientStop { position: 0.0;              color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._delta) }
            GradientStop { position: root._fw * 0.35;  color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._delta * (1.0 - root._ease(0.35))) }
            GradientStop { position: root._fw * 0.65;  color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._delta * (1.0 - root._ease(0.65))) }
            GradientStop { position: root._fw;          color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0.0) }
            GradientStop { position: root._fw + 0.001; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0.0) }
            GradientStop { position: 1.0 - root._fw - 0.001; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0.0) }
            GradientStop { position: 1.0 - root._fw;         color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0.0) }
            GradientStop { position: 1.0 - root._fw * 0.65;  color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._delta * (1.0 - root._ease(0.65))) }
            GradientStop { position: 1.0 - root._fw * 0.35;  color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._delta * (1.0 - root._ease(0.35))) }
            GradientStop { position: 1.0;                     color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._delta) }
        }
    }
}
