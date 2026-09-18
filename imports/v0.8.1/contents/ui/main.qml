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
    readonly property int wantedHeight: Math.min(Plasmoid.configuration.maxHeight,
        Math.max(220, pad * 2 + 38 + drives.count * rowH))
    property bool scanRunning: false
    property bool watchersRunning: false

    function tr2(r, e) { return ru ? r : e }
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
        var units = ru ? ["Б", "КиБ", "МиБ", "ГиБ", "ТиБ"] : ["B", "KiB", "MiB", "GiB", "TiB"]
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
        return tran ? tran.toUpperCase() + " " + name : tr2("Диск ", "Disk ") + name
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
            if (target === "/") label = tr2("Система", "System")
            else if (!label) label = basename(target)
            var physical = shortDrive(source, map)
            rows.push({
                title: label, target: target, source: source,
                fs: prettyFs(fs.fstype), physical: physical,
                total: size, available: available, used: used,
                icon: target === "/" ? "drive-harddisk-root" :
                    (physical.indexOf("USB ") === 0 ? "drive-removable-media-usb" : "drive-harddisk")
            })
            seen[source] = true
        }
        rows.sort(function(a, b) {
            if (a.target === "/") return -1
            if (b.target === "/") return 1
            return a.title.localeCompare(b.title)
        })
        drives.clear()
        for (var k = 0; k < rows.length; ++k) drives.append(rows[k])
        fitTimer.restart()
    }
    function refresh(delay) {
        if (delay > 0) { delayedRefresh.interval = delay; delayedRefresh.restart(); return }
        if (scanRunning) return
        scanRunning = true
        executable.connectSource(scanCommand)
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
    readonly property string mountWatchCommand: "/usr/bin/findmnt --poll=mount,umount,move,remount --first-only --output ACTION,TARGET"
    readonly property string udevWatchCommand: "/bin/sh -c \"" + udevWatchScript + "\""
    readonly property string udevWatchScript: "LC_ALL=C stdbuf -oL udevadm monitor --udev --subsystem-match=block --property 2>/dev/null "
        + "| grep -m1 -E '^ACTION=(add|remove|change)$'"

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation

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

        readonly property real baseAlpha: Plasmoid.configuration.backgroundOpacity / 100.0
        readonly property real edgeAlpha: baseAlpha * (1.0 - Plasmoid.configuration.edgeOpacity / 100.0)
        readonly property real curve: Plasmoid.configuration.edgeCurve / 100.0
        readonly property real edgeFraction: Math.min(0.45, Plasmoid.configuration.edgeWidth / Math.max(1, Math.min(width, height)))

        Rectangle {
            anchors.fill: parent
            radius: Plasmoid.configuration.rounded ? Plasmoid.configuration.cornerRadius : 0
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g,
                           Kirigami.Theme.backgroundColor.b, view.edgeAlpha)
        }
        Rectangle {
            anchors.fill: parent
            radius: Plasmoid.configuration.rounded ? Plasmoid.configuration.cornerRadius : 0
            color: "transparent"
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0) }
                GradientStop { position: Math.max(0.01, view.edgeFraction * (view.curve < 0 ? 1.7 : 0.65)); color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, view.baseAlpha) }
                GradientStop { position: 1.0 - Math.max(0.01, view.edgeFraction * (view.curve > 0 ? 0.65 : 1.7)); color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, view.baseAlpha) }
                GradientStop { position: 1.0; color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0) }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.pad
            spacing: 4
            opacity: Plasmoid.configuration.textOpacity / 100.0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                Kirigami.Icon { source: "drive-harddisk"; Layout.preferredWidth: 22; Layout.preferredHeight: 22 }
                PC3.Label { text: root.tr2("Диски", "Drives"); font.bold: true; font.pixelSize: 20; Layout.fillWidth: true }
                PC3.Label { text: drives.count; opacity: 0.72 }
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
                delegate: Item {
                    required property string title
                    required property string target
                    required property string source
                    required property string fs
                    required property string physical
                    required property double total
                    required property double available
                    required property int used
                    required property string icon
                    width: list.width - (list.contentHeight > list.height ? 10 : 0)
                    height: root.rowH

                    HoverHandler { id: hover }
                    TapHandler { onTapped: Qt.openUrlExternally("file://" + encodeURI(target)) }
                    QQC2.ToolTip.visible: hover.hovered
                    QQC2.ToolTip.text: source + "\n" + target

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 8
                        spacing: 14
                        Kirigami.Icon {
                            source: icon
                            Layout.preferredWidth: Math.min(64, root.rowH - 30)
                            Layout.preferredHeight: Layout.preferredWidth
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4
                            PC3.Label { text: title; font.bold: true; font.pixelSize: 18; elide: Text.ElideRight; Layout.fillWidth: true }
                            PC3.Label {
                                text: root.formatBytes(available) + " " + root.tr2("свободно из", "free of") + " " + root.formatBytes(total)
                                font.pixelSize: 16; elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            PC3.Label {
                                visible: Plasmoid.configuration.showFs || Plasmoid.configuration.showPhysical
                                text: {
                                    var a = Plasmoid.configuration.showFs ? fs : ""
                                    var b = Plasmoid.configuration.showPhysical ? physical : ""
                                    return a && b ? a + "  •  " + b : a + b
                                }
                                opacity: 0.72; font.pixelSize: 13; elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            QQC2.ProgressBar {
                                Layout.fillWidth: true; from: 0; to: 100; value: used
                                palette.highlight: used >= Plasmoid.configuration.criticalPercent ? Kirigami.Theme.negativeTextColor
                                    : used >= Plasmoid.configuration.warningPercent ? Kirigami.Theme.neutralTextColor
                                    : Kirigami.Theme.highlightColor
                            }
                            PC3.Label { Layout.alignment: Qt.AlignRight; text: used + "% " + root.tr2("занято", "used"); font.pixelSize: 13 }
                        }
                    }
                }
                PC3.Label {
                    anchors.centerIn: parent
                    visible: drives.count === 0
                    text: root.scanRunning ? root.tr2("Обновление…", "Refreshing…") : root.tr2("Доступные диски не найдены", "No accessible drives found")
                    opacity: 0.75
                }
            }
        }
    }
}
