// EdgeFadeBackground.qml
// Four-sided edge fade: solid centre Rectangle + four transparent-to-color
// LinearGradient strips on each edge. Fully GPU-accelerated, no Canvas.
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property color baseColor:   "black"
    property real  centerAlpha: 0.4   // alpha of the solid centre (0..1)
    property real  edgeAlpha:   1.0   // 0 = same as centre, 1 = fully transparent edge
    property real  fadeWidth:   30    // px — width of fade band on each side
    property real  curve:       0.0   // reserved
    property real  radius:      0

    // Alpha at the very edge: 0 when edgeAlpha==1, same as centre when edgeAlpha==0
    readonly property real  _ea:          Math.max(0.0, Math.min(1.0, edgeAlpha))
    readonly property real  _edgeFinal:   centerAlpha * (1.0 - _ea)
    readonly property color _centerColor: Qt.rgba(baseColor.r, baseColor.g, baseColor.b, centerAlpha)
    readonly property color _edgeColor:   Qt.rgba(baseColor.r, baseColor.g, baseColor.b, _edgeFinal)
    readonly property real  _fw:          Math.max(0, Math.min(fadeWidth, Math.min(width, height) / 2))

    // Solid background at full centre alpha
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root._centerColor
    }

    // Left fade: edgeColor -> centerColor
    LinearGradient {
        visible: root._fw > 0 && root._ea > 0.001
        width: root._fw; height: parent.height
        anchors.left: parent.left
        start: Qt.point(0, 0); end: Qt.point(width, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: root._edgeColor }
            GradientStop { position: 1.0; color: root._centerColor }
        }
    }

    // Right fade: centerColor -> edgeColor
    LinearGradient {
        visible: root._fw > 0 && root._ea > 0.001
        width: root._fw; height: parent.height
        anchors.right: parent.right
        start: Qt.point(0, 0); end: Qt.point(width, 0)
        gradient: Gradient {
            GradientStop { position: 0.0; color: root._centerColor }
            GradientStop { position: 1.0; color: root._edgeColor }
        }
    }

    // Top fade: edgeColor -> centerColor
    LinearGradient {
        visible: root._fw > 0 && root._ea > 0.001
        width: parent.width; height: root._fw
        anchors.top: parent.top
        start: Qt.point(0, 0); end: Qt.point(0, height)
        gradient: Gradient {
            GradientStop { position: 0.0; color: root._edgeColor }
            GradientStop { position: 1.0; color: root._centerColor }
        }
    }

    // Bottom fade: centerColor -> edgeColor
    LinearGradient {
        visible: root._fw > 0 && root._ea > 0.001
        width: parent.width; height: root._fw
        anchors.bottom: parent.bottom
        start: Qt.point(0, 0); end: Qt.point(0, height)
        gradient: Gradient {
            GradientStop { position: 0.0; color: root._centerColor }
            GradientStop { position: 1.0; color: root._edgeColor }
        }
    }
}
