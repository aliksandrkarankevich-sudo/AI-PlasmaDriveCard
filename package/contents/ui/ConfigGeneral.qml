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
    property int cfg_textScale
    property int cfg_progressHeight
    property int cfg_maxHeight
    property bool cfg_showRoot
    property bool cfg_showBoot
    property bool cfg_showFs
    property bool cfg_showPhysical
    property string cfg_iconStyle
    property bool cfg_showActivity
    property int cfg_activityInterval
    property int cfg_backgroundOpacity
    property string cfg_backgroundColorMode
    property string cfg_backgroundColor
    property int cfg_textOpacity
    property string cfg_textColorMode
    property string cfg_textColor
    property bool cfg_rounded
    property int cfg_cornerRadius
    property int cfg_edgeOpacity
    property int cfg_edgeWidth
    property int cfg_edgeCurve
    property int cfg_contentPadding
    property int cfg_updateInterval
    property int cfg_warningPercent
    property int cfg_criticalPercent

    readonly property bool ru: cfg_language !== "en"
    function tr2(ruText, enText) { return ru ? ruText : enText }

    Kirigami.FormLayout {
        width: page.availableWidth
        implicitHeight: childrenRect.height + 48
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Kirigami.Units.largeSpacing

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
            text: page.tr2("Подбирать автоматически", "Fit automatically")
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
            Kirigami.FormData.label: page.tr2("Масштаб текста:", "Text scale:")
            from: 70; to: 160; stepSize: 5; value: page.cfg_textScale
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 100 }
            onValueModified: page.cfg_textScale = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Толщина полосы:", "Bar thickness:")
            from: 4; to: 24; value: page.cfg_progressHeight
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 8 }
            onValueModified: page.cfg_progressHeight = value
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
        QQC2.ComboBox {
            Kirigami.FormData.label: page.tr2("Значок:", "Icon:")
            model: [page.tr2("Диск", "Drive"), page.tr2("Папка", "Folder"), page.tr2("Открытая папка", "Open folder")]
            currentIndex: page.cfg_iconStyle === "folder" ? 1 : (page.cfg_iconStyle === "folder-open" ? 2 : 0)
            onActivated: page.cfg_iconStyle = currentIndex === 1 ? "folder" : (currentIndex === 2 ? "folder-open" : "drive")
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }
        Kirigami.Heading { Kirigami.FormData.isSection: true; level: 3; text: page.tr2("Активность", "Activity") }
        QQC2.CheckBox {
            Kirigami.FormData.label: page.tr2("Дисковые операции:", "Disk operations:")
            text: page.tr2("Показывать чтение/запись", "Show read/write activity")
            checked: page.cfg_showActivity
            onToggled: page.cfg_showActivity = checked
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Проверять каждые:", "Check every:")
            from: 1; to: 10; value: page.cfg_activityInterval; enabled: page.cfg_showActivity
            textFromValue: function(v) { return v + " " + page.tr2("с", "s") }
            valueFromText: function(t) { return parseInt(t) || 2 }
            onValueModified: page.cfg_activityInterval = value
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }
        Kirigami.Heading { Kirigami.FormData.isSection: true; level: 3; text: page.tr2("Оформление", "Appearance") }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Непрозрачность фона:", "Background opacity:")
            from: 0; to: 100; value: page.cfg_backgroundOpacity
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_backgroundOpacity = value
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: page.tr2("Цвет фона:", "Background color:")
            model: [page.tr2("Из темы", "From theme"), page.tr2("Свой", "Custom")]
            currentIndex: page.cfg_backgroundColorMode === "custom" ? 1 : 0
            onActivated: page.cfg_backgroundColorMode = currentIndex === 1 ? "custom" : "theme"
        }
        QQC2.TextField {
            Kirigami.FormData.label: page.tr2("Свой фон:", "Custom background:")
            text: page.cfg_backgroundColor; enabled: page.cfg_backgroundColorMode === "custom"
            placeholderText: "#20242b"
            onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text)) page.cfg_backgroundColor = text
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Непрозрачность текста:", "Text opacity:")
            from: 10; to: 100; value: page.cfg_textOpacity
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 10 }
            onValueModified: page.cfg_textOpacity = value
        }
        QQC2.ComboBox {
            Kirigami.FormData.label: page.tr2("Цвет текста:", "Text color:")
            model: [page.tr2("Из темы", "From theme"), page.tr2("Свой", "Custom")]
            currentIndex: page.cfg_textColorMode === "custom" ? 1 : 0
            onActivated: page.cfg_textColorMode = currentIndex === 1 ? "custom" : "theme"
        }
        QQC2.TextField {
            Kirigami.FormData.label: page.tr2("Свой текст:", "Custom text:")
            text: page.cfg_textColor; enabled: page.cfg_textColorMode === "custom"
            placeholderText: "#eff0f1"
            onEditingFinished: if (/^#[0-9a-fA-F]{6}$/.test(text)) page.cfg_textColor = text
        }
        QQC2.CheckBox {
            Kirigami.FormData.label: page.tr2("Углы:", "Corners:")
            text: page.tr2("Включить скругление", "Enable rounding")
            checked: page.cfg_rounded
            onToggled: page.cfg_rounded = checked
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Радиус:", "Radius:")
            from: 0; to: 80; value: page.cfg_cornerRadius; enabled: page.cfg_rounded
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_cornerRadius = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Прозрачность края:", "Edge transparency:")
            from: 0; to: 100; value: page.cfg_edgeOpacity
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_edgeOpacity = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Ширина перехода:", "Fade width:")
            from: 0; to: 96; value: page.cfg_edgeWidth
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_edgeWidth = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Кривая перехода:", "Fade curve:")
            from: -100; to: 100; stepSize: 5; value: page.cfg_edgeCurve
            textFromValue: function(v) { return v === 0 ? page.tr2("0 — ровная", "0 — balanced") : (v > 0 ? "+" : "") + v }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_edgeCurve = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Отступ содержимого:", "Content padding:")
            from: 8; to: 64; stepSize: 2; value: page.cfg_contentPadding
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 8 }
            onValueModified: page.cfg_contentPadding = value
        }
        Kirigami.Separator { Kirigami.FormData.isSection: true }
        Kirigami.Heading { Kirigami.FormData.isSection: true; level: 3; text: page.tr2("Обновление", "Refresh") }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Интервал:", "Interval:")
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
        Item { Kirigami.FormData.isSection: true; implicitHeight: 32 }
    }
}
