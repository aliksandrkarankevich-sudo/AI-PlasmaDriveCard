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

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property bool ru: Plasmoid.configuration.language !== "en"
    readonly property int pad: Plasmoid.configuration.contentPadding
    readonly property int rowH: Plasmoid.configuration.rowHeight
    readonly property int wantedHeight: Math.max(150, Math.min(Plasmoid.configuration.maxHeight,
        pad * 2 + 38 + Math.max(1, drives.count) * rowH))
    property bool scanRunning: false
    property bool activityRunning: false
    property bool pendingRefresh: false
    property var previousIo: ({})
    property int lastMountCount: -1

    // ── Functions ────────────────────────────────────────────────────────────
    function tr2(r, e) { return ru ? r : e }
    function fontPx(base) { return Math.max(8, Math.round(base * Plasmoid.configuration.textScale / 100.0)) }
    function openTarget(target) {
        if (!target) return
        var url = target.endsWith("/") ? target : target + "/"
        Qt.openUrlExternally("file://" + encodeURI(url))
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
            lsblkData   = JSON.parse(output.substring(markerIndex + marker.length).trim())
        } catch (error) {
            console.warn("DriveCard JSON:", error)
            return
        }
        var map = ({})
        var blocks = lsblkData.blockdevices || []
        for (var i = 0; i < blocks.length; ++i) {
            var block = blocks[i]
            map[block.name]                   = block
            if (block.path) map[block.path]   = block
            map["/dev/" + block.name]         = block
            map["/dev/mapper/" + block.name]  = block
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
            var size      = Number(fs.size)  || 0
            var available = Number(fs.avail) || 0
            var used      = parseInt(String(fs["use%"] || "0")) || 0
            var label     = fs.label || ""
            if (target === "/")   label = tr2("Система", "System")
            else if (!label)      label = basename(target)
            var physical = shortDrive(source, map)
            rows.push({
                title: label, target: target, source: source,
                fs: prettyFs(fs.fstype), physical: physical,
                total: size, available: available, used: used,
                driveIcon: displayIcon(target, physical), kname: basename(source), active: false
            })
            seen[source] = true
        }
        rows.sort(function(a, b) {
            if (a.target === "/") return -1
            if (b.target === "/") return  1
            return a.title.localeCompare(b.title)
        })
        drives.clear()
        previousIo = ({})
        for (var k = 0; k < rows.length; ++k) drives.append(rows[k])
    }
    // pendingRefresh: if a scan is already running when hotplug fires,
    // set the flag and start a new scan as soon as the current one ends.
    function refresh(delay) {
        if (delay > 0) { delayedRefresh.interval = delay; delayedRefresh.restart(); return }
        if (scanRunning) { pendingRefresh = true; return }
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
            var row = drives.get(j)
            var now    = current[row.kname]
            var before = previousIo[row.kname]
            drives.setProperty(j, "active", now !== undefined && before !== undefined && now !== before)
        }
        previousIo = current
    }
    function refreshIcons() {
        for (var i = 0; i < drives.count; ++i) {
            var row = drives.get(i)
            drives.setProperty(i, "driveIcon", displayIcon(row.target, row.physical))
        }
    }

    // ── Commands ─────────────────────────────────────────────────────────────
    readonly property string scanCommand: "/bin/sh -c \"" + scanScript + "\""
    readonly property string scanScript:
        "LC_ALL=C findmnt --json --real --bytes -o SOURCE,TARGET,FSTYPE,LABEL,SIZE,AVAIL,USE%; "
        + "printf '\\n__DC_LSBLK__\\n'; "
        + "LC_ALL=C lsblk --json --bytes -l -o NAME,PATH,PKNAME,TYPE,TRAN,MODEL"
    readonly property string activityCommand: "/bin/cat /proc/diskstats"
    // Count mounted real filesystems — fires AFTER the kernel finishes
    // mounting, so findmnt in the main scan will already see the new drive.
    readonly property string hotplugCommand: "findmnt --real -n -o TARGET 2>/dev/null | wc -l"

    // ── Layout hints ─────────────────────────────────────────────────────────
    Layout.minimumWidth:    360
    Layout.preferredWidth:  470
    Layout.minimumHeight:   Plasmoid.configuration.autoFit ? wantedHeight : 220
    Layout.preferredHeight: Plasmoid.configuration.autoFit ? wantedHeight : 420
    Layout.maximumHeight:   Plasmoid.configuration.autoFit ? wantedHeight : 16777215

    ListModel { id: drives }

    // ── Main data source ──────────────────────────────────────────────────────
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        onNewData: function(sourceName, data) {
            if (sourceName === root.scanCommand) {
                disconnectSource(sourceName)
                root.scanRunning = false
                var output = data["stdout"] || ""
                if (output.length) root.rebuild(output)
                // If a hotplug event arrived while scan was running,
                // start another scan immediately so nothing is missed.
                if (root.pendingRefresh) {
                    root.pendingRefresh = false
                    root.refresh(0)
                }
            } else if (sourceName === root.activityCommand) {
                disconnectSource(sourceName)
                root.activityRunning = false
                root.applyActivity(data["stdout"] || "")
            } else if (sourceName === root.hotplugCommand) {
                disconnectSource(sourceName)
                var n = parseInt((data["stdout"] || "0").trim()) || 0
                if (root.lastMountCount >= 0 && n !== root.lastMountCount)
                    root.refresh(0)
                root.lastMountCount = n
            }
        }
    }

    // ── Timers ────────────────────────────────────────────────────────────────
    Timer {
        interval: Math.max(15, Plasmoid.configuration.updateInterval) * 1000
        repeat: true; running: true
        onTriggered: root.refresh(0)
    }
    Timer {
        interval: Math.max(1, Plasmoid.configuration.activityInterval) * 1000
        repeat: true; running: Plasmoid.configuration.showActivity; triggeredOnStart: true
        onTriggered: root.refreshActivity()
    }
    // Poll mounted filesystems every 1 s. Uses findmnt --real so the
    // counter changes only when a mount point actually appears/disappears.
    Timer {
        id: hotplugPoll
        interval: 1000
        repeat: true; running: true; triggeredOnStart: true
        onTriggered: executable.connectSource(root.hotplugCommand)
    }
    Timer { id: delayedRefresh; interval: 1200; repeat: false; onTriggered: root.refresh(0) }

    // ── Config watchers ───────────────────────────────────────────────────────
    Connections {
        target: Plasmoid.configuration
        function onShowRootChanged()  { root.refresh(0) }
        function onShowBootChanged()  { root.refresh(0) }
        function onIconStyleChanged() { root.refreshIcons() }
    }

    Component.onCompleted: Qt.callLater(function() { root.refresh(0) })

    // ── Full representation ───────────────────────────────────────────────────
    fullRepresentation: Item {
        id: view
        implicitWidth: 470

        readonly property color backgroundBase: Plasmoid.configuration.backgroundColorMode === "custom"
            ? Plasmoid.configuration.backgroundColor : Kirigami.Theme.backgroundColor
        readonly property color textBase: Plasmoid.configuration.textColorMode === "custom"
            ? Plasmoid.configuration.textColor : Kirigami.Theme.textColor
        readonly property color labelColor: Qt.rgba(
            textBase.r, textBase.g, textBase.b,
            Plasmoid.configuration.textOpacity / 100.0)

        EdgeFadeBackground {
            anchors.fill: parent
            baseColor:   view.backgroundBase
            centerAlpha: Plasmoid.configuration.backgroundOpacity / 100.0
            edgeAlpha:   Plasmoid.configuration.edgeOpacity / 100.0
            fadeWidth:   Plasmoid.configuration.edgeWidth
            curve:       Plasmoid.configuration.edgeCurve / 100.0
            radius:      Plasmoid.configuration.rounded ? Plasmoid.configuration.cornerRadius : 0
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.pad
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                Kirigami.Icon {
                    source: "drive-harddisk"
                    Layout.preferredWidth: 22; Layout.preferredHeight: 22
                }
                PC3.Label {
                    text: root.tr2("Диски", "Drives")
                    color: view.labelColor; font.bold: true
                    font.pixelSize: root.fontPx(20); Layout.fillWidth: true
                }
                PC3.Label {
                    text: drives.count
                    color: view.labelColor; opacity: 0.72
                    font.pixelSize: root.fontPx(13)
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: drives
                boundsBehavior: Flickable.StopAtBounds
                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    policy: list.contentHeight > list.height
                        ? QQC2.ScrollBar.AsNeeded
                        : QQC2.ScrollBar.AlwaysOff
                }

                delegate: QQC2.ItemDelegate {
                    required property string title
                    required property string target
                    required property string source
                    required property string fs
                    required property string physical
                    required property double total
                    required property double available
                    required property int    used
                    required property string driveIcon
                    required property string kname
                    required property bool   active

                    width:  list.width - (list.contentHeight > list.height ? 10 : 0)
                    height: root.rowH
                    padding: 0; leftPadding: 0; rightPadding: 0
                    topPadding: 0; bottomPadding: 0
                    onClicked: root.openTarget(target)

                    QQC2.ToolTip.visible: hovered
                    QQC2.ToolTip.text: source + "\n" + target
                    QQC2.ToolTip.delay: 600

                    background: Rectangle {
                        color: parent.hovered
                            ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                                      Kirigami.Theme.highlightColor.g,
                                      Kirigami.Theme.highlightColor.b, 0.12)
                            : "transparent"
                        radius: Plasmoid.configuration.rounded
                            ? Math.max(2, Plasmoid.configuration.cornerRadius - root.pad) : 0
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 8
                        spacing: 14

                        Item {
                            Layout.preferredWidth: Math.min(64, root.rowH - 30)
                            Layout.preferredHeight: Layout.preferredWidth
                            Kirigami.Icon { anchors.fill: parent; source: driveIcon }
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
                            spacing: 2

                            PC3.Label {
                                text: title; color: view.labelColor
                                font.bold: true; font.pixelSize: root.fontPx(18)
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            PC3.Label {
                                text: root.formatBytes(available) + " "
                                    + root.tr2("свободно из", "free of") + " "
                                    + root.formatBytes(total)
                                color: view.labelColor; font.pixelSize: root.fontPx(16)
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            PC3.Label {
                                visible: Plasmoid.configuration.showFs || Plasmoid.configuration.showPhysical
                                text: {
                                    var a = Plasmoid.configuration.showFs       ? fs       : ""
                                    var b = Plasmoid.configuration.showPhysical ? physical : ""
                                    return (a && b) ? (a + "  •  " + b) : (a + b)
                                }
                                color: view.labelColor; opacity: 0.72
                                font.pixelSize: root.fontPx(13)
                                elide: Text.ElideRight; Layout.fillWidth: true
                            }
                            PC3.Label {
                                Layout.alignment: Qt.AlignRight
                                text: used + "% " + root.tr2("занято", "used")
                                color: view.labelColor; font.pixelSize: root.fontPx(13)
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.max(4, Plasmoid.configuration.progressHeight)
                                clip: true
                                QQC2.ProgressBar {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    from: 0; to: 100; value: used
                                    palette.highlight:
                                        used >= Plasmoid.configuration.criticalPercent
                                            ? Kirigami.Theme.negativeTextColor
                                            : used >= Plasmoid.configuration.warningPercent
                                                ? Kirigami.Theme.neutralTextColor
                                                : Kirigami.Theme.highlightColor
                                }
                            }
                        }
                    }
                }

                PC3.Label {
                    anchors.centerIn: parent
                    visible: drives.count === 0
                    text: root.scanRunning
                        ? root.tr2("Обновление...", "Refreshing...")
                        : root.tr2("Доступные диски не найдены", "No accessible drives found")
                    color: view.labelColor; opacity: 0.75
                    font.pixelSize: root.fontPx(15)
                }
            }
        }
    }
}
