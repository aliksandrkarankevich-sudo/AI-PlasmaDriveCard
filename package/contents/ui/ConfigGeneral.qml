import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as Plasma5Support

KCM.SimpleKCM {
    id: page

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
    property string cfg_iconStyle
    property string cfg_customIconPath
    property string cfg_volumeOverrides
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
    property int    cfg_rowPaddingVDefault:         4
    property int    cfg_separatorHeightDefault:     1
    property int    cfg_textScaleDefault:           95
    property int    cfg_progressHeightDefault:      9
    property int    cfg_maxHeightDefault:           720
    property bool   cfg_showRootDefault:            true
    property bool   cfg_showBootDefault:            false
    property bool   cfg_showFsDefault:              true
    property string cfg_iconStyleDefault:           "drive"
    property string cfg_customIconPathDefault:      ""
    property string cfg_volumeOverridesDefault:     ""
    property bool   cfg_showActivityDefault:        true
    property int    cfg_activityIntervalDefault:    2
    property int    cfg_backgroundOpacityDefault:   60
    property string cfg_backgroundColorModeDefault: "theme"
    property string cfg_backgroundColorDefault:     "#20242b"
    property int    cfg_textOpacityDefault:         90
    property string cfg_textColorModeDefault:       "theme"
    property string cfg_textColorDefault:           "#eff0f1"
    property bool   cfg_roundedDefault:             true
    property int    cfg_cornerRadiusDefault:        30
    property int    cfg_edgeOpacityDefault:         100
    property int    cfg_edgeWidthDefault:           60
    property int    cfg_edgeCurveDefault:           -10
    property int    cfg_contentPaddingDefault:      10
    property int    cfg_updateIntervalDefault:      60
    property int    cfg_warningPercentDefault:      80
    property int    cfg_criticalPercentDefault:     90
    property string cfg_profilesDefault:            ""
    property string cfg_activeProfileDefault:       ""

    readonly property bool ru: cfg_language !== "en"
    function tr2(r, e) { return ru ? r : e }

    readonly property var _iconStyles: [
        { id: "drive",            ru: "Авто (по типу диска)", en: "Auto (by drive type)" },
        { id: "folder",           ru: "Папка",                en: "Folder" },
        { id: "folder-open",      ru: "Открытая папка",       en: "Open folder" },
        { id: "folder-documents", ru: "Папка с документами",  en: "Documents folder" },
        { id: "computer",         ru: "Компьютер",            en: "Computer" },
        { id: "custom",           ru: "Свой файл…",           en: "Custom file…" }
    ]
    function _iconIndex() {
        for (var i = 0; i < _iconStyles.length; ++i)
            if (_iconStyles[i].id === cfg_iconStyle) return i
        return 0
    }

    // ---- per-volume icon overrides (key = mount point) ----
    property string ovTarget: ""
    property var    mountList: []

    function _ovAll() {
        try {
            var o = JSON.parse(cfg_volumeOverrides || "{}")
            return (o && typeof o === "object" && !Array.isArray(o)) ? o : ({})
        } catch (e) { return ({}) }
    }
    function _ovEntry(target) {
        var e = _ovAll()[target]
        return (e && typeof e === "object") ? e : ({})
    }
    function _ovIcon(target) { return _ovEntry(target).icon || "" }
    function _ovSize(target) {
        var s = Number(_ovEntry(target).size)
        return (isFinite(s) && s >= 50 && s <= 300) ? Math.round(s) : 100
    }
    function _ovSet(target, icon, size) {
        if (!target) return
        var all = _ovAll()
        var e = ({})
        if (icon) e.icon = icon
        if (size && size !== 100) e.size = size
        if (Object.keys(e).length === 0) delete all[target]
        else all[target] = e
        cfg_volumeOverrides = Object.keys(all).length ? JSON.stringify(all) : ""
    }
    function _ovSummary() {
        var all = _ovAll()
        var keys = Object.keys(all)
        if (!keys.length) return tr2("Переопределений нет", "No overrides")
        return keys.map(function(k) {
            var e = all[k]
            var parts = []
            if (e.icon) parts.push(tr2("значок", "icon"))
            if (e.size) parts.push(e.size + "%")
            return k + " (" + parts.join(", ") + ")"
        }).join("\n")
    }

    Plasma5Support.DataSource {
        id: mountScan
        engine: "executable"
        readonly property string cmd: "findmnt -rn --real -o TARGET"
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var lines = (data["stdout"] || "").split("\n")
            var out = []
            for (var i = 0; i < lines.length; ++i) {
                var t = lines[i].trim().replace(/\\x20/g, " ")
                if (t && out.indexOf(t) < 0) out.push(t)
            }
            page.mountList = out
            if (!page.ovTarget && out.length) page.ovTarget = out[0]
        }
        Component.onCompleted: connectSource(cmd)
    }

    // ---- built-in factory profile (never stored, cannot be deleted/overwritten) ----
    readonly property string _factoryId: "__default__"
    readonly property var _factory: ({
        autoFit: true, rowPaddingV: 4, separatorHeight: 1,
        textScale: 95, progressHeight: 9, maxHeight: 720,
        showRoot: true, showBoot: false, showFs: true,
        iconStyle: "drive", customIconPath: "", volumeOverrides: "",
        showActivity: true, activityInterval: 2,
        backgroundOpacity: 60, backgroundColorMode: "theme", backgroundColor: "#20242b",
        textOpacity: 90, textColorMode: "theme", textColor: "#eff0f1",
        rounded: true, cornerRadius: 30,
        edgeOpacity: 100, edgeWidth: 60, edgeCurve: -10,
        contentPadding: 10, updateInterval: 60,
        warningPercent: 80, criticalPercent: 90
    })
    function _factoryLabel() { return tr2("По умолчанию", "Default") }
    function _displayName(n) { return n === _factoryId ? _factoryLabel() : n }
    function _isReserved(n) {
        var t = (n || "").trim().toLowerCase()
        return t === _factoryId || t === "по умолчанию" || t === "default"
    }

    // ---- profiles ----
    function _loadProfiles() {
        if (!cfg_profiles || cfg_profiles.trim() === "") return []
        try { return JSON.parse(cfg_profiles) } catch(e) { return [] }
    }
    function _saveProfiles(arr) { cfg_profiles = JSON.stringify(arr) }
    function _profileNames() { return _loadProfiles().map(function(p) { return p.name }) }
    function _currentSnapshot(name) {
        return {
            name: name,
            language: cfg_language, autoFit: cfg_autoFit,
            rowPaddingV: cfg_rowPaddingV, separatorHeight: cfg_separatorHeight,
            textScale: cfg_textScale, progressHeight: cfg_progressHeight,
            maxHeight: cfg_maxHeight, showRoot: cfg_showRoot, showBoot: cfg_showBoot,
            showFs: cfg_showFs, iconStyle: cfg_iconStyle,
            customIconPath: cfg_customIconPath,
            volumeOverrides: cfg_volumeOverrides,
            showActivity: cfg_showActivity, activityInterval: cfg_activityInterval,
            backgroundOpacity: cfg_backgroundOpacity,
            backgroundColorMode: cfg_backgroundColorMode, backgroundColor: cfg_backgroundColor,
            textOpacity: cfg_textOpacity,
            textColorMode: cfg_textColorMode, textColor: cfg_textColor,
            rounded: cfg_rounded, cornerRadius: cfg_cornerRadius,
            edgeOpacity: cfg_edgeOpacity, edgeWidth: cfg_edgeWidth, edgeCurve: cfg_edgeCurve,
            contentPadding: cfg_contentPadding, updateInterval: cfg_updateInterval,
            warningPercent: cfg_warningPercent, criticalPercent: cfg_criticalPercent
        }
    }
    function saveProfile(name) {
        if (!name || name.trim() === "" || _isReserved(name)) return
        var arr = _loadProfiles()
        var idx = arr.findIndex(function(p) { return p.name === name })
        var snap = _currentSnapshot(name)
        if (idx >= 0) arr[idx] = snap; else arr.push(snap)
        _saveProfiles(arr)
        cfg_activeProfile = name
        profileModel.reload()
    }
    function loadProfile(name) {
        var p
        if (name === _factoryId) {
            p = JSON.parse(JSON.stringify(_factory))
            p.language = cfg_language   // keep the user's current UI language
        } else {
            p = _loadProfiles().find(function(x) { return x.name === name })
        }
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
        cfg_iconStyle           = p.iconStyle           !== undefined ? p.iconStyle           : cfg_iconStyleDefault
        cfg_customIconPath      = p.customIconPath      !== undefined ? p.customIconPath      : cfg_customIconPathDefault
        cfg_volumeOverrides     = p.volumeOverrides     !== undefined ? p.volumeOverrides     : cfg_volumeOverridesDefault
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
        if (name === _factoryId) return
        var arr = _loadProfiles().filter(function(p) { return p.name !== name })
        _saveProfiles(arr)
        if (cfg_activeProfile === name) cfg_activeProfile = ""
        profileModel.reload()
    }

    ListModel {
        id: profileModel
        function reload() {
            clear()
            append({ pname: page._factoryId, builtin: true })
            var names = page._profileNames()
            for (var i = 0; i < names.length; ++i) append({ pname: names[i], builtin: false })
        }
        Component.onCompleted: reload()
    }

    FileDialog {
        id: iconDialog
        title: page.tr2("Выберите значок", "Choose an icon")
        nameFilters: [page.tr2("Изображения (*.svg *.svgz *.png)", "Images (*.svg *.svgz *.png)")]
        onAccepted: {
            var p = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""))
            page.cfg_customIconPath = p
            page.cfg_iconStyle = "custom"
        }
    }

    FileDialog {
        id: volumeIconDialog
        title: page.tr2("Значок для тома", "Icon for volume")
        nameFilters: [page.tr2("Изображения (*.svg *.svgz *.png *.jpg *.jpeg *.webp)",
                               "Images (*.svg *.svgz *.png *.jpg *.jpeg *.webp)")]
        onAccepted: {
            var p = decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, ""))
            page._ovSet(page.ovTarget, p, page._ovSize(page.ovTarget))
        }
    }

    Kirigami.FormLayout {
        // ---- Profiles ----
        Kirigami.Heading {
            Kirigami.FormData.isSection: true; level: 3
            text: page.tr2("Профили настроек", "Settings Profiles")
                + (page.cfg_activeProfile ? "  —  " + page._displayName(page.cfg_activeProfile) : "")
        }

        ListView {
            Kirigami.FormData.label: page.tr2("Сохранённые:", "Saved:")
            Layout.fillWidth: true
            implicitHeight: Math.min(profileModel.count * 40, 200)
            model: profileModel
            clip: true
            delegate: RowLayout {
                width: ListView.view ? ListView.view.width : 0
                height: 38
                spacing: Kirigami.Units.smallSpacing
                QQC2.Label {
                    text: page._displayName(model.pname)
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: model.pname === page.cfg_activeProfile
                        ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                    font.bold: model.pname === page.cfg_activeProfile
                }
                QQC2.Button {
                    text: model.builtin ? page.tr2("Сбросить", "Reset") : page.tr2("Загрузить", "Load")
                    onClicked: page.loadProfile(model.pname)
                }
                QQC2.Button {
                    visible: !model.builtin
                    text: page.tr2("Удалить", "Delete")
                    onClicked: page.deleteProfile(model.pname)
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: page.tr2("Новый профиль:", "New profile:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            QQC2.TextField {
                id: profileNameField
                Layout.fillWidth: true
                placeholderText: page.tr2("Название...", "Name...")
                text: page.cfg_activeProfile === page._factoryId ? "" : page.cfg_activeProfile
            }
            QQC2.Button {
                text: page.tr2("Сохранить", "Save")
                enabled: profileNameField.text.trim().length > 0
                    && !page._isReserved(profileNameField.text)
                onClicked: page.saveProfile(profileNameField.text.trim())
            }
        }

        // ---- Language ----
        Kirigami.Separator { Kirigami.FormData.isSection: true }
        QQC2.ComboBox {
            Kirigami.FormData.label: page.tr2("Язык:", "Language:")
            model: ["Русский", "English"]
            currentIndex: page.cfg_language === "en" ? 1 : 0
            onActivated: page.cfg_language = currentIndex === 1 ? "en" : "ru"
        }

        // ---- Size ----
        Kirigami.Heading { Kirigami.FormData.isSection: true; level: 3; text: page.tr2("Размер", "Size") }

        QQC2.CheckBox {
            Kirigami.FormData.label: page.tr2("Высота:", "Height:")
            text: page.tr2("Подбирать автоматически", "Fit automatically")
            checked: page.cfg_autoFit
            onToggled: page.cfg_autoFit = checked
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Отступ строки:", "Row padding:")
            from: 4; to: 40; stepSize: 2; value: page.cfg_rowPaddingV
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 4 }
            onValueModified: page.cfg_rowPaddingV = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Отступ между дисками:", "Gap between drives:")
            from: 0; to: 32; stepSize: 1; value: page.cfg_separatorHeight
            textFromValue: function(v) { return v === 0 ? page.tr2("выключен", "off") : v + " px" }
            valueFromText: function(t) { return parseInt(t) || 0 }
            onValueModified: page.cfg_separatorHeight = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Масштаб текста:", "Text scale:")
            from: 70; to: 160; stepSize: 5; value: page.cfg_textScale
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 95 }
            onValueModified: page.cfg_textScale = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Толщина полосы:", "Bar thickness:")
            from: 4; to: 48; value: page.cfg_progressHeight
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 9 }
            onValueModified: page.cfg_progressHeight = value
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Максимальная высота:", "Maximum height:")
            from: 240; to: 1600; stepSize: 20; value: page.cfg_maxHeight
            textFromValue: function(v) { return v + " px" }
            valueFromText: function(t) { return parseInt(t) || 720 }
            onValueModified: page.cfg_maxHeight = value
        }

        // ---- Content ----
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
        QQC2.ComboBox {
            Kirigami.FormData.label: page.tr2("Вид значка:", "Icon style:")
            model: page._iconStyles.map(function(s) { return page.ru ? s.ru : s.en })
            currentIndex: page._iconIndex()
            onActivated: {
                var id = page._iconStyles[currentIndex].id
                page.cfg_iconStyle = id
                if (id === "custom" && !page.cfg_customIconPath) iconDialog.open()
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            text: page.tr2("Общий значок для всех дисков. Для отдельных томов его можно переопределить ниже.",
                           "One icon for all drives. You can override it for individual volumes below.")
        }
        RowLayout {
            Kirigami.FormData.label: page.tr2("Своя картинка:", "Custom picture:")
            Layout.fillWidth: true
            visible: page.cfg_iconStyle === "custom"
            spacing: Kirigami.Units.smallSpacing
            QQC2.TextField {
                Layout.fillWidth: true
                text: page.cfg_customIconPath
                placeholderText: "/home/…/icon.svg"
                onEditingFinished: page.cfg_customIconPath = text.trim()
            }
            QQC2.Button {
                text: page.tr2("Выбрать…", "Browse…")
                onClicked: iconDialog.open()
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            visible: page.cfg_iconStyle === "custom"
            wrapMode: Text.Wrap
            opacity: 0.7
            font: Kirigami.Theme.smallFont
            text: page.tr2("Файл SVG, SVGZ или PNG, который будет показан у всех дисков.",
                           "An SVG, SVGZ or PNG file shown next to all drives.")
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

        // ---- Volume icons ----
        Kirigami.Heading { Kirigami.FormData.isSection: true; level: 3; text: page.tr2("Значки томов", "Volume icons") }

        QQC2.ComboBox {
            id: ovCombo
            Kirigami.FormData.label: page.tr2("Том (точка монтирования):", "Volume (mount point):")
            Layout.fillWidth: true
            editable: true
            model: page.mountList
            editText: page.ovTarget
            onActivated: page.ovTarget = currentText
            onAccepted: page.ovTarget = editText.trim()
        }
        RowLayout {
            Kirigami.FormData.label: page.tr2("Картинка:", "Picture:")
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing
            QQC2.TextField {
                Layout.fillWidth: true
                enabled: page.ovTarget.length > 0
                text: page._ovIcon(page.ovTarget)
                placeholderText: page.tr2("Путь к файлу или имя иконки из темы", "File path or theme icon name")
                onEditingFinished: page._ovSet(page.ovTarget, text.trim(), page._ovSize(page.ovTarget))
            }
            QQC2.Button {
                text: page.tr2("Выбрать…", "Browse…")
                enabled: page.ovTarget.length > 0
                onClicked: volumeIconDialog.open()
            }
        }
        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Размер значка:", "Icon size:")
            enabled: page.ovTarget.length > 0
            from: 50; to: 300; stepSize: 10
            value: page._ovSize(page.ovTarget)
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { var n = parseInt(t); return isNaN(n) ? 100 : n }
            onValueModified: page._ovSet(page.ovTarget, page._ovIcon(page.ovTarget), value)
        }
        QQC2.Button {
            text: page.tr2("Сбросить для этого тома", "Reset for this volume")
            enabled: page.ovTarget.length > 0
                && (page._ovIcon(page.ovTarget).length > 0 || page._ovSize(page.ovTarget) !== 100)
            onClicked: page._ovSet(page.ovTarget, "", 100)
        }
        QQC2.Label {
            Kirigami.FormData.label: page.tr2("Задано:", "Configured:")
            Layout.fillWidth: true
            text: page._ovSummary()
            wrapMode: Text.Wrap
            opacity: 0.8
        }

        // ---- Appearance ----
        Kirigami.Heading { Kirigami.FormData.isSection: true; level: 3; text: page.tr2("Оформление", "Appearance") }

        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Непрозрачность фона:", "Background opacity:")
            from: 0; to: 100; value: page.cfg_backgroundOpacity
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { var n = parseInt(t); return isNaN(n) ? value : n }
            onValueModified: page.cfg_backgroundOpacity = value
        }

        ColorPicker {
            Kirigami.FormData.label: page.tr2("Цвет фона:", "Background color:")
            Layout.fillWidth: true
            label: ""
            labelTheme:  page.tr2("Из темы", "From theme")
            labelCustom: page.tr2("Свой",    "Custom")
            mode:     page.cfg_backgroundColorMode
            hexColor: page.cfg_backgroundColor
            onModeSelected: function(m) { page.cfg_backgroundColorMode = m }
            onColorPicked:  function(h) { page.cfg_backgroundColor = h }
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr2("Непрозрачность текста:", "Text opacity:")
            from: 10; to: 100; value: page.cfg_textOpacity
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) || 10 }
            onValueModified: page.cfg_textOpacity = value
        }

        ColorPicker {
            Kirigami.FormData.label: page.tr2("Цвет текста:", "Text color:")
            Layout.fillWidth: true
            label: ""
            labelTheme:  page.tr2("Из темы", "From theme")
            labelCustom: page.tr2("Свой",    "Custom")
            mode:     page.cfg_textColorMode
            hexColor: page.cfg_textColor
            onModeSelected: function(m) { page.cfg_textColorMode = m }
            onColorPicked:  function(h) { page.cfg_textColor = h }
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
            valueFromText: function(t) { return parseInt(t) || 10 }
            onValueModified: page.cfg_contentPadding = value
        }

        // ---- Refresh ----
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
    }
}
