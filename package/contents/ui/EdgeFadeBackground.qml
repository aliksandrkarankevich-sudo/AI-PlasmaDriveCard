// EdgeFadeBackground.qml — four-sided symmetric fade overlay
import QtQuick

Item {
    id: root

    // These properties are set from the parent (main.qml)
    property color  baseColor:     "black"
    property real   centerAlpha:   0.4
    property real   edgeAlpha:     0.0
    property real   edgeFraction:  0.15   // 0..0.45, fraction of each side
    property real   curve:         0.0    // -1..1 shape of the gradient
    property real   radius:        0.0

    // Shared helper: 8-stop smooth fade from edgeAlpha → centerAlpha
    // using a simple cubic-ease shape controlled by curve (-1..1).
    // Negative curve → concave (fade lingers near edge)
    // Zero           → cosine-like balanced fade
    // Positive curve → convex (fade completes quickly)
    function _stop(t) {
        // t is 0.0 (edge) → 1.0 (centre)
        var s
        if (curve >= 0) {
            s = 1.0 - Math.pow(1.0 - t, 1.0 + curve * 2.5)
        } else {
            s = Math.pow(t, 1.0 - curve * 2.5)
        }
        return edgeAlpha + (centerAlpha - edgeAlpha) * s
    }

    // ── Solid centre fill ───────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                       root.centerAlpha)
    }

    // ── LEFT fade ───────────────────────────────────────────────────
    Rectangle {
        visible: root.edgeFraction > 0
        x: 0; y: 0
        width:  Math.round(parent.width  * root.edgeFraction)
        height: parent.height
        radius: root.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.000
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.edgeAlpha) }
            GradientStop { position: 0.143
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.143)) }
            GradientStop { position: 0.286
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.286)) }
            GradientStop { position: 0.429
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.429)) }
            GradientStop { position: 0.571
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.571)) }
            GradientStop { position: 0.714
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.714)) }
            GradientStop { position: 0.857
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.857)) }
            GradientStop { position: 1.000
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha) }
        }
    }

    // ── RIGHT fade ──────────────────────────────────────────────────
    Rectangle {
        visible: root.edgeFraction > 0
        x: parent.width - Math.round(parent.width * root.edgeFraction)
        y: 0
        width:  Math.round(parent.width  * root.edgeFraction)
        height: parent.height
        radius: root.radius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.000
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha) }
            GradientStop { position: 0.143
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.857)) }
            GradientStop { position: 0.286
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.714)) }
            GradientStop { position: 0.429
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.571)) }
            GradientStop { position: 0.571
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.429)) }
            GradientStop { position: 0.714
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.286)) }
            GradientStop { position: 0.857
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.143)) }
            GradientStop { position: 1.000
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.edgeAlpha) }
        }
    }

    // ── TOP fade ────────────────────────────────────────────────────
    Rectangle {
        visible: root.edgeFraction > 0
        x: 0; y: 0
        width:  parent.width
        height: Math.round(parent.height * root.edgeFraction)
        radius: root.radius
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.000
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.edgeAlpha) }
            GradientStop { position: 0.143
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.143)) }
            GradientStop { position: 0.286
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.286)) }
            GradientStop { position: 0.429
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.429)) }
            GradientStop { position: 0.571
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.571)) }
            GradientStop { position: 0.714
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.714)) }
            GradientStop { position: 0.857
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.857)) }
            GradientStop { position: 1.000
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha) }
        }
    }

    // ── BOTTOM fade ─────────────────────────────────────────────────
    Rectangle {
        visible: root.edgeFraction > 0
        x: 0
        y: parent.height - Math.round(parent.height * root.edgeFraction)
        width:  parent.width
        height: Math.round(parent.height * root.edgeFraction)
        radius: root.radius
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.000
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha) }
            GradientStop { position: 0.143
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.857)) }
            GradientStop { position: 0.286
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.714)) }
            GradientStop { position: 0.429
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.571)) }
            GradientStop { position: 0.571
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.429)) }
            GradientStop { position: 0.714
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.286)) }
            GradientStop { position: 0.857
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root._stop(0.143)) }
            GradientStop { position: 1.000
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.edgeAlpha) }
        }
    }
}
