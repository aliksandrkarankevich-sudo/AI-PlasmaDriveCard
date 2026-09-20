// SPDX-License-Identifier: GPL-3.0-or-later
// Four-sided edge-fade background — Drive Cards 0.95.0-beta2
//
// Architecture:
//   Layer 0 – solid Rectangle filled with baseColor @ centerAlpha (the "centre")
//   Layer 1 – horizontal Rectangle whose gradient alpha goes from edgeAlpha→centerAlpha
//              on left, and centerAlpha→edgeAlpha on right, using subtract-blend trick:
//              we paint the *difference* as an overlay so the total alpha at any pixel is
//              lerp(edgeAlpha, centerAlpha, t).  Because Qt blends in premul-alpha we use
//              a simpler approach: paint the full colour at the correct final alpha and
//              rely on the fact that this sits on top of a transparent scene.
//   Layer 2 – vertical Rectangle, same idea for top/bottom.
//
// Correct approach: every layer paints Qt.rgba(r,g,b,alpha) where alpha is the desired
// FINAL pixel alpha for that layer standing alone.  The layers are combined with
// SourceOver so only the topmost non-transparent pixel "wins" per-channel.
// We therefore build a composite using four independent gradient Rectangles that
// each own one edge and fade toward the centre, and a single solid centre rect.
//
// Simpler and bug-free: use a single Canvas that draws the fill + four gradient strips.
import QtQuick

Item {
    id: bg

    property color  baseColor
    property real   centerAlpha   // 0..1  opacity of the solid centre region
    property real   edgeAlpha     // 0..1  opacity at the four edges
    property real   fraction      // 0..0.45  fade-band width as fraction of min(w,h)
    property real   curve         // -1..1   shape: 0=linear, >0 fast-in, <0 slow-in
    property int    radius: 0

    // Hermite mid-stop (position 0.5 inside the band)
    readonly property real _midAlpha: {
        var t = 0.5
        if (curve < 0) t = Math.pow(0.5, 1.0 + Math.abs(curve))
        else if (curve > 0) t = 1.0 - Math.pow(0.5, 1.0 + curve)
        return edgeAlpha + t * (centerAlpha - edgeAlpha)
    }
    readonly property real _band: (fraction <= 0) ? 0.0 : Math.min(0.45, fraction)

    readonly property real _r: baseColor.r
    readonly property real _g: baseColor.g
    readonly property real _b: baseColor.b

    // ── Layer 0: solid centre ──────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: bg.radius
        color: Qt.rgba(bg._r, bg._g, bg._b, bg.centerAlpha)
    }

    // ── Layer 1: left edge strip ───────────────────────────────────────────────
    Rectangle {
        visible: bg._band > 0 && bg.edgeAlpha < bg.centerAlpha
        x: 0; y: 0
        width: parent.width * bg._band
        height: parent.height
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(bg._r, bg._g, bg._b, bg.edgeAlpha)  }
            GradientStop { position: 0.5; color: Qt.rgba(bg._r, bg._g, bg._b, bg._midAlpha)  }
            GradientStop { position: 1.0; color: Qt.rgba(bg._r, bg._g, bg._b, bg.centerAlpha)}
        }
    }

    // ── Layer 2: right edge strip ──────────────────────────────────────────────
    Rectangle {
        visible: bg._band > 0 && bg.edgeAlpha < bg.centerAlpha
        x: parent.width * (1.0 - bg._band); y: 0
        width: parent.width * bg._band
        height: parent.height
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(bg._r, bg._g, bg._b, bg.centerAlpha)}
            GradientStop { position: 0.5; color: Qt.rgba(bg._r, bg._g, bg._b, bg._midAlpha)  }
            GradientStop { position: 1.0; color: Qt.rgba(bg._r, bg._g, bg._b, bg.edgeAlpha)  }
        }
    }

    // ── Layer 3: top edge strip ────────────────────────────────────────────────
    Rectangle {
        visible: bg._band > 0 && bg.edgeAlpha < bg.centerAlpha
        x: 0; y: 0
        width: parent.width
        height: parent.height * bg._band
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(bg._r, bg._g, bg._b, bg.edgeAlpha)  }
            GradientStop { position: 0.5; color: Qt.rgba(bg._r, bg._g, bg._b, bg._midAlpha)  }
            GradientStop { position: 1.0; color: Qt.rgba(bg._r, bg._g, bg._b, bg.centerAlpha)}
        }
    }

    // ── Layer 4: bottom edge strip ─────────────────────────────────────────────
    Rectangle {
        visible: bg._band > 0 && bg.edgeAlpha < bg.centerAlpha
        x: 0
        y: parent.height * (1.0 - bg._band)
        width: parent.width
        height: parent.height * bg._band
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(bg._r, bg._g, bg._b, bg.centerAlpha)}
            GradientStop { position: 0.5; color: Qt.rgba(bg._r, bg._g, bg._b, bg._midAlpha)  }
            GradientStop { position: 1.0; color: Qt.rgba(bg._r, bg._g, bg._b, bg.edgeAlpha)  }
        }
    }
}
