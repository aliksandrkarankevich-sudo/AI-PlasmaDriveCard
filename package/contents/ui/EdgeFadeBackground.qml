// EdgeFadeBackground.qml
// Single-pass ShaderEffect background (Qt6 inline GLSL, no Qt5Compat).
// Uses layer.enabled on a Rectangle for correct RHI clipping.
// Corner logic: t = min(tx, ty) — no overlap, no darkening.
import QtQuick

Item {
    id: root

    property color baseColor:   "black"
    property real  centerAlpha: 0.4
    property real  edgeAlpha:   1.0   // 0 = no fade, 1 = fully transparent edge
    property real  fadeWidth:   30    // px
    property real  curve:       0.0   // -1..+1, mapped to pow exponent
    property real  radius:      0

    readonly property real _fwNorm: (width > 0 && height > 0)
        ? Math.max(0.0, Math.min(0.45, fadeWidth / Math.min(width, height)))
        : 0.0
    readonly property real _ea:  Math.max(0.0, Math.min(1.0, edgeAlpha))
    readonly property real _exp: Math.max(0.25, 2.0 + curve * 2.0)

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: root.radius
        color: "transparent"

        // layer clips ShaderEffect to rounded rect in RHI mode
        layer.enabled: root.radius > 0
        layer.smooth:  true

        ShaderEffect {
            anchors.fill: parent

            property real rW:           root.width
            property real rH:           root.height
            property real fw:           root._fwNorm
            property real expVal:       root._exp
            property real centerAlpha:  root.centerAlpha
            property real edgeStrength: root._ea
            property real baseR:        root.baseColor.r
            property real baseG:        root.baseColor.g
            property real baseB:        root.baseColor.b

            fragmentShader: "
                uniform lowp float qt_Opacity;
                uniform highp float rW;
                uniform highp float rH;
                uniform highp float fw;
                uniform highp float expVal;
                uniform highp float centerAlpha;
                uniform highp float edgeStrength;
                uniform highp float baseR;
                uniform highp float baseG;
                uniform highp float baseB;
                varying highp vec2 qt_TexCoord0;

                void main() {
                    highp vec2 uv = qt_TexCoord0;
                    highp float dx = min(uv.x, 1.0 - uv.x);
                    highp float dy = min(uv.y, 1.0 - uv.y);
                    highp float tx = (fw > 0.0) ? clamp(dx / fw, 0.0, 1.0) : 1.0;
                    highp float ty = (fw > 0.0) ? clamp(dy / fw, 0.0, 1.0) : 1.0;
                    highp float t  = min(tx, ty);
                    highp float s  = smoothstep(0.0, 1.0, t);
                    s = pow(s, expVal);
                    highp float edgeA = centerAlpha * (1.0 - edgeStrength);
                    highp float alpha = mix(edgeA, centerAlpha, s) * qt_Opacity;
                    gl_FragColor = vec4(baseR * alpha, baseG * alpha, baseB * alpha, alpha);
                }
            "
        }
    }
}
