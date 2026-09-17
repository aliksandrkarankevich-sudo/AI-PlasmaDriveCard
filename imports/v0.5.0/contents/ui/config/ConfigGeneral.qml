// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property string cfg_language: "ru"
    property alias cfg_updateInterval: updateInterval.value
    property alias cfg_warningPercent: warningPercent.value
    property alias cfg_criticalPercent: criticalPercent.value
    property alias cfg_showRoot: showRoot.checked
    property alias cfg_showBoot: showBoot.checked
    readonly property bool ru: cfg_language === "ru"

    function syncLanguage() {
        const index = language.indexOfValue(cfg_language)
        if (index >= 0 && language.currentIndex !== index)
            language.currentIndex = index
    }

    onCfg_languageChanged: syncLanguage()
    Component.onCompleted: syncLanguage()

    QQC2.ComboBox {
        id: language
        Kirigami.FormData.label: page.ru ? "Язык:" : "Language:"
        model: [
            { text: "Русский", value: "ru" },
            { text: "English", value: "en" }
        ]
        textRole: "text"
        valueRole: "value"
        onActivated: page.cfg_language = currentValue
    }

    QQC2.SpinBox {
        id: updateInterval
        Kirigami.FormData.label: page.ru ? "Интервал обновления:" : "Update interval:"
        from: 10
        to: 3600
        editable: true
        textFromValue: function(value) {
            return page.ru ? value + " с" : value + " s"
        }
        valueFromText: function(text) { return parseInt(text) }
    }

    QQC2.SpinBox {
        id: warningPercent
        Kirigami.FormData.label: page.ru ? "Предупреждение при:" : "Warning at:"
        from: 1
        to: 99
        textFromValue: function(value) { return value + "%" }
        valueFromText: function(text) { return parseInt(text) }
    }

    QQC2.SpinBox {
        id: criticalPercent
        Kirigami.FormData.label: page.ru ? "Критический уровень:" : "Critical at:"
        from: 2
        to: 100
        textFromValue: function(value) { return value + "%" }
        valueFromText: function(text) { return parseInt(text) }
    }

    QQC2.CheckBox {
        id: showRoot
        Kirigami.FormData.label: page.ru ? "Системные разделы:" : "System volumes:"
        text: page.ru ? "Показывать корневую файловую систему" : "Show the root filesystem"
    }

    QQC2.CheckBox {
        id: showBoot
        text: page.ru ? "Показывать разделы /boot и /boot/efi" : "Show /boot and /boot/efi volumes"
    }

    Kirigami.InlineMessage {
        Layout.fillWidth: true
        visible: true
        type: Kirigami.MessageType.Information
        text: page.ru
            ? "Показываются реальные файловые системы, уже смонтированные в текущем сеансе. Виджет не запрашивает пароль и не монтирует диски."
            : "Real filesystems already mounted in the current session are shown. The widget never asks for a password or mounts disks."
    }
}
