// EdgeFadeBackground.qml
// Four-sided fade from centerAlpha at the centre to transparent at all edges.
// Uses two layered Rectangles with orthogonal Gradient to avoid ShaderEffect
// compatibility issues across different GPU drivers on Plasma 6.
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

Item {
    id: root

    // Public API
    property color baseColor: "black"
    property real  centerAlpha: 0.4   // opacity of the solid centre (0..1)
    property real  edgeAlpha:   1.0   // how transparent the edge is (0 = same as centre, 1 = fully transparent)
    property real  fadeWidth:   30    // px — width of the fade band on each side
    property real  curve:       0.0   // -1..1, negative = slow start, positive = slow end
    property real  radius:      0     // corner radius in px

    // Derived
    readonly property real _edgeFinal: centerAlpha * (1.0 - Math.max(0, Math.min(1, edgeAlpha)))
    readonly property real _fw: (fadeWidth <= 0) ? 0
        : Math.min(0.48, fadeWidth / Math.max(1, Math.min(width, height)))

    // Helper: map fraction t through a soft curve
    // curve > 0  → ease-in (slow at edge, fast toward center)
    // curve < 0  → ease-out (fast at edge, slow toward center)
    function _stop(t) {
        var c = Math.max(-1, Math.min(1, curve))
        if (Math.abs(c) < 0.01) return t
        if (c > 0) return Math.pow(t, 1.0 + c * 2.0)
        return 1.0 - Math.pow(1.0 - t, 1.0 - c * 2.0)
    }

    // ── Solid centre base ────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root._edgeFinal)
    }

    // ── Horizontal fade (left & right) ───────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        visible: root._fw > 0
        gradient: Gradient {
            orientation: Gradient.Horizontal

            // LEFT edge → centre
            GradientStop {
                position: 0.0
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha * (1.0 - root._stop(0.0 / Math.max(root._fw, 0.001))))
            }
            GradientStop {
                position: root._fw * root._stop(0.33)
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha * (1.0 - root._edgeFinal / root.centerAlpha +
                                                   root._edgeFinal / root.centerAlpha * root._stop(0.33)))
            }
            GradientStop {
                position: root._fw
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha - root._edgeFinal)
            }
            // Flat centre
            GradientStop {
                position: root._fw + 0.001
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0)
            }
            GradientStop {
                position: 1.0 - root._fw - 0.001
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0)
            }
            // RIGHT centre → edge
            GradientStop {
                position: 1.0 - root._fw
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha - root._edgeFinal)
            }
            GradientStop {
                position: 1.0 - root._fw * root._stop(0.33)
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha * (1.0 - root._edgeFinal / root.centerAlpha +
                                                   root._edgeFinal / root.centerAlpha * root._stop(0.33)))
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha * (1.0 - root._stop(0.0 / Math.max(root._fw, 0.001))))
            }
        }
    }

    // ── Vertical fade (top & bottom) ─────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        visible: root._fw > 0
        gradient: Gradient {
            orientation: Gradient.Vertical

            GradientStop {
                position: 0.0
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha * (1.0 - root._stop(0.0 / Math.max(root._fw, 0.001))))
            }
            GradientStop {
                position: root._fw * root._stop(0.33)
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha * (1.0 - root._edgeFinal / root.centerAlpha +
                                                   root._edgeFinal / root.centerAlpha * root._stop(0.33)))
            }
            GradientStop {
                position: root._fw
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha - root._edgeFinal)
            }
            GradientStop {
                position: root._fw + 0.001
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0)
            }
            GradientStop {
                position: 1.0 - root._fw - 0.001
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, 0)
            }
            GradientStop {
                position: 1.0 - root._fw
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha - root._edgeFinal)
            }
            GradientStop {
                position: 1.0 - root._fw * root._stop(0.33)
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha * (1.0 - root._edgeFinal / root.centerAlpha +
                                                   root._edgeFinal / root.centerAlpha * root._stop(0.33)))
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha * (1.0 - root._stop(0.0 / Math.max(root._fw, 0.001))))
            }
        }
    }
}
