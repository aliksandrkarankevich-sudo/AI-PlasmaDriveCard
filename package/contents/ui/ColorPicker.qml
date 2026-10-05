// ColorPicker.qml - RGB sliders + preview + mode switch (theme / custom)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root
    spacing: Kirigami.Units.smallSpacing

    // mode: "theme" | "custom"  (owned by the parent, updated via modeSelected)
    property string mode:  "theme"
    // hexColor: "#rrggbb"      (owned by the parent, updated via colorPicked)
    property string hexColor: "#ffffff"
    property string label: ""
    property string labelTheme:  "Из темы"
    property string labelCustom: "Свой"

    // NOTE: must NOT be named modeChanged/colorChanged - those clash with
    // auto-generated property change signals and break QML loading.
    signal modeSelected(string newMode)
    signal colorPicked(string newHex)

    property int _r: 255
    property int _g: 255
    property int _b: 255

    function _hexToRgb(hex) {
        var h = (hex || "").replace("#", "")
        if (h.length !== 6) return
        _r = parseInt(h.substring(0, 2), 16)
        _g = parseInt(h.substring(2, 4), 16)
        _b = parseInt(h.substring(4, 6), 16)
    }
    function _toHex(n) {
        var s = n.toString(16)
        return s.length === 1 ? "0" + s : s
    }
    function _rgbToHex() {
        return "#" + _toHex(_r) + _toHex(_g) + _toHex(_b)
    }
    // Only emit; the parent writes the new value back into hexColor.
    function _applyRgb() {
        var h = _rgbToHex()
        if (h !== hexColor) root.colorPicked(h)
    }

    onHexColorChanged: _hexToRgb(hexColor)
    Component.onCompleted: _hexToRgb(hexColor)

    // Slider with a gradient groove and an explicit, always visible handle.
    component ChannelSlider: QQC2.Slider {
        id: ch
        property color startColor: "black"
        property color endColor: "white"
        Layout.fillWidth: true
        from: 0; to: 255; stepSize: 1
        implicitHeight: 24

        background: Rectangle {
            x: ch.leftPadding
            y: ch.topPadding + ch.availableHeight / 2 - height / 2
            width: ch.availableWidth
            height: 8
            radius: 4
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: ch.startColor }
                GradientStop { position: 1.0; color: ch.endColor }
            }
            border.color: Qt.rgba(0.5, 0.5, 0.5, 0.5)
            border.width: 1
        }

        handle: Rectangle {
            x: ch.leftPadding + ch.visualPosition * (ch.availableWidth - width)
            y: ch.topPadding + ch.availableHeight / 2 - height / 2
            width: 18
            height: 18
            radius: 9
            color: ch.pressed ? Kirigami.Theme.highlightColor : "#ffffff"
            border.color: ch.activeFocus || ch.hovered ? Kirigami.Theme.highlightColor : "#333333"
            border.width: 2
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        QQC2.Label {
            text: root.label
            visible: root.label.length > 0
            font.bold: true
        }
        Item { Layout.fillWidth: true }
        QQC2.ButtonGroup { id: modeGroup }
        QQC2.RadioButton {
            text: root.labelTheme
            checked: root.mode === "theme"
            QQC2.ButtonGroup.group: modeGroup
            onClicked: root.modeSelected("theme")
        }
        QQC2.RadioButton {
            text: root.labelCustom
            checked: root.mode === "custom"
            QQC2.ButtonGroup.group: modeGroup
            onClicked: root.modeSelected("custom")
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        visible: root.mode === "custom"
        enabled: root.mode === "custom"

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 6
            color: root.hexColor
            border.color: Qt.rgba(0.5, 0.5, 0.5, 0.4)
            border.width: 1
            QQC2.Label {
                anchors.centerIn: parent
                text: root.hexColor.toUpperCase()
                color: (root._r * 299 + root._g * 587 + root._b * 114) > 128000
                    ? "#111111" : "#eeeeee"
                font.pixelSize: 13
                font.family: "monospace"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            QQC2.Label { text: "R"; color: "#e05555"; font.bold: true; Layout.preferredWidth: 14 }
            ChannelSlider {
                id: sliderR
                startColor: Qt.rgba(0, root._g / 255, root._b / 255, 1)
                endColor:   Qt.rgba(1, root._g / 255, root._b / 255, 1)
                onMoved: { root._r = Math.round(value); root._applyRgb() }
                Binding { target: sliderR; property: "value"; value: root._r }
            }
            QQC2.Label { text: root._r; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            QQC2.Label { text: "G"; color: "#55b855"; font.bold: true; Layout.preferredWidth: 14 }
            ChannelSlider {
                id: sliderG
                startColor: Qt.rgba(root._r / 255, 0, root._b / 255, 1)
                endColor:   Qt.rgba(root._r / 255, 1, root._b / 255, 1)
                onMoved: { root._g = Math.round(value); root._applyRgb() }
                Binding { target: sliderG; property: "value"; value: root._g }
            }
            QQC2.Label { text: root._g; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            QQC2.Label { text: "B"; color: "#5588e0"; font.bold: true; Layout.preferredWidth: 14 }
            ChannelSlider {
                id: sliderB
                startColor: Qt.rgba(root._r / 255, root._g / 255, 0, 1)
                endColor:   Qt.rgba(root._r / 255, root._g / 255, 1, 1)
                onMoved: { root._b = Math.round(value); root._applyRgb() }
                Binding { target: sliderB; property: "value"; value: root._b }
            }
            QQC2.Label { text: root._b; Layout.preferredWidth: 28; horizontalAlignment: Text.AlignRight }
        }
    }
}
