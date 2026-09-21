// EdgeFadeBackground.qml
// Single-pass ShaderEffect background:
//   - no Qt5Compat dependency
//   - no corner overlap / darkening
//   - perceptually smooth fade via smoothstep + pow curve
import QtQuick

Item {
    id: root

    property color baseColor:   "black"
    property real  centerAlpha: 0.4   // alpha at centre (0..1)
    property real  edgeAlpha:   1.0   // fade strength: 0=no fade, 1=fully transparent edge
    property real  fadeWidth:   30    // px — fade band width
    property real  curve:       0.0   // 0=smoothstep, >0=steeper, <0=softer  (maps to pow exponent)
    property real  radius:      0

    // Normalised fade width (0..0.5) passed to shader
    readonly property real _fwNorm: (width > 0 && height > 0)
        ? Math.max(0.0, Math.min(0.45, fadeWidth / Math.min(width, height)))
        : 0.0
    readonly property real _ea: Math.max(0.0, Math.min(1.0, edgeAlpha))
    // pow exponent: curve==0 → exp=2 (smooth), curve==1 → exp=4 (sharp), curve==-1 → exp=1 (linear)
    readonly property real _exp: Math.max(0.5, 2.0 + curve * 2.0)

    // Clip to rounded rectangle so shader corners are clean
    Rectangle {
        id: clipRect
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        clip: true

        ShaderEffect {
            anchors.fill: parent

            // uniforms
            property vector3d baseRGB: Qt.vector3d(root.baseColor.r, root.baseColor.g, root.baseColor.b)
            property real centerAlpha: root.centerAlpha
            property real edgeStrength: root._ea
            property real fw: root._fwNorm
            property real exp_: root._exp

            fragmentShader: "
                #version 440
                layout(location = 0) in vec2 qt_TexCoord0;
                layout(location = 0) out vec4 fragColor;

                layout(std140, binding = 0) uniform buf {
                    mat4 qt_Matrix;
                    float qt_Opacity;
                    vec3  baseRGB;
                    float centerAlpha;
                    float edgeStrength;
                    float fw;
                    float exp_;
                };

                void main() {
                    vec2 uv = qt_TexCoord0;               // 0..1
                    // distance from each edge, normalised 0..1 within fade band
                    float dx = min(uv.x, 1.0 - uv.x);   // dist to left/right edge
                    float dy = min(uv.y, 1.0 - uv.y);   // dist to top/bottom edge
                    // t=0 at edge, t=1 inside fade band
                    float tx = (fw > 0.0) ? clamp(dx / fw, 0.0, 1.0) : 1.0;
                    float ty = (fw > 0.0) ? clamp(dy / fw, 0.0, 1.0) : 1.0;
                    float t  = min(tx, ty);              // corner = min of both axes — no overlap
                    // smooth curve
                    float s  = smoothstep(0.0, 1.0, t);
                    s        = pow(s, exp_);
                    // alpha: edge is centerAlpha*(1-edgeStrength), centre is centerAlpha
                    float edgeAlpha = centerAlpha * (1.0 - edgeStrength);
                    float alpha = mix(edgeAlpha, centerAlpha, s) * qt_Opacity;
                    fragColor = vec4(baseRGB * alpha, alpha);
                }
            "
        }
    }
}
