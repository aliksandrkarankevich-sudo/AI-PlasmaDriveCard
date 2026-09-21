// EdgeFadeBackground.qml
// Four-sided edge fade: solid centre Rectangle + four LinearGradient strips.
// Gamma-corrected midpoint stop for perceptually smooth transition.
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property color baseColor:   "black"
    property real  centerAlpha: 0.4
    property real  edgeAlpha:   1.0   // 0 = same as centre, 1 = fully transparent edge
    property real  fadeWidth:   30
    property real  curve:       0.0   // reserved
    property real  radius:      0

    readonly property real  _ea:          Math.max(0.0, Math.min(1.0, edgeAlpha))
    readonly property real  _edgeFinal:   centerAlpha * (1.0 - _ea)
    readonly property real  _midAlpha:    _edgeFinal + Math.sqrt((_ea)) * (centerAlpha - _edgeFinal) * 0.5
    readonly property color _centerColor: Qt.rgba(baseColor.r, baseColor.g, baseColor.b, centerAlpha)
    readonly property color _midColor:    Qt.rgba(baseColor.r, baseColor.g, baseColor.b, _midAlpha)
    readonly property color _edgeColor:   Qt.rgba(baseColor.r, baseColor.g, baseColor.b, _edgeFinal)
    readonly property real  _fw:          Math.max(0, Math.min(fadeWidth, Math.min(width, height) / 2))

    // Solid base at centre alpha
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root._centerColor
    }

    // Left: edge -> mid -> centre
    LinearGradient {
        visible: root._fw > 0 && root._ea > 0.005
        width: root._fw; height: parent.height
        anchors.left: parent.left
        start: Qt.point(0, 0); end: Qt.point(width, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: root._edgeColor }
            GradientStop { position: 0.5; color: root._midColor }
            GradientStop { position: 1.0; color: root._centerColor }
        }
    }

    // Right: centre -> mid -> edge
    LinearGradient {
        visible: root._fw > 0 && root._ea > 0.005
        width: root._fw; height: parent.height
        anchors.right: parent.right
        start: Qt.point(0, 0); end: Qt.point(width, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: root._centerColor }
            GradientStop { position: 0.5; color: root._midColor }
            GradientStop { position: 1.0; color: root._edgeColor }
        }
    }

    // Top: edge -> mid -> centre
    LinearGradient {
        visible: root._fw > 0 && root._ea > 0.005
        width: parent.width; height: root._fw
        anchors.top: parent.top
        start: Qt.point(0, 0); end: Qt.point(0, height)
        gradient: Gradient {
            GradientStop { position: 0.0; color: root._edgeColor }
            GradientStop { position: 0.5; color: root._midColor }
            GradientStop { position: 1.0; color: root._centerColor }
        }
    }

    // Bottom: centre -> mid -> edge
    LinearGradient {
        visible: root._fw > 0 && root._ea > 0.005
        width: parent.width; height: root._fw
        anchors.bottom: parent.bottom
        start: Qt.point(0, 0); end: Qt.point(0, height)
        gradient: Gradient {
            GradientStop { position: 0.0; color: root._centerColor }
            GradientStop { position: 0.5; color: root._midColor }
            GradientStop { position: 1.0; color: root._edgeColor }
        }
    }
}
