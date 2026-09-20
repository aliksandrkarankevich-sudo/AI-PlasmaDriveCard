// SPDX-License-Identifier: GPL-3.0-or-later
// EdgeFadeBackground.qml — four-sided transparent edge fade
// Place this item behind all content inside fullRepresentation.

import QtQuick

Item {
    id: root

    // ── Public inputs ────────────────────────────────────────────
    required property color  baseColor      // surface colour (no alpha)
    required property real   centerAlpha    // 0‥1 opacity of the centre
    required property real   edgeAlpha      // 0‥1 opacity at the edges (≤ centerAlpha)
    required property real   fadeFraction   // 0‥0.45  fraction of width/height used for fade
    required property real   curve          // –1‥+1  shape of the fade (0 = linear)
    required property real   radius         // corner radius in px

    // ── Helpers ──────────────────────────────────────────────────
    // Blend two alpha values with a gamma-like curve.
    // t in [0,1]: 0 = edge side, 1 = centre
    function alphaAt(t) {
        // Ease-in (curve > 0) keeps edge transparent longer.
        // Ease-out (curve < 0) makes the transition sharper near the edge.
        var shaped
        if (curve > 0) {
            var exp = 1.0 + curve * 2.0   // 1..3
            shaped = Math.pow(t, exp)
        } else {
            var expN = 1.0 - curve * 2.0  // 1..3
            shaped = 1.0 - Math.pow(1.0 - t, expN)
        }
        return edgeAlpha + (centerAlpha - edgeAlpha) * shaped
    }

    // Build an array of GradientStop positions and their alpha values
    // for one edge.  p0 = edge position (0 or 1), p1 = centre position.
    // Returns an array of {pos, alpha} objects.
    function stops(p0, p1) {
        var result = []
        var steps = 8
        for (var i = 0; i <= steps; ++i) {
            var t   = i / steps          // 0 = p0 side, 1 = p1 side
            var pos = p0 + (p1 - p0) * t
            result.push({ pos: pos, alpha: alphaAt(t) })
        }
        return result
    }

    // ── Solid centre fill ─────────────────────────────────────────
    // Drawn first so the mask rectangles multiply on top.
    Rectangle {
        id: centre
        anchors.fill: parent
        radius: root.radius
        color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b, root.centerAlpha)
    }

    // ── Horizontal fade mask (left + right) ───────────────────────
    // Covers the full height; erases alpha on the left and right sides.
    Rectangle {
        id: hFade
        anchors.fill: parent
        radius: root.radius
        visible: root.fadeFraction > 0.001
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Horizontal

            // Left edge → centre  (stops from position 0 to fadeFraction)
            GradientStop {
                position: 0.0
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0))
            }
            GradientStop {
                position: root.fadeFraction * 0.25
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0.25))
            }
            GradientStop {
                position: root.fadeFraction * 0.5
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0.5))
            }
            GradientStop {
                position: root.fadeFraction * 0.75
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0.75))
            }
            GradientStop {
                position: root.fadeFraction
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha)
            }

            // Centre plateau
            GradientStop {
                position: 1.0 - root.fadeFraction
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha)
            }

            // Centre → right edge
            GradientStop {
                position: 1.0 - root.fadeFraction * 0.75
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0.75))
            }
            GradientStop {
                position: 1.0 - root.fadeFraction * 0.5
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0.5))
            }
            GradientStop {
                position: 1.0 - root.fadeFraction * 0.25
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0.25))
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0))
            }
        }
    }

    // ── Vertical fade mask (top + bottom) ─────────────────────────
    Rectangle {
        id: vFade
        anchors.fill: parent
        radius: root.radius
        visible: root.fadeFraction > 0.001
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Vertical

            GradientStop {
                position: 0.0
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0))
            }
            GradientStop {
                position: root.fadeFraction * 0.25
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0.25))
            }
            GradientStop {
                position: root.fadeFraction * 0.5
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0.5))
            }
            GradientStop {
                position: root.fadeFraction * 0.75
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0.75))
            }
            GradientStop {
                position: root.fadeFraction
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha)
            }

            GradientStop {
                position: 1.0 - root.fadeFraction
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.centerAlpha)
            }

            GradientStop {
                position: 1.0 - root.fadeFraction * 0.75
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0.75))
            }
            GradientStop {
                position: 1.0 - root.fadeFraction * 0.5
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0.5))
            }
            GradientStop {
                position: 1.0 - root.fadeFraction * 0.25
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0.25))
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(root.baseColor.r, root.baseColor.g, root.baseColor.b,
                               root.alphaAt(0))
            }
        }
    }
}
