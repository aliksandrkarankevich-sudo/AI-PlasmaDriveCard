// EdgeFadeBackground.qml
// Four-sided fade-to-transparent background for Drive Cards.
// Two stacked rectangles: horizontal gradient mask + vertical gradient mask.
// Their alpha values multiply at the corners, giving a smooth perimeter fade.
import QtQuick

Item {
    id: root

    // ---- inputs from parent -------------------------------------------------
    required property color  baseColor      // background colour (no alpha)
    required property real   baseAlpha      // centre opacity  0..1
    required property real   edgeAlpha      // edge   opacity  0..1 (should be <= baseAlpha)
    required property real   edgeFraction   // fade width as fraction of dimension 0..0.45
    required property real   curve          // -1..+1  negative = slow-in, positive = slow-out
    required property bool   rounded
    required property int    cornerRadius
    // ------------------------------------------------------------------------

    anchors.fill: parent

    // Helper: map normalised position p (0..1) to alpha using curve.
    // p=0 is the edge (edgeAlpha), p=1 is the centre (baseAlpha).
    function fadeAlpha(p) {
        var t = curve >= 0
            ? Math.pow(p, 1.0 + curve * 2.0)       // slow-out: lingers near edge
            : 1.0 - Math.pow(1.0 - p, 1.0 - curve * 2.0) // slow-in : quick rise then flat
        return edgeAlpha + t * (baseAlpha - edgeAlpha)
    }

    // ---- solid base (centre alpha) -----------------------------------------
    Rectangle {
        anchors.fill: parent
        radius: root.rounded ? root.cornerRadius : 0
        color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.baseAlpha)
    }

    // ---- horizontal mask (left + right fade) --------------------------------
    // Covers the full height; darkens left/right edges down to edgeAlpha.
    // When edgeWidth == 0 (edgeFraction == 0) this rectangle is invisible.
    Rectangle {
        anchors.fill: parent
        radius: root.rounded ? root.cornerRadius : 0
        visible: root.edgeFraction > 0
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            // left edge -> centre
            GradientStop { position: 0.0;                  color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0.0) }
            GradientStop { position: root.edgeFraction * 0.35; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.fadeAlpha(0.35)) }
            GradientStop { position: root.edgeFraction * 0.65; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.fadeAlpha(0.65)) }
            GradientStop { position: root.edgeFraction * 0.85; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.fadeAlpha(0.85)) }
            GradientStop { position: root.edgeFraction;        color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.baseAlpha) }
            // centre: fully transparent overlay (solid base rect below handles this)
            GradientStop { position: root.edgeFraction + 0.001; color: "transparent" }
            GradientStop { position: 1.0 - root.edgeFraction - 0.001; color: "transparent" }
            // right fade (mirror)
            GradientStop { position: 1.0 - root.edgeFraction;        color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.baseAlpha) }
            GradientStop { position: 1.0 - root.edgeFraction * 0.85; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.fadeAlpha(0.85)) }
            GradientStop { position: 1.0 - root.edgeFraction * 0.65; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.fadeAlpha(0.65)) }
            GradientStop { position: 1.0 - root.edgeFraction * 0.35; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.fadeAlpha(0.35)) }
            GradientStop { position: 1.0;                  color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0.0) }
        }
    }

    // ---- vertical mask (top + bottom fade) ----------------------------------
    Rectangle {
        anchors.fill: parent
        radius: root.rounded ? root.cornerRadius : 0
        visible: root.edgeFraction > 0
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0;                  color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0.0) }
            GradientStop { position: root.edgeFraction * 0.35; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.fadeAlpha(0.35)) }
            GradientStop { position: root.edgeFraction * 0.65; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.fadeAlpha(0.65)) }
            GradientStop { position: root.edgeFraction * 0.85; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.fadeAlpha(0.85)) }
            GradientStop { position: root.edgeFraction;        color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.baseAlpha) }
            GradientStop { position: root.edgeFraction + 0.001; color: "transparent" }
            GradientStop { position: 1.0 - root.edgeFraction - 0.001; color: "transparent" }
            GradientStop { position: 1.0 - root.edgeFraction;        color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.baseAlpha) }
            GradientStop { position: 1.0 - root.edgeFraction * 0.85; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.fadeAlpha(0.85)) }
            GradientStop { position: 1.0 - root.edgeFraction * 0.65; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.fadeAlpha(0.65)) }
            GradientStop { position: 1.0 - root.edgeFraction * 0.35; color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.fadeAlpha(0.35)) }
            GradientStop { position: 1.0;                  color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0.0) }
        }
    }
}
