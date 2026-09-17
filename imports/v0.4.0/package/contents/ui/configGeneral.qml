import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_displayName: displayNameField.text
    property alias cfg_mountPath: mountPathField.text
    property alias cfg_iconName: iconNameField.text
    property alias cfg_updateInterval: updateIntervalBox.value
    property alias cfg_warningPercent: warningBox.value
    property alias cfg_criticalPercent: criticalBox.value

    Kirigami.FormLayout {
        wideMode: true

        QQC2.TextField {
            id: displayNameField
            Kirigami.FormData.label: i18n("Name:")
            placeholderText: i18n("Games")
        }
        QQC2.TextField {
            id: mountPathField
            Kirigami.FormData.label: i18n("Mount point:")
            placeholderText: "/mnt/LinuxGames"
        }
        QQC2.TextField {
            id: iconNameField
            Kirigami.FormData.label: i18n("Icon name:")
            placeholderText: "folder-games"
        }
        QQC2.SpinBox {
            id: updateIntervalBox
            Kirigami.FormData.label: i18n("Update interval:")
            from: 10
            to: 3600
            editable: true
            textFromValue: function(value) { return i18np("%1 second", "%1 seconds", value) }
            valueFromText: function(text) { return parseInt(text, 10) || 60 }
        }
        QQC2.SpinBox {
            id: warningBox
            Kirigami.FormData.label: i18n("Warning at:")
            from: 1
            to: 99
            editable: true
            textFromValue: function(value) { return value + "%" }
            valueFromText: function(text) { return parseInt(text, 10) || 85 }
        }
        QQC2.SpinBox {
            id: criticalBox
            Kirigami.FormData.label: i18n("Critical at:")
            from: 2
            to: 100
            editable: true
            textFromValue: function(value) { return value + "%" }
            valueFromText: function(text) { return parseInt(text, 10) || 95 }
        }
        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: true
            type: Kirigami.MessageType.Information
            text: i18n("The path must already be a mount point. This widget never mounts, formats, or changes disks.")
        }
    }
}
