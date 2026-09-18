import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth
    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
    QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AsNeeded

    property string cfg_language
    property bool cfg_autoFit
    property int cfg_rowHeight
    property int cfg_maxHeight
    property bool cfg_showRoot
    property bool cfg_showBoot
    property bool cfg_showFs
    property bool cfg_showPhysical
    property int cfg_backgroundOpacity
    property int cfg_textOpacity
    property bool cfg_rounded
    property int cfg_cornerRadius
    property int cfg_edgeOpacity
    property int cfg_edgeWidth
    property int cfg_edgeCurve
    property int cfg_outerMargin
    property int cfg_contentPadding
    property int cfg_contentProtection
    property int cfg_discoveryInterval
    property int cfg_updateInterval
    property int cfg_warningPercent
    property int cfg_criticalPercent

    readonly property bool ru: cfg_language !== "en"
    function tr2(r, e) { return ru ? r : e }

    Kirigami.FormLayout {
        width: page.availableWidth
        implicitHeight: childrenRect.height + Kirigami.Units.gridUnit * 3

        QQC2.ComboBox {
            Kirigami.FormData.label: page.tr2("Язык:", "Language:")
            model: ["Русский", "English"]
            currentIndex: page.cfg_language === "en" ? 1 : 0
            onActivated: page.cfg_language = currentIndex === 1 ? "en" : "ru"
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }
        Kirigami.Heading { Kirigami.FormData.isSection: true; level: 3; text: page.tr2("Размер", "Size") }
        QQC2.CheckBox {
            Kirigami.FormData.label: page.tr2("Высота:", "Height:")
            text: page.tr2("Рекомендовать размер автоматически", "Recommend size automatically")
            checked: page.cfg_autoFit
            onToggled: page.cfg_autoFit = checked
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Высота строки:", "Row height:")
            from: 72; to: 180; stepSize: 4; value: page.cfg_rowHeight
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 108 }
            onValueModified: page.cfg_rowHeight = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Максимальная высота:", "Maximum height:")
            from: 240; to: 1600; stepSize: 20; value: page.cfg_maxHeight
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 720 }
            onValueModified: page.cfg_maxHeight = value
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: page.tr2("Разделы:", "Volumes:")
            text: page.tr2("Показывать системный раздел /", "Show system volume /")
            checked: page.cfg_showRoot
            onToggled: page.cfg_showRoot = checked
        }
        QQC2.CheckBox {
            text: page.tr2("Показывать /boot и /boot/efi", "Show /boot and /boot/efi")
            checked: page.cfg_showBoot
            onToggled: page.cfg_showBoot = checked
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: page.tr2("Сведения:", "Details:")
            text: page.tr2("Показывать файловую систему", "Show filesystem")
            checked: page.cfg_showFs
            onToggled: page.cfg_showFs = checked
        }
        QQC2.CheckBox {
            text: page.tr2("Показывать физический диск кратко", "Show short physical drive")
            checked: page.cfg_showPhysical
            onToggled: page.cfg_showPhysical = checked
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true }
        Kirigami.Heading { Kirigami.FormData.isSection: true; level: 3; text: page.tr2("Оформление", "Appearance") }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Непрозрачность центра:", "Center opacity:")
            from: 0; to: 100; value: page.cfg_backgroundOpacity
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_backgroundOpacity = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Непрозрачность текста:", "Text opacity:")
            from: 10; to: 100; value: page.cfg_textOpacity
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 10 }
            onValueModified: page.cfg_textOpacity = value
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: page.tr2("Углы:", "Corners:")
            text: page.tr2("Включить скругление", "Enable rounding")
            checked: page.cfg_rounded
            onToggled: page.cfg_rounded = checked
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Радиус:", "Radius:")
            from: 0; to: 96; value: page.cfg_cornerRadius; enabled: page.cfg_rounded
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_cornerRadius = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Прозрачность границы:", "Edge transparency:")
            from: 0; to: 100; value: page.cfg_edgeOpacity
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_edgeOpacity = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Ширина растворения:", "Fade width:")
            from: 0; to: 120; value: page.cfg_edgeWidth
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_edgeWidth = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Форма перехода:", "Fade shape:")
            from: -100; to: 100; stepSize: 5; value: page.cfg_edgeCurve
            textFromValue: function(v) { return v === 0 ? page.tr2("0 — нейтральная", "0 — neutral") : (v > 0 ? "+" : "") + v }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_edgeCurve = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Внешний запас:", "Outer safety margin:")
            from: 0; to: 12; value: page.cfg_outerMargin
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_outerMargin = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Отступ содержимого:", "Content padding:")
            from: 4; to: 64; stepSize: 2; value: page.cfg_contentPadding
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 4 }
            onValueModified: page.cfg_contentPadding = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Защита от растворения:", "Fade protection:")
            from: 0; to: 100; stepSize: 5; value: page.cfg_contentProtection
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_contentProtection = value
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true }
        Kirigami.Heading { Kirigami.FormData.isSection: true; level: 3; text: page.tr2("Обновление", "Refresh") }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Поиск дисков:", "Discover drives:")
            from: 5; to: 120; stepSize: 5; value: page.cfg_discoveryInterval
            textFromValue: function(v) { return v + " " + page.tr2("с", "s") }
            valueFromText: function(t) { return parseInt(t) || 10 }
            onValueModified: page.cfg_discoveryInterval = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Обновление места:", "Refresh space:")
            from: 15; to: 1800; stepSize: 15; value: page.cfg_updateInterval
            textFromValue: function(v) { return v + " " + page.tr2("с", "s") }
            valueFromText: function(t) { return parseInt(t) || 60 }
            onValueModified: page.cfg_updateInterval = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Предупреждение:", "Warning:")
            from: 50; to: 99; value: page.cfg_warningPercent
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 80 }
            onValueModified: page.cfg_warningPercent = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Критический уровень:", "Critical:")
            from: 51; to: 100; value: page.cfg_criticalPercent
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 90 }
            onValueModified: page.cfg_criticalPercent = value
        }
        Item { Kirigami.FormData.isSection: true; implicitHeight: Kirigami.Units.gridUnit * 2 }
    }
}
