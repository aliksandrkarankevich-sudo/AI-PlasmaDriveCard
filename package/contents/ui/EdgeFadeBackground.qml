// EdgeFadeBackground.qml
// Four-sided edge fade using four LinearGradient overlays.
// No Canvas, no pixel loop — fully GPU-accelerated.
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property color baseColor:   "black"
    property real  centerAlpha: 0.4
    property real  edgeAlpha:   1.0
    property real  fadeWidth:   30
    property real  curve:       0.0   // reserved for future use, currently unused
    property real  radius:      0

    readonly property real _edgeFinal: centerAlpha * Math.max(0.0, 1.0 - Math.max(0.0, Math.min(1.0, edgeAlpha)))
    readonly property color _centerColor: Qt.rgba(baseColor.r, baseColor.g, baseColor.b, centerAlpha)
    readonly property color _edgeColor:   Qt.rgba(baseColor.r, baseColor.g, baseColor.b, _edgeFinal)

    // Solid base
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root._centerColor
    }

    // Left fade
    LinearGradient {
        width: Math.min(root.fadeWidth, parent.width / 2)
        height: parent.height
        anchors.left: parent.left
        start: Qt.point(0, 0); end: Qt.point(width, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: root._edgeColor }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Right fade
    LinearGradient {
        width: Math.min(root.fadeWidth, parent.width / 2)
        height: parent.height
        anchors.right: parent.right
        start: Qt.point(0, 0); end: Qt.point(width, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: root._edgeColor }
        }
    }

    // Top fade
    LinearGradient {
        width: parent.width
        height: Math.min(root.fadeWidth, parent.height / 2)
        anchors.top: parent.top
        start: Qt.point(0, 0); end: Qt.point(0, height)
        gradient: Gradient {
            GradientStop { position: 0.0; color: root._edgeColor }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Bottom fade
    LinearGradient {
        width: parent.width
        height: Math.min(root.fadeWidth, parent.height / 2)
        anchors.bottom: parent.bottom
        start: Qt.point(0, 0); end: Qt.point(0, height)
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: root._edgeColor }
        }
    }
}
