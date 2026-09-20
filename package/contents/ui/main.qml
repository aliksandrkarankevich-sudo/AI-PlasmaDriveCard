import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PC3
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property bool ru: Plasmoid.configuration.language !== "en"
    readonly property int pad: Plasmoid.configuration.contentPadding
    readonly property int rowH: Plasmoid.configuration.rowHeight
    readonly property int wantedHeight: Math.max(150, Math.min(Plasmoid.configuration.maxHeight,
        pad * 2 + 38 + Math.max(1, drives.count) * rowH))
    property bool scanRunning: false
    property bool activityRunning: false
    property bool watchersRunning: false
    property var previousIo: ({})

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation

    function tr2(r, e) { return ru ? r : e }
    function fontPx(base) { return Math.max(8, Math.round(base * Plasmoid.configuration.textScale / 100.0)) }
    function openTarget(target) {
        if (!target) return
        // normalize: root stays "/", everything else strips trailing slash
        var t = target === "/" ? target : target.replace(/\/+$/, "")
        Qt.openUrlExternally("file://" + encodeURI(t))
    }
    function displayIcon(target, physical) {
        if (Plasmoid.configuration.iconStyle === "folder") return "folder"
        if (Plasmoid.configuration.iconStyle === "folder-open") return "folder-open"
        return target === "/" ? "drive-harddisk-root" :
            (physical.indexOf("USB ") === 0 ? "drive-removable-media-usb" : "drive-harddisk")
    }
    function basename(path) {
        var p = (path || "").replace(/\/$/, "")
        return decodeURIComponent(p.substring(p.lastIndexOf("/") + 1)) || p
    }
    function cleanSource(source) { return (source || "").replace(/\[.*\]$/, "") }
    function prettyFs(value) {
        var v = (value || "").toLowerCase()
        if (v === "btrfs") return "Btrfs"
        if (v === "vfat") return "FAT"
        if (v === "exfat") return "exFAT"
        return v.toUpperCase()
    }
    function formatBytes(number) {
        var n = Number(number) || 0
        var units = ru ? ["\u0411", "\u041a\u0438\u0411", "\u041c\u0438\u0411", "\u0413\u0438\u0411", "\u0422\u0438\u0411"] : ["B", "KiB", "MiB", "GiB", "TiB"]
        var i = 0
        while (n >= 1024 && i < units.length - 1) { n /= 1024; ++i }
        return Qt.locale(ru ? "ru_RU" : "en_US").toString(n, "f", i < 3 ? 0 : 1) + " " + units[i]
    }
    function shortDrive(source, map) {
        var key = cleanSource(source)
        var node = map[key] || map[basename(key)]
        var guard = 0
        while (node && node.type !== "disk" && node.pkname && guard++ < 12)
            node = map[node.pkname] || map["/dev/" + node.pkname]
        if (!node) return ""
        var name = node.name || basename(node.path || "")
        var tran = (node.tran || "").toLowerCase()
        var match = /^nvme(\d+)n\d+$/.exec(name)
        if (match) return "NVMe " + match[1]
        if (tran === "usb") return "USB " + name
        if (tran === "sata" || /^sd[a-z]+$/.test(name)) return "SATA " + name
        return tran ? tran.toUpperCase() + " " + name : tr2("\u0414\u0438\u0441\u043a ", "Disk ") + name
    }
    function flatten(items, output) {
        for (var i = 0; i < (items || []).length; ++i) {
            output.push(items[i])
            if (items[i].children) flatten(items[i].children, output)
        }
    }
    function rebuild(output) {
        var marker = "__DC_LSBLK__"
        var markerIndex = output.indexOf(marker)
        if (markerIndex < 0) return
        var findmntData
        var lsblkData
        try {
            findmntData = JSON.parse(output.substring(0, markerIndex).trim())
            lsblkData = JSON.parse(output.substring(markerIndex + marker.length).trim())
        } catch (error) {
            console.warn("DriveCard JSON:", error)
            return
        }
        var map = ({})
        var blocks = lsblkData.blockdevices || []
        for (var i = 0; i < blocks.length; ++i) {
            var block = blocks[i]
            map[block.name] = block
            if (block.path) map[block.path] = block
            map["/dev/" + block.name] = block
            map["/dev/mapper/" + block.name] = block
        }
        var all = []
        var rows = []
        var seen = ({})
        flatten(findmntData.filesystems || [], all)
        for (var j = 0; j < all.length; ++j) {
            var fs = all[j]
            var target = fs.target || ""
            var source = cleanSource(fs.source)
            if (!target || source.indexOf("/dev/") !== 0) continue
            if (!Plasmoid.configuration.showRoot && target === "/") continue
            if (!Plasmoid.configuration.showBoot && (target === "/boot" || target === "/boot/efi")) continue
            if (seen[source]) continue
            var size = Number(fs.size) || 0
            var available = Number(fs.avail) || 0
            var used = parseInt(String(fs["use%"] || "0")) || 0
            var label = fs.label || ""
            if (target === "/") label = tr2("\u0421\u0438\u0441\u0442\u0435\u043c\u0430", "System")
            else if (!label) label = basename(target)
            var physical = shortDrive(source, map)
            rows.push({
                title: label, target: target, source: source,
                fs: prettyFs(fs.fstype), physical: physical,
                total: size, available: available, used: used,
                icon: displayIcon(target, physical), kname: basename(source), active: false
            })
            seen[source] = true
        }
        rows.sort(function(a, b) {
            if (a.target === "/") return -1
            if (b.target === "/") return 1
            return a.title.localeCompare(b.title)
        })
        drives.clear()
        previousIo = ({})
        for (var k = 0; k < rows.length; ++k) drives.append(rows[k])
        fitTimer.restart()
    }
    function refresh(delay) {
        if (delay > 0) { delayedRefresh.interval = delay; delayedRefresh.restart(); return }
        if (scanRunning) return
        scanRunning = true
        executable.connectSource(scanCommand)
    }
    function refreshActivity() {
        if (!Plasmoid.configuration.showActivity || activityRunning) return
        activityRunning = true
        executable.connectSource(activityCommand)
    }
    function applyActivity(output) {
        var current = ({})
        var lines = output.split("\n")
        for (var i = 0; i < lines.length; ++i) {
            var parts = lines[i].trim().split(/\s+/)
            if (parts.length >= 11) current[parts[2]] = String(parts[3]) + ":" + String(parts[7])
        }
        for (var j = 0; j < drives.count; ++j) {
            var row = drives.get(j), now = current[row.kname], before = previousIo[row.kname]
            drives.setProperty(j, "active", now !== undefined && before !== undefined && now !== before)
        }
        previousIo = current
    }
    function stopWatchers() {
        executable.disconnectSource(mountWatchCommand)
        executable.disconnectSource(udevWatchCommand)
        watchersRunning = false
    }
    function startWatchers() {
        if (watchersRunning) return
        watchersRunning = true
        executable.connectSource(mountWatchCommand)
        executable.connectSource(udevWatchCommand)
    }
    function storageEvent() {
        stopWatchers()
        refresh(1200)
        watcherRestart.restart()
    }

    readonly property string scanCommand: "/bin/sh -c \"" + scanScript + "\""
    readonly property string scanScript: "LC_ALL=C findmnt --json --real --bytes -o SOURCE,TARGET,FSTYPE,LABEL,SIZE,AVAIL,USE%; "
        + "printf '\\n__DC_LSBLK__\\n'; "
        + "LC_ALL=C lsblk --json --bytes -l -o NAME,PATH,PKNAME,TYPE,TRAN,MODEL"
    readonly property string activityCommand: "/bin/cat /proc/diskstats"
    readonly property string mountWatchCommand: "/usr/bin/findmnt --poll=mount,umount,move,remount --first-only --output ACTION,TARGET"
    readonly property string udevWatchCommand: "/bin/sh -c \"" + udevWatchScript + "\""
    readonly property string udevWatchScript: "LC_ALL=C stdbuf -oL udevadm monitor --udev --subsystem-match=block --property 2>/dev/null "
        + "| grep -m1 -E '^ACTION=(add|remove|change)$'"

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    Layout.minimumWidth: 360
    Layout.preferredWidth: 470
    Layout.minimumHeight: Plasmoid.configuration.autoFit ? wantedHeight : 220
    Layout.preferredHeight: Plasmoid.configuration.autoFit ? wantedHeight : 420
    Layout.maximumHeight: Plasmoid.configuration.autoFit ? wantedHeight : 16777215

    ListModel { id: drives }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        onNewData: function(sourceName, data) {
            if (sourceName === root.scanCommand) {
                disconnectSource(sourceName)
                root.scanRunning = false
                var output = data["stdout"] || ""
                if (output.length) root.rebuild(output)
            } else if (sourceName === root.activityCommand) {
                disconnectSource(sourceName)
                root.activityRunning = false
                root.applyActivity(data["stdout"] || "")
            } else if (sourceName === root.mountWatchCommand || sourceName === root.udevWatchCommand) {
                root.storageEvent()
            }
        }
    }
    Timer { id: delayedRefresh; interval: 1200; repeat: false; onTriggered: root.refresh(0) }
    Timer { id: watcherRestart; interval: 1800; repeat: false; onTriggered: root.startWatchers() }
    Timer {
        interval: Math.max(15, Plasmoid.configuration.updateInterval) * 1000
        repeat: true; running: true; onTriggered: root.refresh(0)
    }
    Timer {
        interval: Math.max(1, Plasmoid.configuration.activityInterval) * 1000
        repeat: true; running: Plasmoid.configuration.showActivity; triggeredOnStart: true
        onTriggered: root.refreshActivity()
    }
    Timer {
        id: fitTimer; interval: 150; repeat: false
        onTriggered: {
            if (!Plasmoid.configuration.autoFit) return
            root.Layout.minimumHeight = root.wantedHeight
            root.Layout.preferredHeight = root.wantedHeight
            root.Layout.maximumHeight = root.wantedHeight
            root.height = root.wantedHeight
        }
    }
    Connections {
        target: Plasmoid.configuration
        function onShowRootChanged() { root.refresh(0) }
        function onShowBootChanged() { root.refresh(0) }
        function onRowHeightChanged() { fitTimer.restart() }
        function onMaxHeightChanged() { fitTimer.restart() }
        function onAutoFitChanged() { fitTimer.restart() }
    }
    Component.onCompleted: { refresh(0); startWatchers() }
    Component.onDestruction: stopWatchers()

    fullRepresentation: Item {
        id: view
        implicitWidth: 470
        implicitHeight: root.wantedHeight
        Layout.minimumWidth: 360
        Layout.preferredWidth: 470
        Layout.minimumHeight: Plasmoid.configuration.autoFit ? root.wantedHeight : 220
        Layout.preferredHeight: Plasmoid.configuration.autoFit ? root.wantedHeight : 420
        Layout.maximumHeight: Plasmoid.configuration.autoFit ? root.wantedHeight : 16777215

        readonly property color backgroundBase: Plasmoid.configuration.backgroundColorMode === "custom"
            ? Plasmoid.configuration.backgroundColor : Kirigami.Theme.backgroundColor
        readonly property color textBase: Plasmoid.configuration.textColorMode === "custom"
            ? Plasmoid.configuration.textColor : Kirigami.Theme.textColor
        readonly property color labelColor: Qt.rgba(textBase.r, textBase.g, textBase.b,
            Plasmoid.configuration.textOpacity / 100.0)
        readonly property real baseAlpha: Plasmoid.configuration.backgroundOpacity / 100.0
        // edgeAlpha: fully transparent at edge when edgeOpacity==100, fully opaque when edgeOpacity==0
        readonly property real edgeAlpha: baseAlpha * (1.0 - Plasmoid.configuration.edgeOpacity / 100.0)
        readonly property real curve: Plasmoid.configuration.edgeCurve / 100.0
        // edgeFraction: fraction of width/height used for the fade zone on each side
        readonly property real edgeFraction: Plasmoid.configuration.edgeWidth <= 0 ? 0.0
            : Math.min(0.45, Plasmoid.configuration.edgeWidth / Math.max(1, Math.min(width, height)))

        // ---- Background: single solid rect + two gradient masks (H and V) ----
        // Solid base at baseAlpha
        Rectangle {
            anchors.fill: parent
            radius: Plasmoid.configuration.rounded ? Plasmoid.configuration.cornerRadius : 0
            color: Qt.rgba(view.backgroundBase.r, view.backgroundBase.g,
                           view.backgroundBase.b, view.baseAlpha)
        }
        // Horizontal fade mask (left + right edges)
        Rectangle {
            anchors.fill: parent
            radius: Plasmoid.configuration.rounded ? Plasmoid.configuration.cornerRadius : 0
            visible: view.edgeFraction > 0
            color: "transparent"
            gradient: Gradient {
                orientation: Gradient.Horizontal
                // Position helpers for symmetric easing via curve parameter
                // curve > 0 = faster fade (more transparent sooner)
                // curve < 0 = slower fade (stays opaque longer before fading)
                property real p1: Math.max(0.001, view.edgeFraction * (1.0 + view.curve))
                property real p2: Math.min(0.499, 1.0 - Math.max(0.001, view.edgeFraction * (1.0 + view.curve)))
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(view.backgroundBase.r, view.backgroundBase.g,
                                   view.backgroundBase.b, view.edgeAlpha - view.baseAlpha)
                }
                GradientStop {
                    position: parent.p1
                    color: Qt.rgba(view.backgroundBase.r, view.backgroundBase.g,
                                   view.backgroundBase.b, 0)
                }
                GradientStop {
                    position: parent.p2
                    color: Qt.rgba(view.backgroundBase.r, view.backgroundBase.g,
                                   view.backgroundBase.b, 0)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(view.backgroundBase.r, view.backgroundBase.g,
                                   view.backgroundBase.b, view.edgeAlpha - view.baseAlpha)
                }
            }
        }
        // Vertical fade mask (top + bottom edges)
        Rectangle {
            anchors.fill: parent
            radius: Plasmoid.configuration.rounded ? Plasmoid.configuration.cornerRadius : 0
            visible: view.edgeFraction > 0
            color: "transparent"
            gradient: Gradient {
                orientation: Gradient.Vertical
                property real p1: Math.max(0.001, view.edgeFraction * (1.0 + view.curve))
                property real p2: Math.min(0.499, 1.0 - Math.max(0.001, view.edgeFraction * (1.0 + view.curve)))
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(view.backgroundBase.r, view.backgroundBase.g,
                                   view.backgroundBase.b, view.edgeAlpha - view.baseAlpha)
                }
                GradientStop {
                    position: parent.p1
                    color: Qt.rgba(view.backgroundBase.r, view.backgroundBase.g,
                                   view.backgroundBase.b, 0)
                }
                GradientStop {
                    position: parent.p2
                    color: Qt.rgba(view.backgroundBase.r, view.backgroundBase.g,
                                   view.backgroundBase.b, 0)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(view.backgroundBase.r, view.backgroundBase.g,
                                   view.backgroundBase.b, view.edgeAlpha - view.baseAlpha)
                }
            }
        }
        // ---------------------------------------------------------------------

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.pad
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                Kirigami.Icon { source: "drive-harddisk"; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
                PC3.Label { text: root.tr2("\u0414\u0438\u0441\u043a\u0438", "Drives"); color: view.labelColor; font.bold: true; font.pixelSize: root.fontPx(20); Layout.fillWidth: true }
                PC3.Label { text: drives.count; color: view.labelColor; opacity: 0.72; font.pixelSize: root.fontPx(13) }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: drives
                boundsBehavior: Flickable.StopAtBounds
                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    policy: list.contentHeight > list.height ? QQC2.ScrollBar.AsNeeded : QQC2.ScrollBar.AlwaysOff
                }
                delegate: QQC2.ItemDelegate {
                    required property string title
                    required property string target
                    required property string source
                    required property string fs
                    required property string physical
                    required property double total
                    required property double available
                    required property int used
                    required property string icon
                    required property string kname
                    required property bool active

                    width: list.width - (list.contentHeight > list.height ? 10 : 0)
                    height: root.rowH
                    // Full-row click opens the drive in the file manager
                    onClicked: root.openTarget(target)

                    background: Rectangle {
                        radius: Plasmoid.configuration.rounded
                            ? Math.max(0, Plasmoid.configuration.cornerRadius - root.pad)
                            : 0
                        color: parent.hovered
                            ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                      Kirigami.Theme.highlightColor.g,
                                      Kirigami.Theme.highlightColor.b,
                                      parent.pressed ? 0.22 : 0.12)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: source + "\n" + target + "\n" + root.tr2("\u041d\u0430\u0436\u043c\u0438\u0442\u0435 \u0434\u043b\u044f \u043e\u0442\u043a\u0440\u044b\u0442\u0438\u044f", "Click to open")

                    contentItem: RowLayout {
                        anchors.leftMargin: 4
                        anchors.rightMargin: 8
                        spacing: 14
                        Item {
                            Layout.preferredWidth: Math.min(64, root.rowH - 30)
                            Layout.preferredHeight: Layout.preferredWidth
                            Kirigami.Icon { anchors.fill: parent; source: icon }
                            Rectangle {
                                visible: Plasmoid.configuration.showActivity && active
                                width: 12; height: 12; radius: 6
                                anchors.right: parent.right; anchors.bottom: parent.bottom
                                color: Kirigami.Theme.positiveTextColor
                                border.width: 2; border.color: Kirigami.Theme.backgroundColor
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4
                            PC3.Label { text: title; color: view.labelColor; font.bold: true; font.pixelSize: root.fontPx(18); elide: Text.ElideRight; Layout.fillWidth: true }
                            PC3.Label {
                                text: root.formatBytes(available) + " " + root.tr2("\u0441\u0432\u043e\u0431\u043e\u0434\u043d\u043e \u0438\u0437", "free of") + " " + root.formatBytes(total)
                                color: view.labelColor; font.pixelSize: root.fontPx(16); elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            PC3.Label {
                                visible: Plasmoid.configuration.showFs || Plasmoid.configuration.showPhysical
                                text: {
                                    var a = Plasmoid.configuration.showFs ? fs : ""
                                    var b = Plasmoid.configuration.showPhysical ? physical : ""
                                    return a && b ? a + "  \u2022  " + b : a + b
                                }
                                color: view.labelColor; opacity: 0.72; font.pixelSize: root.fontPx(13); elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            QQC2.ProgressBar {
                                Layout.fillWidth: true; Layout.preferredHeight: Plasmoid.configuration.progressHeight; from: 0; to: 100; value: used
                                palette.highlight: used >= Plasmoid.configuration.criticalPercent ? Kirigami.Theme.negativeTextColor
                                    : used >= Plasmoid.configuration.warningPercent ? Kirigami.Theme.neutralTextColor
                                    : Kirigami.Theme.highlightColor
                            }
                            PC3.Label { Layout.alignment: Qt.AlignRight; text: used + "% " + root.tr2("\u0437\u0430\u043d\u044f\u0442\u043e", "used"); color: view.labelColor; font.pixelSize: root.fontPx(13) }
                        }
                    }
                }
                PC3.Label {
                    anchors.centerIn: parent
                    visible: drives.count === 0
                    text: root.scanRunning ? root.tr2("\u041e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u0435\u2026", "Refreshing\u2026") : root.tr2("\u0414\u043e\u0441\u0442\u0443\u043f\u043d\u044b\u0435 \u0434\u0438\u0441\u043a\u0438 \u043d\u0435 \u043d\u0430\u0439\u0434\u0435\u043d\u044b", "No accessible drives found")
                    color: view.labelColor
                    opacity: 0.75
                    font.pixelSize: root.fontPx(15)
                }
            }
        }
    }
}
