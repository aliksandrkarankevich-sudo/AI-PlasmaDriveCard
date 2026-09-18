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
    readonly property int rowH: Plasmoid.configuration.rowHeight
    readonly property int safeMargin: Plasmoid.configuration.outerMargin
    readonly property int protection: Math.round(Plasmoid.configuration.edgeWidth * Plasmoid.configuration.contentProtection / 100)
    readonly property int innerPad: Plasmoid.configuration.contentPadding + protection
    readonly property int contentHeight: safeMargin * 2 + innerPad * 2 + 34 + drives.count * rowH
    readonly property int wantedHeight: Math.min(Plasmoid.configuration.maxHeight, Math.max(220, contentHeight))
    property bool scanRunning: false
    property bool scanPending: false
    property string mountSignature: ""

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
        if (v === "ntfs3" || v === "ntfs") return "NTFS"
        if (v === "ext4") return "EXT4"
        return v.toUpperCase()
    }
    function formatBytes(number) {
        var n = Number(number) || 0
        var units = ru ? ["Б", "КиБ", "МиБ", "ГиБ", "ТиБ"] : ["B", "KiB", "MiB", "GiB", "TiB"]
        var i = 0
        while (n >= 1024 && i < units.length - 1) { n /= 1024; ++i }
        return Qt.locale(ru ? "ru_RU" : "en_US").toString(n, "f", i < 3 ? 0 : 1) + " " + units[i]
    }
    function fileUrl(path) {
        return "file://" + String(path).split("/").map(function(part) { return encodeURIComponent(part) }).join("/")
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
        var blocks = []
        flatten(lsblkData.blockdevices || [], blocks)
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
    }
    function fullRefresh() {
        if (scanRunning) { scanPending = true; return }
        scanRunning = true
        executable.connectSource(scanCommand)
    }
    function discover() {
        if (!scanRunning) executable.connectSource(discoverCommand)
    }

    readonly property string scanCommand: "/bin/sh -c \"LC_ALL=C findmnt --json --real --bytes -o SOURCE,TARGET,FSTYPE,LABEL,SIZE,AVAIL,USE%; printf '\\n__DC_LSBLK__\\n'; LC_ALL=C lsblk --json --bytes -o NAME,PATH,PKNAME,TYPE,TRAN,MODEL\""
    readonly property string discoverCommand: "/bin/sh -c \"LC_ALL=C findmnt -rn --real -o SOURCE,TARGET | sort\""

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Layout.minimumWidth: 360
    Layout.preferredWidth: 470
    Layout.minimumHeight: 220
    Layout.preferredHeight: Plasmoid.configuration.autoFit ? wantedHeight : 420

    ListModel { id: drives }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        onNewData: function(sourceName, data) {
            disconnectSource(sourceName)
            var output = data["stdout"] || ""
            if (sourceName === root.scanCommand) {
                root.scanRunning = false
                if (output.length) root.rebuild(output)
                if (root.scanPending) {
                    root.scanPending = false
                    refreshDelay.restart()
                }
            } else if (sourceName === root.discoverCommand) {
                var signature = output.trim()
                if (root.mountSignature !== signature) {
                    root.mountSignature = signature
                    root.fullRefresh()
                }
            }
        }
    }
    Timer { id: refreshDelay; interval: 200; repeat: false; onTriggered: root.fullRefresh() }
    Timer {
        interval: Math.max(5, Plasmoid.configuration.discoveryInterval) * 1000
        repeat: true; running: true; triggeredOnStart: true
        onTriggered: root.discover()
    }
    Timer {
        interval: Math.max(15, Plasmoid.configuration.updateInterval) * 1000
        repeat: true; running: true
        onTriggered: root.fullRefresh()
    }
    Connections {
        target: Plasmoid.configuration
        function onShowRootChanged() { root.fullRefresh() }
        function onShowBootChanged() { root.fullRefresh() }
    }
    Component.onCompleted: root.fullRefresh()

    fullRepresentation: Item {
        id: view
        implicitWidth: 470
        implicitHeight: root.wantedHeight
        Layout.minimumWidth: 360
        Layout.preferredWidth: 470
        Layout.minimumHeight: 220
        Layout.preferredHeight: Plasmoid.configuration.autoFit ? root.wantedHeight : 420

        Canvas {
            id: background
            anchors.fill: parent
            anchors.margins: root.safeMargin
            renderStrategy: Canvas.Cooperative
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d")
                var w = width
                var h = height
                ctx.globalCompositeOperation = "source-over"
                ctx.globalAlpha = 1.0
                ctx.clearRect(0, 0, w, h)
                if (w <= 0 || h <= 0) return
                var opacity = Plasmoid.configuration.backgroundOpacity / 100
                var edge = opacity * (1 - Plasmoid.configuration.edgeOpacity / 100)
                var fade = Math.max(0, Math.min(Plasmoid.configuration.edgeWidth, Math.min(w, h) / 2))
                var radius = Plasmoid.configuration.rounded ? Math.min(Plasmoid.configuration.cornerRadius, w / 2, h / 2) : 0
                var c = Kirigami.Theme.backgroundColor
                function rgba(a) { return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")" }
                function roundedRect(x, y, rw, rh, r) {
                    ctx.beginPath()
                    ctx.moveTo(x + r, y)
                    ctx.lineTo(x + rw - r, y)
                    ctx.quadraticCurveTo(x + rw, y, x + rw, y + r)
                    ctx.lineTo(x + rw, y + rh - r)
                    ctx.quadraticCurveTo(x + rw, y + rh, x + rw - r, y + rh)
                    ctx.lineTo(x + r, y + rh)
                    ctx.quadraticCurveTo(x, y + rh, x, y + rh - r)
                    ctx.lineTo(x, y + r)
                    ctx.quadraticCurveTo(x, y, x + r, y)
                    ctx.closePath()
                }
                roundedRect(0, 0, w, h, radius)
                ctx.fillStyle = rgba(opacity)
                ctx.fill()
                if (fade <= 0 || edge >= opacity) return
                var curve = Math.max(-100, Math.min(100, Plasmoid.configuration.edgeCurve))
                var exponent = Math.pow(4, -curve / 100)
                var edgeRatio = opacity > 0 ? edge / opacity : 0
                function maskAlpha(t) {
                    var smooth = t * t * (3 - 2 * t)
                    return edgeRatio + (1 - edgeRatio) * Math.pow(smooth, exponent)
                }
                function addStops(gradient, length) {
                    var steps = 16
                    for (var i = 0; i <= steps; ++i) {
                        var t = i / steps
                        var position = Math.min(0.499, fade * t / length)
                        var alpha = maskAlpha(t)
                        gradient.addColorStop(position, "rgba(0,0,0," + alpha + ")")
                        gradient.addColorStop(1 - position, "rgba(0,0,0," + alpha + ")")
                    }
                }
                ctx.globalCompositeOperation = "destination-in"
                var gx = ctx.createLinearGradient(0, 0, w, 0)
                addStops(gx, w)
                ctx.fillStyle = gx
                ctx.fillRect(0, 0, w, h)
                var gy = ctx.createLinearGradient(0, 0, 0, h)
                addStops(gy, h)
                ctx.fillStyle = gy
                ctx.fillRect(0, 0, w, h)
                ctx.globalCompositeOperation = "source-over"
            }
            onWidthChanged: paintDelay.restart()
            onHeightChanged: paintDelay.restart()
            Connections {
                target: Plasmoid.configuration
                function onBackgroundOpacityChanged() { paintDelay.restart() }
                function onRoundedChanged() { paintDelay.restart() }
                function onCornerRadiusChanged() { paintDelay.restart() }
                function onEdgeOpacityChanged() { paintDelay.restart() }
                function onEdgeWidthChanged() { paintDelay.restart() }
                function onEdgeCurveChanged() { paintDelay.restart() }
                function onOuterMarginChanged() { paintDelay.restart() }
            }
            Timer { id: paintDelay; interval: 24; repeat: false; onTriggered: background.requestPaint() }
            Component.onCompleted: requestPaint()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.safeMargin + root.innerPad
            spacing: 4
            opacity: Plasmoid.configuration.textOpacity / 100

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
                QQC2.ScrollBar.vertical: QQC2.ScrollBar { policy: list.contentHeight > list.height ? QQC2.ScrollBar.AsNeeded : QQC2.ScrollBar.AlwaysOff }
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
                    TapHandler { onTapped: Qt.openUrlExternally(root.fileUrl(target)) }
                    QQC2.ToolTip.visible: hover.hovered
                    QQC2.ToolTip.text: source + "\n" + target

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 2
                        anchors.rightMargin: 6
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
