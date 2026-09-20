// SPDX-License-Identifier: GPL-3.0-or-later
// Four-sided edge-fade background for Drive Cards 0.95.0-beta2
import QtQuick

Item {
    id: bg

    // Exposed properties — bound by parent
    property color  baseColor
    property real   centerAlpha   // opacity of the solid centre
    property real   edgeAlpha     // opacity at the four edges (0 = fully transparent)
    property real   fraction      // 0..0.45  width of the fade band, as fraction of the shorter side
    property real   curve         // -1..1    shape of the fade (negative = slow-in, positive = fast-in)
    property int    radius: 0

    // Resolved mid-stops derived from curve
    readonly property real midPos:   0.50
    readonly property real midAlpha: {
        // Hermite-like blend: at curve=0 linear; curve<0 stays near edgeAlpha longer;
        // curve>0 reaches centerAlpha faster
        var t = 0.5
        if (curve < 0) t = Math.pow(0.5, 1.0 + Math.abs(curve))
        else           t = 1.0 - Math.pow(0.5, 1.0 + curve)
        return edgeAlpha + t * (centerAlpha - edgeAlpha)
    }
    readonly property real bandH: Math.max(0, fraction) // horizontal band
    readonly property real bandV: Math.max(0, fraction) // vertical band

    // 1. Solid centre rectangle
    Rectangle {
        anchors.fill: parent
        radius: bg.radius
        color: Qt.rgba(bg.baseColor.r, bg.baseColor.g, bg.baseColor.b, bg.centerAlpha)
    }

    // 2. Horizontal fade mask (left and right edges)
    Rectangle {
        anchors.fill: parent
        radius: bg.radius
        color: "transparent"
        visible: bg.bandH > 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            // left edge: edgeAlpha → centerAlpha
            GradientStop { position: 0.0;                                     color: Qt.rgba(bg.baseColor.r, bg.baseColor.g, bg.baseColor.b, bg.edgeAlpha   - bg.centerAlpha) }
            GradientStop { position: bg.bandH * 0.5;                          color: Qt.rgba(bg.baseColor.r, bg.baseColor.g, bg.baseColor.b, bg.midAlpha    - bg.centerAlpha) }
            GradientStop { position: bg.bandH;                                color: Qt.rgba(0, 0, 0, 0) }
            // right mirror
            GradientStop { position: 1.0 - bg.bandH;                         color: Qt.rgba(0, 0, 0, 0) }
            GradientStop { position: 1.0 - bg.bandH * 0.5;                   color: Qt.rgba(bg.baseColor.r, bg.baseColor.g, bg.baseColor.b, bg.midAlpha    - bg.centerAlpha) }
            GradientStop { position: 1.0;                                     color: Qt.rgba(bg.baseColor.r, bg.baseColor.g, bg.baseColor.b, bg.edgeAlpha   - bg.centerAlpha) }
        }
    }

    // 3. Vertical fade mask (top and bottom edges)
    Rectangle {
        anchors.fill: parent
        radius: bg.radius
        color: "transparent"
        visible: bg.bandV > 0
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0;                                     color: Qt.rgba(bg.baseColor.r, bg.baseColor.g, bg.baseColor.b, bg.edgeAlpha   - bg.centerAlpha) }
            GradientStop { position: bg.bandV * 0.5;                          color: Qt.rgba(bg.baseColor.r, bg.baseColor.g, bg.baseColor.b, bg.midAlpha    - bg.centerAlpha) }
            GradientStop { position: bg.bandV;                                color: Qt.rgba(0, 0, 0, 0) }
            GradientStop { position: 1.0 - bg.bandV;                         color: Qt.rgba(0, 0, 0, 0) }
            GradientStop { position: 1.0 - bg.bandV * 0.5;                   color: Qt.rgba(bg.baseColor.r, bg.baseColor.g, bg.baseColor.b, bg.midAlpha    - bg.centerAlpha) }
            GradientStop { position: 1.0;                                     color: Qt.rgba(bg.baseColor.r, bg.baseColor.g, bg.baseColor.b, bg.edgeAlpha   - bg.centerAlpha) }
        }
    }
}
