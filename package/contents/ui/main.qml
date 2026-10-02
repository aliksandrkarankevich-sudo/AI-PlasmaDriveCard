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

   readonly property bool ru:      Plasmoid.configuration.language !== "en"
   readonly property int  pad:     Plasmoid.configuration.contentPadding
   readonly property int  sepH:    Plasmoid.configuration.separatorHeight
   readonly property int  rowPadV: Math.max(4, Plasmoid.configuration.rowPaddingV)
   readonly property int  maxH:    Plasmoid.configuration.maxHeight
   readonly property int  minH:    Kirigami.Units.gridUnit * 9
   readonly property int  headerH: Kirigami.Units.gridUnit * 2
   readonly property int  rowGapV: Kirigami.Units.smallSpacing
   readonly property int  progressH: Math.max(2, Plasmoid.configuration.progressHeight)
   readonly property int  groupH:
       Math.max(Kirigami.Units.iconSizes.smallMedium,
                Math.ceil(fontPx(15) * 1.4)) + rowGapV * 2
   readonly property int estimatedRowH:
       rowPadV * 2
       + fontPx(18) + fontPx(16) + fontPx(13)
       + fontPx(13) + progressH
       + rowGapV * 4
   property int measuredRowH: 0
   readonly property int effectiveRowH: measuredRowH > 0 ? measuredRowH : estimatedRowH
   property int measuredHeaderH: 0
   readonly property int effectiveHeaderH: Math.max(headerH, measuredHeaderH)
   property int rowCount:   0
   property int groupCount: 0
   readonly property int wantedHeight: Math.max(minH,
       Math.min(maxH,
           pad * 2 + effectiveHeaderH + rowGapV
           + Math.max(1, rowCount) * effectiveRowH
           + groupCount * groupH
           + Math.max(0, drives.count - 1) * sepH))

   onWantedHeightChanged: Qt.callLater(function() {
       if (Plasmoid.configuration.autoFit && root.wantedHeight > 0)
           root.height = root.wantedHeight
   })

   property bool scanRunning:     false
   property bool activityRunning: false
   property bool pendingRefresh:  false
   property var  previousIo:      ({})
   property real _lastScanMs:     0

   function tr2(r, e) { return ru ? r : e }
   function fontPx(base) {
       return Math.max(8, Math.round(base * Plasmoid.configuration.textScale / 100.0))
   }
   function openTarget(target) {
       if (!target) return
       var url = target.endsWith("/") ? target : target + "/"
       Qt.openUrlExternally("file://" + encodeURI(url))
   }
   function diskIcon(kind) {
       if (kind === "raid") return "drive-multidisk"
       if (kind === "usb")  return "drive-removable-media-usb"
       if (kind === "ssd")  return "drive-harddisk-solidstate"
       return "drive-harddisk"
   }
   function displayIcon(target, kind) {
       var st = Plasmoid.configuration.iconStyle
       if (st === "folder")           return "folder"
       if (st === "folder-open")      return "folder-open"
       if (st === "folder-documents") return "folder-documents"
       if (st === "computer")         return "computer"
       if (st === "custom") {
           var p = Plasmoid.configuration.customIconPath
           if (p) return p.indexOf("/") === 0 ? "file://" + p : p
       }
       if (target === "/" && kind !== "raid") return "drive-harddisk-root"
       return diskIcon(kind)
   }
   function basename(path) {
       var p = (path || "").replace(/\/$/, "")
       return decodeURIComponent(p.substring(p.lastIndexOf("/") + 1)) || p
   }
   function cleanSource(source) { return (source || "").replace(/\[.*\]$/, "") }
   function prettyFs(value) {
       var v = (value || "").toLowerCase()
       if (v === "btrfs") return "Btrfs"
       if (v === "vfat")  return "FAT"
       if (v === "exfat") return "exFAT"
       return v.toUpperCase()
   }
   function formatBytes(number) {
       var n = Number(number) || 0
       var units = ru
           ? ["Б", "КиБ", "МиБ", "ГиБ", "ТиБ"]
           : ["B", "KiB", "MiB", "GiB", "TiB"]
       var i = 0
       while (n >= 1024 && i < units.length - 1) { n /= 1024; ++i }
       return Qt.locale(ru ? "ru_RU" : "en_US").toString(n, "f", i < 3 ? 0 : 1) + " " + units[i]
   }
   function flatten(items, output) {
       for (var i = 0; i < (items || []).length; ++i) {
           output.push(items[i])
           if (items[i].children) flatten(items[i].children, output)
       }
   }

   // ---- физические диски и RAID ----------------------------------------
   function isRota(v) { return v === true || v === 1 || v === "1" || v === "true" }

   function buildInfo(blocks) {
       var info = ({})
       function walk(list, diskName, parentName) {
           for (var i = 0; i < (list || []).length; ++i) {
               var n = list[i]
               var e = info[n.name]
               if (!e) { e = { node: n, disks: [], parent: parentName }; info[n.name] = e }
               var d = (n.type === "disk") ? n.name : diskName
               if (d && e.disks.indexOf(d) < 0) e.disks.push(d)
               walk(n.children, d, n.name)
           }
       }
       walk(blocks, "", "")
       return info
   }
   function groupOf(info, name) {
       var e = info[name]
       var guard = 0
       while (e && guard++ < 16) {
           var t = e.node.type || ""
           if (t === "disk")
               return { key: "disk:" + e.node.name, raid: false, entry: e }
           if (t.indexOf("raid") === 0 || t === "md")
               return { key: "raid:" + e.node.name, raid: true, entry: e }
           e = info[e.parent]
       }
       return null
   }
   function diskKind(n) {
       var tran = (n.tran || "").toLowerCase()
       if (tran === "usb")  return "usb"
       if (tran === "nvme" || !isRota(n.rota)) return "ssd"
       return "hdd"
   }
   function diskTypeLabel(n) {
       var tran = (n.tran || "").toLowerCase()
       if (tran === "nvme") return "NVMe"
       if (tran === "usb")  return "USB"
       if (!tran && /^(vd|xvd)/.test(n.name || ""))
           return tr2("Виртуальный", "Virtual")
       return isRota(n.rota) ? "HDD" : "SSD"
   }
   function makeGroup(g) {
       var n = g.entry.node
       if (!g) return { key: "other", kind: "hdd", title: tr2("Прочее", "Other"),
                        sub: "", rows: [], hasRoot: false }
       if (g.raid) {
           var t = n.type || ""
           var level = t.indexOf("raid") === 0 ? "RAID " + t.substring(4) : "RAID"
           var members = g.entry.disks.join(" + ")
           return { key: g.key, kind: "raid",
                    title: level + "  " + n.name,
                    sub: formatBytes(n.size) + (members ? "  •  " + members : ""),
                    rows: [], hasRoot: false }
       }
       var model = (n.model || "").replace(/\s+/g, " ").trim()
       return { key: g.key, kind: diskKind(n),
                title: model || n.name,
                sub: formatBytes(n.size) + "  •  " + diskTypeLabel(n) + "  •  " + n.name,
                rows: [], hasRoot: false }
   }
   function blankRow() {
       return { title: "", target: "", source: "", fs: "", physical: "",
                total: 0, available: 0, used: 0, driveIcon: "", kname: "",
                active: false, isHeader: false, groupSub: "", kind: "" }
   }

   function rebuild(output) {
       var marker      = "__DC_LSBLK__"
       var markerIndex = output.indexOf(marker)
       if (markerIndex < 0) return
       var findmntData, lsblkData
       try {
           findmntData = JSON.parse(output.substring(0, markerIndex).trim())
           lsblkData   = JSON.parse(output.substring(markerIndex + marker.length).trim())
       } catch (error) {
           console.warn("DriveCard JSON:", error)
           return
       }
       var info   = buildInfo(lsblkData.blockdevices || [])
       var all    = []
       var groups = ({})
       var seen   = ({})
       flatten(findmntData.filesystems || [], all)
       for (var j = 0; j < all.length; ++j) {
           var fs     = all[j]
           var target = fs.target || ""
           var source = cleanSource(fs.source)
           if (!target || source.indexOf("/dev/") !== 0) continue
           if (!Plasmoid.configuration.showRoot && target === "/") continue
           if (!Plasmoid.configuration.showBoot &&
               (target === "/boot" || target === "/boot/efi")) continue
           if (seen[source]) continue
           var size      = Number(fs.size)  || 0
           var available = Number(fs.avail) || 0
           var used      = parseInt(String(fs["use%"] || "0")) || 0
           var label     = fs.label || ""
           if (target === "/") label = tr2("Система", "System")
           else if (!label)    label = basename(target)

           var found = groupOf(info, source.substring(source.lastIndexOf("/") + 1))
           var gkey  = found ? found.key : "other"
           if (!groups[gkey]) groups[gkey] = makeGroup(found)
           var grp = groups[gkey]
           if (target === "/") grp.hasRoot = true

           var row = blankRow()
           row.title = label; row.target = target; row.source = source
           row.fs = prettyFs(fs.fstype); row.physical = grp.title
           row.total = size; row.available = available; row.used = used
           row.kind = grp.kind
           row.driveIcon = displayIcon(target, grp.kind)
           row.kname = basename(source)
           grp.rows.push(row)
           seen[source] = true
       }

       var list = []
       for (var key in groups) list.push(groups[key])
       list.sort(function(a, b) {
           if (a.hasRoot !== b.hasRoot) return a.hasRoot ? -1 : 1
           if (a.key === "other") return 1
           if (b.key === "other") return -1
           return a.title.localeCompare(b.title)
       })

       drives.clear()
       previousIo = ({})
       var rowsTotal = 0
       for (var gi = 0; gi < list.length; ++gi) {
           var g = list[gi]
           g.rows.sort(function(a, b) {
               if (a.target === "/") return -1
               if (b.target === "/") return  1
               return a.title.localeCompare(b.title)
           })
           var head = blankRow()
           head.isHeader = true
           head.title = g.title; head.groupSub = g.sub
           head.kind = g.kind; head.driveIcon = diskIcon(g.kind)
           drives.append(head)
           for (var k = 0; k < g.rows.length; ++k) drives.append(g.rows[k])
           rowsTotal += g.rows.length
       }
       rowCount   = rowsTotal
       groupCount = list.length
       _lastScanMs = Date.now()
   }
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
       var lines   = output.split("\n")
       for (var i = 0; i < lines.length; ++i) {
           var parts = lines[i].trim().split(/\s+/)
           if (parts.length >= 11)
               current[parts[2]] = String(parts[3]) + ":" + String(parts[7])
       }
       for (var j = 0; j < drives.count; ++j) {
           var row = drives.get(j)
           if (row.isHeader) continue
           var now    = current[row.kname]
           var before = previousIo[row.kname]
           drives.setProperty(j, "active",
               now !== undefined && before !== undefined && now !== before)
       }
       previousIo = current
   }
   function refreshIcons() {
       for (var i = 0; i < drives.count; ++i) {
           var row = drives.get(i)
           if (row.isHeader) continue
           drives.setProperty(i, "driveIcon", displayIcon(row.target, row.kind))
       }
   }
   function scheduleStorageRefresh() {
       refresh(400)
   }

   readonly property string scanCommand: "/bin/sh -c \"" + scanScript + "\""
   readonly property string scanScript:
       "LC_ALL=C findmnt --json --real --bytes -o SOURCE,TARGET,FSTYPE,LABEL,SIZE,AVAIL,USE%; "
       + "printf '\\n__DC_LSBLK__\\n'; "
       + "LC_ALL=C lsblk --json --bytes -o NAME,PATH,PKNAME,TYPE,TRAN,MODEL,SIZE,ROTA"
   readonly property string activityCommand: "/bin/cat /proc/diskstats"

   Layout.minimumWidth:    Kirigami.Units.gridUnit * 22
   Layout.preferredWidth:  Kirigami.Units.gridUnit * 29
   Layout.minimumHeight:   Plasmoid.configuration.autoFit ? wantedHeight : minH
   Layout.preferredHeight: Plasmoid.configuration.autoFit ? wantedHeight : minH
   Layout.maximumHeight:   Plasmoid.configuration.autoFit ? wantedHeight : 16777215

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
               if (root.pendingRefresh) {
                   root.pendingRefresh = false
                   root.refresh(0)
               }
           } else if (sourceName === root.activityCommand) {
               disconnectSource(sourceName)
               root.activityRunning = false
               root.applyActivity(data["stdout"] || "")
           }
       }
   }

   Timer {
       id: delayedRefresh
       interval: 400
       repeat: false
       onTriggered: root.refresh(0)
   }
   Timer {
       interval:  Math.max(15, Plasmoid.configuration.updateInterval) * 1000
       repeat:    true
       running:   true
       onTriggered: root.refresh(0)
   }
   Timer {
       interval:         Math.max(1, Plasmoid.configuration.activityInterval) * 1000
       repeat:           true
       running:          Plasmoid.configuration.showActivity
       triggeredOnStart: true
       onTriggered: root.refreshActivity()
   }
   // Детектор подключения/отключения устройств (в т.ч. сборка RAID):
   // опрашивает /proc/partitions и пересканирует диски при изменении.
   Timer {
       id: hotplugPoller
       interval: 5000
       repeat:   true
       running:  true
       property int _lastCount: -1
       onTriggered: hotplugExec.connectSource("cat /proc/partitions")
   }
   Plasma5Support.DataSource {
       id: hotplugExec
       engine: "executable"
       onNewData: function(sourceName, data) {
           disconnectSource(sourceName)
           var lines = (data["stdout"] || "").split("\n").filter(function(l) {
               return l.trim().length > 0
           }).length
           if (hotplugPoller._lastCount >= 0 && lines !== hotplugPoller._lastCount)
               root.scheduleStorageRefresh()
           hotplugPoller._lastCount = lines
       }
   }

   Connections {
       target: Plasmoid.configuration
       function onShowRootChanged()        { root.refresh(0) }
       function onShowBootChanged()        { root.refresh(0) }
       function onIconStyleChanged()       { root.refreshIcons() }
       function onCustomIconPathChanged()  { root.refreshIcons() }
       function onLanguageChanged()        { root.scheduleStorageRefresh() }
       function onTextScaleChanged()       { root.scheduleStorageRefresh() }
       function onRowPaddingVChanged()     { root.scheduleStorageRefresh() }
       function onSeparatorHeightChanged() { root.scheduleStorageRefresh() }
       function onProgressHeightChanged()  { root.scheduleStorageRefresh() }
       function onMaxHeightChanged()       { root.scheduleStorageRefresh() }
       function onAutoFitChanged()         { root.scheduleStorageRefresh() }
   }

   Component.onCompleted: Qt.callLater(function() { root.refresh(0) })

   fullRepresentation: Item {
       id: view

       implicitWidth:  Kirigami.Units.gridUnit * 29
       implicitHeight: root.wantedHeight

       Layout.minimumWidth:    Kirigami.Units.gridUnit * 22
       Layout.preferredWidth:  Kirigami.Units.gridUnit * 29
       Layout.minimumHeight:   Plasmoid.configuration.autoFit ? root.wantedHeight : root.minH
       Layout.preferredHeight: Plasmoid.configuration.autoFit ? root.wantedHeight : root.minH
       Layout.maximumHeight:   Plasmoid.configuration.autoFit ? root.wantedHeight : 16777215

       readonly property color backgroundBase:
           Plasmoid.configuration.backgroundColorMode === "custom"
               ? Plasmoid.configuration.backgroundColor
               : Kirigami.Theme.backgroundColor
       readonly property color textBase:
           Plasmoid.configuration.textColorMode === "custom"
               ? Plasmoid.configuration.textColor
               : Kirigami.Theme.textColor
       readonly property color labelColor: Qt.rgba(
           textBase.r, textBase.g, textBase.b,
           Plasmoid.configuration.textOpacity / 100.0)

       EdgeFadeBackground {
           anchors.fill: parent
           baseColor:    view.backgroundBase
           centerAlpha:  Plasmoid.configuration.backgroundOpacity / 100.0
           edgeAlpha:    Plasmoid.configuration.edgeOpacity / 100.0
           fadeWidth:    Plasmoid.configuration.edgeWidth
           curve:        Plasmoid.configuration.edgeCurve / 100.0
           radius:       Plasmoid.configuration.rounded
                             ? Plasmoid.configuration.cornerRadius : 0
       }

       Rectangle {
           id: suspendedOverlay
           anchors.fill: parent
           visible: false
           color:   Qt.rgba(0, 0, 0, 0.55)
           radius:  Plasmoid.configuration.rounded
                        ? Plasmoid.configuration.cornerRadius : 0
           z: 99
           Column {
               anchors.centerIn: parent
               spacing: Kirigami.Units.smallSpacing
               Kirigami.Icon {
                   source: "dialog-warning"
                   width:  Kirigami.Units.iconSizes.large
                   height: Kirigami.Units.iconSizes.large
                   anchors.horizontalCenter: parent.horizontalCenter
               }
               PC3.Label {
                   text: root.tr2(
                       "Виджет приостановлен\nПовтор через 30 с",
                       "Widget suspended\nRetrying in 30 s")
                   color: "white"
                   horizontalAlignment: Text.AlignHCenter
                   font.pixelSize: root.fontPx(14)
               }
           }
       }

       ColumnLayout {
           id: layout
           anchors.fill: parent
           anchors.margins: root.pad
           spacing: Kirigami.Units.smallSpacing

           RowLayout {
               id: header

               Binding {
                   target: root
                   property: "measuredHeaderH"
                   value: Math.ceil(Math.max(
                       root.headerH,
                       header.implicitHeight,
                       header.Layout.minimumHeight))
               }
               Layout.fillWidth:       true
               Layout.preferredHeight: root.headerH
               Kirigami.Icon {
                   source: "drive-harddisk"
                   Layout.preferredWidth:  Kirigami.Units.iconSizes.smallMedium
                   Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
               }
               PC3.Label {
                   text:             root.tr2("Диски", "Drives")
                   color:            view.labelColor
                   font.bold:        true
                   font.pixelSize:   root.fontPx(20)
                   Layout.fillWidth: true
               }
               PC3.Label {
                   text:           root.rowCount
                   color:          view.labelColor
                   opacity:        0.72
                   font.pixelSize: root.fontPx(13)
               }
           }

           ListView {
               id: list
               Layout.fillWidth: true
               Layout.fillHeight: true
               clip: true
               model: drives
               spacing: root.sepH
               boundsBehavior: Flickable.StopAtBounds

               QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                   policy: list.contentHeight > list.height
                       ? QQC2.ScrollBar.AsNeeded
                       : QQC2.ScrollBar.AlwaysOff
               }

               delegate: Item {
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
                   required property bool   isHeader
                   required property string groupSub
                   required property string kind
                   required property int    index

                   function measureRow() {
                       if (!isHeader && row.implicitHeight > 0)
                           root.measuredRowH = Math.ceil(row.implicitHeight)
                   }

                   Component.onCompleted: Qt.callLater(measureRow)

                   Connections {
                       target: row
                       function onImplicitHeightChanged() {
                           Qt.callLater(measureRow)
                       }
                   }

                   width:          list.width
                   implicitHeight: isHeader ? root.groupH : Math.ceil(row.implicitHeight)
                   height:         implicitHeight

                   Rectangle {
                       anchors.fill: parent
                       visible: !isHeader
                       color: hoverArea.containsMouse
                           ? Qt.rgba(
                               Kirigami.Theme.highlightColor.r,
                               Kirigami.Theme.highlightColor.g,
                               Kirigami.Theme.highlightColor.b, 0.12)
                           : "transparent"
                       radius: Plasmoid.configuration.rounded
                           ? Math.max(2, Plasmoid.configuration.cornerRadius - root.pad) : 0
                       Behavior on color { ColorAnimation { duration: 120 } }
                   }

                   QQC2.ToolTip.visible: hoverArea.containsMouse && !isHeader
                   QQC2.ToolTip.text:   source + "\n" + target + "\n" + physical
                   QQC2.ToolTip.delay:  600

                   MouseArea {
                       id: hoverArea
                       anchors.fill: parent
                       enabled: !isHeader
                       hoverEnabled: true
                       onClicked: root.openTarget(target)
                   }

                   RowLayout {
                       id: groupRow
                       anchors.fill: parent
                       anchors.leftMargin: Kirigami.Units.smallSpacing
                       anchors.rightMargin: Kirigami.Units.largeSpacing
                       spacing: Kirigami.Units.smallSpacing
                       visible: isHeader

                       Kirigami.Icon {
                           source: driveIcon
                           Layout.preferredWidth:  Kirigami.Units.iconSizes.smallMedium
                           Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                           Layout.alignment: Qt.AlignVCenter
                       }
                       PC3.Label {
                           text:             title
                           color:            view.labelColor
                           font.bold:        true
                           font.pixelSize:   root.fontPx(15)
                           elide:            Text.ElideRight
                           Layout.fillWidth: true
                           Layout.alignment: Qt.AlignVCenter
                       }
                       PC3.Label {
                           text:             groupSub
                           color:            view.labelColor
                           opacity:          0.72
                           font.pixelSize:   root.fontPx(12)
                           elide:            Text.ElideRight
                           Layout.maximumWidth: list.width * 0.6
                           Layout.alignment: Qt.AlignVCenter
                       }
                   }

                   RowLayout {
                       id: row
                       anchors.fill: parent
                       anchors.leftMargin: Kirigami.Units.smallSpacing + Kirigami.Units.largeSpacing
                       anchors.rightMargin: Kirigami.Units.largeSpacing
                       spacing: Kirigami.Units.largeSpacing
                       visible: !isHeader

                       Item {
                           Layout.preferredWidth:  Kirigami.Units.iconSizes.medium
                           Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                           Layout.alignment: Qt.AlignVCenter
                           Kirigami.Icon { anchors.fill: parent; source: driveIcon }
                           Rectangle {
                               visible: Plasmoid.configuration.showActivity && active
                               width:   Kirigami.Units.smallSpacing * 2
                               height:  Kirigami.Units.smallSpacing * 2
                               radius:  Kirigami.Units.smallSpacing
                               anchors.right: parent.right
                               anchors.bottom: parent.bottom
                               color: Kirigami.Theme.positiveTextColor
                               border.width: Math.max(1, Kirigami.Units.smallSpacing / 2)
                               border.color: Kirigami.Theme.backgroundColor
                           }
                       }

                       ColumnLayout {
                           Layout.fillWidth:    true
                           Layout.alignment:    Qt.AlignVCenter
                           Layout.topMargin:    root.rowPadV
                           Layout.bottomMargin: root.rowPadV
                           spacing: root.rowGapV

                           PC3.Label {
                               text:             title
                               color:            view.labelColor
                               font.bold:        true
                               font.pixelSize:   root.fontPx(18)
                               elide:            Text.ElideRight
                               Layout.fillWidth: true
                           }
                           PC3.Label {
                               text: root.formatBytes(available) + " "
                                   + root.tr2("свободно из", "free of") + " "
                                   + root.formatBytes(total)
                               color:            view.labelColor
                               font.pixelSize:   root.fontPx(16)
                               elide:            Text.ElideRight
                               Layout.fillWidth: true
                           }
                           PC3.Label {
                               visible: Plasmoid.configuration.showFs
                               text:    fs
                               color:            view.labelColor
                               opacity:          0.72
                               font.pixelSize:   root.fontPx(13)
                               elide:            Text.ElideRight
                               Layout.fillWidth: true
                           }

                           RowLayout {
                               Layout.fillWidth: true
                               spacing: Kirigami.Units.smallSpacing
                               Item { Layout.fillWidth: true }
                               PC3.Label {
                                   text:           used + "% " + root.tr2("занято", "used")
                                   color:          view.labelColor
                                   font.pixelSize: root.fontPx(13)
                               }
                           }

                           Item {
                               Layout.fillWidth:       true
                               Layout.preferredHeight: root.progressH

                               readonly property int   ph:    root.progressH
                               readonly property real  fillW: width * Math.max(0, Math.min(100, used)) / 100.0
                               readonly property color fillColor:
                                   used >= Plasmoid.configuration.criticalPercent
                                       ? Kirigami.Theme.negativeTextColor
                                       : used >= Plasmoid.configuration.warningPercent
                                           ? Kirigami.Theme.neutralTextColor
                                           : Kirigami.Theme.highlightColor

                               Rectangle {
                                   anchors.left:           parent.left
                                   anchors.right:          parent.right
                                   anchors.verticalCenter: parent.verticalCenter
                                   height: parent.ph
                                   radius: parent.ph / 2
                                   color:  Qt.rgba(
                                       parent.fillColor.r,
                                       parent.fillColor.g,
                                       parent.fillColor.b, 0.20)
                               }
                               Rectangle {
                                   anchors.left:           parent.left
                                   anchors.verticalCenter: parent.verticalCenter
                                   width:  Math.max(parent.ph, parent.fillW)
                                   height: parent.ph
                                   radius: parent.ph / 2
                                   color:  parent.fillColor
                                   Behavior on width { SmoothedAnimation { velocity: 120 } }
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
                   color: view.labelColor
                   opacity: 0.75
                   font.pixelSize: root.fontPx(15)
               }
           }
       }
   }
}
