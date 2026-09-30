import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

QQC2.ScrollView {
    id: page
    clip: true
    contentWidth: availableWidth
    QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
    QQC2.ScrollBar.vertical.policy:   QQC2.ScrollBar.AsNeeded

    property string title

    property string cfg_language
    property bool   cfg_autoFit
    property int    cfg_rowPaddingV
    property int    cfg_separatorHeight
    property int    cfg_textScale
    property int    cfg_progressHeight
    property int    cfg_maxHeight
    property bool   cfg_showRoot
    property bool   cfg_showBoot
    property bool   cfg_showFs
    property bool   cfg_showPhysical
    property string cfg_iconStyle
    property bool   cfg_showActivity
    property int    cfg_activityInterval
    property int    cfg_backgroundOpacity
    property string cfg_backgroundColorMode
    property string cfg_backgroundColor
    property int    cfg_textOpacity
    property string cfg_textColorMode
    property string cfg_textColor
    property bool   cfg_rounded
    property int    cfg_cornerRadius
    property int    cfg_edgeOpacity
    property int    cfg_edgeWidth
    property int    cfg_edgeCurve
    property int    cfg_contentPadding
    property int    cfg_updateInterval
    property int    cfg_warningPercent
    property int    cfg_criticalPercent
    property string cfg_profiles
    property string cfg_activeProfile

    property string cfg_languageDefault:            "ru"
    property bool   cfg_autoFitDefault:             true
    property int    cfg_rowPaddingVDefault:         10
    property int    cfg_separatorHeightDefault:     4
    property int    cfg_textScaleDefault:           100
    property int    cfg_progressHeightDefault:      8
    property int    cfg_maxHeightDefault:           720
    property bool   cfg_showRootDefault:            true
    property bool   cfg_showBootDefault:            false
    property bool   cfg_showFsDefault:              true
    property bool   cfg_showPhysicalDefault:        true
    property string cfg_iconStyleDefault:           "drive"
    property bool   cfg_showActivityDefault:        true
    property int    cfg_activityIntervalDefault:    2
    property int    cfg_backgroundOpacityDefault:   40
    property string cfg_backgroundColorModeDefault: "theme"
    property string cfg_backgroundColorDefault:     "#20242b"
    property int    cfg_textOpacityDefault:         90
    property string cfg_textColorModeDefault:       "theme"
    property string cfg_textColorDefault:           "#eff0f1"
    property bool   cfg_roundedDefault:             true
    property int    cfg_cornerRadiusDefault:        15
    property int    cfg_edgeOpacityDefault:         100
    property int    cfg_edgeWidthDefault:           30
    property int    cfg_edgeCurveDefault:           0
    property int    cfg_contentPaddingDefault:      24
    property int    cfg_updateIntervalDefault:      60
    property int    cfg_warningPercentDefault:      80
    property int    cfg_criticalPercentDefault:     90
    property string cfg_profilesDefault:            ""
    property string cfg_activeProfileDefault:       ""

    readonly property bool ru: cfg_language !== "en"
    function tr2(r, e) { return ru ? r : e }

    readonly property int _smallSp: 4
    function _fontPx(base) { return Math.max(8, Math.round(base * cfg_textScale / 100.0)) }
    readonly property int _rowPadV: Math.max(4, cfg_rowPaddingV)
    readonly property int _rowGapV: _smallSp
    readonly property int _effectiveRowH:
        _rowPadV * 2
        + _fontPx(18) + _fontPx(16) + _fontPx(13)
        + _fontPx(13) + Math.max(2, cfg_progressHeight)
        + _rowGapV * 4

    // ── профили ─────────────────────────────────────────────────────────
    // Профили хранятся как JSON-массив объектов: [{name, ...все cfg_*}]
    function _loadProfiles() {
        if (!cfg_profiles || cfg_profiles.trim() === "") return []
        try { return JSON.parse(cfg_profiles) } catch(e) { return [] }
    }
    function _saveProfiles(arr) {
        cfg_profiles = JSON.stringify(arr)
    }
    function _profileNames() {
        return _loadProfiles().map(function(p) { return p.name })
    }
    function _currentSnapshot(name) {
        return {
            name:                name,
            language:            cfg_language,
            autoFit:             cfg_autoFit,
            rowPaddingV:         cfg_rowPaddingV,
            separatorHeight:     cfg_separatorHeight,
            textScale:           cfg_textScale,
            progressHeight:      cfg_progressHeight,
            maxHeight:           cfg_maxHeight,
            showRoot:            cfg_showRoot,
            showBoot:            cfg_showBoot,
            showFs:              cfg_showFs,
            showPhysical:        cfg_showPhysical,
            iconStyle:           cfg_iconStyle,
            showActivity:        cfg_showActivity,
            activityInterval:    cfg_activityInterval,
            backgroundOpacity:   cfg_backgroundOpacity,
            backgroundColorMode: cfg_backgroundColorMode,
            backgroundColor:     cfg_backgroundColor,
            textOpacity:         cfg_textOpacity,
            textColorMode:       cfg_textColorMode,
            textColor:           cfg_textColor,
            rounded:             cfg_rounded,
            cornerRadius:        cfg_cornerRadius,
            edgeOpacity:         cfg_edgeOpacity,
            edgeWidth:           cfg_edgeWidth,
            edgeCurve:           cfg_edgeCurve,
            contentPadding:      cfg_contentPadding,
            updateInterval:      cfg_updateInterval,
            warningPercent:      cfg_warningPercent,
            criticalPercent:     cfg_criticalPercent
        }
    }
    function saveProfile(name) {
        if (!name || name.trim() === "") return
        var arr = _loadProfiles()
        var idx = arr.findIndex(function(p) { return p.name === name })
        var snap = _currentSnapshot(name)
        if (idx >= 0) arr[idx] = snap
        else arr.push(snap)
        _saveProfiles(arr)
        cfg_activeProfile = name
        profileModel.reload()
    }
    function loadProfile(name) {
        var arr = _loadProfiles()
        var p = arr.find(function(x) { return x.name === name })
        if (!p) return
        cfg_language            = p.language            !== undefined ? p.language            : cfg_languageDefault
        cfg_autoFit             = p.autoFit             !== undefined ? p.autoFit             : cfg_autoFitDefault
        cfg_rowPaddingV         = p.rowPaddingV         !== undefined ? p.rowPaddingV         : cfg_rowPaddingVDefault
        cfg_separatorHeight     = p.separatorHeight     !== undefined ? p.separatorHeight     : cfg_separatorHeightDefault
        cfg_textScale           = p.textScale           !== undefined ? p.textScale           : cfg_textScaleDefault
        cfg_progressHeight      = p.progressHeight      !== undefined ? p.progressHeight      : cfg_progressHeightDefault
        cfg_maxHeight           = p.maxHeight           !== undefined ? p.maxHeight           : cfg_maxHeightDefault
        cfg_showRoot            = p.showRoot            !== undefined ? p.showRoot            : cfg_showRootDefault
        cfg_showBoot            = p.showBoot            !== undefined ? p.showBoot            : cfg_showBootDefault
        cfg_showFs              = p.showFs              !== undefined ? p.showFs              : cfg_showFsDefault
        cfg_showPhysical        = p.showPhysical        !== undefined ? p.showPhysical        : cfg_showPhysicalDefault
        cfg_iconStyle           = p.iconStyle           !== undefined ? p.iconStyle           : cfg_iconStyleDefault
        cfg_showActivity        = p.showActivity        !== undefined ? p.showActivity        : cfg_showActivityDefault
        cfg_activityInterval    = p.activityInterval    !== undefined ? p.activityInterval    : cfg_activityIntervalDefault
        cfg_backgroundOpacity   = p.backgroundOpacity   !== undefined ? p.backgroundOpacity   : cfg_backgroundOpacityDefault
        cfg_backgroundColorMode = p.backgroundColorMode !== undefined ? p.backgroundColorMode : cfg_backgroundColorModeDefault
        cfg_backgroundColor     = p.backgroundColor     !== undefined ? p.backgroundColor     : cfg_backgroundColorDefault
        cfg_textOpacity         = p.textOpacity         !== undefined ? p.textOpacity         : cfg_textOpacityDefault
        cfg_textColorMode       = p.textColorMode       !== undefined ? p.textColorMode       : cfg_textColorModeDefault
        cfg_textColor           = p.textColor           !== undefined ? p.textColor           : cfg_textColorDefault
        cfg_rounded             = p.rounded             !== undefined ? p.rounded             : cfg_roundedDefault
        cfg_cornerRadius        = p.cornerRadius        !== undefined ? p.cornerRadius        : cfg_cornerRadiusDefault
        cfg_edgeOpacity         = p.edgeOpacity         !== undefined ? p.edgeOpacity         : cfg_edgeOpacityDefault
        cfg_edgeWidth           = p.edgeWidth           !== undefined ? p.edgeWidth           : cfg_edgeWidthDefault
        cfg_edgeCurve           = p.edgeCurve           !== undefined ? p.edgeCurve           : cfg_edgeCurveDefault
        cfg_contentPadding      = p.contentPadding      !== undefined ? p.contentPadding      : cfg_contentPaddingDefault
        cfg_updateInterval      = p.updateInterval      !== undefined ? p.updateInterval      : cfg_updateIntervalDefault
        cfg_warningPercent      = p.warningPercent      !== undefined ? p.warningPercent      : cfg_warningPercentDefault
        cfg_criticalPercent     = p.criticalPercent     !== undefined ? p.criticalPercent     : cfg_criticalPercentDefault
        cfg_activeProfile = name
    }
    function deleteProfile(name) {
        var arr = _loadProfiles().filter(function(p) { return p.name !== name })
        _saveProfiles(arr)
        if (cfg_activeProfile === name) cfg_activeProfile = ""
        profileModel.reload()
    }

    ListModel {
        id: profileModel
        function reload() {
            clear()
            var names = page._profileNames()
            for (var i = 0; i < names.length; ++i) append({ pname: names[i] })
        }
        Component.onCompleted: reload()
    }

    // ── UI ──────────────────────────────────────────────────────────────
    Kirigami.FormLayout {
        width: page.availableWidth
        implicitHeight: childrenRect.height + 48
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Kirigami.Units.largeSpacing

        // ── Профили ─────────────────────────────────────────────────────
        Kirigami.Separator { Kirigami.FormData.isSection: true }
        Kirigami.Heading {
            Kirigami.FormData.isSection: true; level: 3
            text: page.tr2("Профили настроек", "Settings Profiles")
                + (page.cfg_activeProfile ? "  —  " + page.cfg_activeProfile : "")
        }

        // Список профилей
        ListView {
            Kirigami.FormData.label: page.tr2("Сохранённые:", "Saved:")
            Layout.fillWidth: true
            implicitHeight: Math.min(profileModel.count * 40, 160)
            visible: profileModel.count > 0
            model: profileModel
            clip: true
            delegate: RowLayout {
                width: parent ? parent.width : 0
                height: 38
                spacing: Kirigami.Units.smallSpacing
                QQC2.Label {
                    text: model.pname
                    Layout.fillWidth: true
                    color: model.pname === page.cfg_activeProfile
                        ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    font.bold: model.pname === page.cfg_activeProfile
                }
                QQC2.Button {
                    text: page.tr2("Загрузить", "Load")
                    onClicked: page.loadProfile(model.pname)
                }
                QQC2.Button {
                    text: page.tr2("Удалить", "Delete")
                    onClicked: page.deleteProfile(model.pname)
                }
            }
        }

        // Сохранить / создать профиль
        RowLayout {
            Kirigami.FormData.label: page.tr2("Новый профиль:", "New profile:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            QQC2.TextField {
                id: profileNameField
                Layout.fillWidth: true
                placeholderText: page.tr2("Название...", "Name...")
                text: page.cfg_activeProfile
            }
            QQC2.Button {
                text: page.tr2("Сохранить", "Save")
                enabled: profileNameField.text.trim().length > 0
                onClicked: page.saveProfile(profileNameField.text.trim())
            }
        }

        // ── Язык ────────────────────────────────────────────────────────
        Kirigami.Separator { Kirigami.FormData.isSection: true }
        QQC2.ComboBox {
            Kirigami.FormData.label: page.tr2("Язык:", "Language:")
            model: ["Русский", "English"]
            currentIndex: page.cfg_language === "en" ? 1 : 0
            onActivated: page.cfg_language = currentIndex === 1 ? "en" : "ru"
        }

        // ── Размер ──────────────────────────────────────────────────────
        Kirigami.Separator { Kirigami.FormData.isSection: true }
        Kirigami.Heading { Kirigami.FormData.isSection: true; level: 3; text: page.tr2("Размер", "Size") }

        QQC2.CheckBox {
            Kirigami.FormData.label: page.tr2("Высота:", "Height:")
            text: page.tr2("Подбирать автоматически", "Fit automatically")
            checked: page.cfg_autoFit
            onToggled: page.cfg_autoFit = checked
        }
        QQC2.Label {
            Kirigami.FormData.label: page.tr2("Высота строки:", "Row height:")
            text: page._effectiveRowH + " px  " + page.tr2("(авто)", "(auto)")
            opacity: 0.65
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Отступ строки:", "Row padding:")
            from: 4; to: 40; stepSize: 2; value: page.cfg_rowPaddingV
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 10 }
            onValueModified: page.cfg_rowPaddingV = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Отступ между дисками:", "Gap between drives:")
            from: 0; to: 32; stepSize: 1; value: page.cfg_separatorHeight
            textFromValue: function(v) { return v === 0 ? page.tr2("выключён", "off") : v + " px" }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_separatorHeight = value
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
            from: 4; to: 48; value: page.cfg_progressHeight
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

        // ── Разделы / значки ─────────────────────────────────────────────
        Kirigami.Separator { Kirigami.FormData.isSection: true }
        Kirigami.Heading { Kirigami.FormData.isSection: true; level: 3; text: page.tr2("Содержимое", "Content") }

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
        QQC2.CheckBox {
            Kirigami.FormData.label: page.tr2("Активность:", "Activity:")
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

        // ── Оформление ──────────────────────────────────────────────────
        Kirigami.Separator { Kirigami.FormData.isSection: true }
        Kirigami.Heading { Kirigami.FormData.isSection: true; level: 3; text: page.tr2("Оформление", "Appearance") }

        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Непрозрачность фона:", "Background opacity:")
            from: 0; to: 100; value: page.cfg_backgroundOpacity
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { var n = parseInt(t); return isNaN(n) ? value : n }
            onValueModified: page.cfg_backgroundOpacity = value
        }

        // Цвет фона — RGB-пикер
        ColorPicker {
            Kirigami.FormData.label: page.tr2("Цвет фона:", "Background color:")
            Layout.fillWidth: true
            label: ""
            labelTheme:  page.tr2("Из темы", "From theme")
            labelCustom: page.tr2("Свой",    "Custom")
            mode:     page.cfg_backgroundColorMode
            hexColor: page.cfg_backgroundColor
            onModeChanged:  function(m) { page.cfg_backgroundColorMode = m }
            onColorChanged: function(h) { page.cfg_backgroundColor = h }
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Непрозрачность текста:", "Text opacity:")
            from: 10; to: 100; value: page.cfg_textOpacity
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 10 }
            onValueModified: page.cfg_textOpacity = value
        }

        // Цвет текста — RGB-пикер
        ColorPicker {
            Kirigami.FormData.label: page.tr2("Цвет текста:", "Text color:")
            Layout.fillWidth: true
            label: ""
            labelTheme:  page.tr2("Из темы", "From theme")
            labelCustom: page.tr2("Свой",    "Custom")
            mode:     page.cfg_textColorMode
            hexColor: page.cfg_textColor
            onModeChanged:  function(m) { page.cfg_textColorMode = m }
            onColorChanged: function(h) { page.cfg_textColor = h }
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
            valueFromText: function(t) { var n = parseInt(t); return isNaN(n) ? value : n }
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

        // ── Обновление ──────────────────────────────────────────────────
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
            from: 50; to: page.cfg_criticalPercent - 1; value: page.cfg_warningPercent
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 80 }
            onValueModified: page.cfg_warningPercent = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Критический уровень:", "Critical:")
            from: page.cfg_warningPercent + 1; to: 100; value: page.cfg_criticalPercent
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 90 }
            onValueModified: page.cfg_criticalPercent = value
        }
        Item { Kirigami.FormData.isSection: true; implicitHeight: 32 }
    }
}
