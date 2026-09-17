// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    property string state: "loading"
    property string errorText: ""
    property bool requestRunning: false
    property bool requestPending: false
    readonly property bool ru: Plasmoid.configuration.language === "ru"
    readonly property int rowHeight: 104
    readonly property int headerHeight: 38
    readonly property int preferredHeight: Math.max(128, headerHeight + disks.count * rowHeight + Kirigami.Units.largeSpacing * 2)

    Plasmoid.title: ru ? "Диски" : "Disks"
    Plasmoid.icon: "drive-harddisk"
    Plasmoid.backgroundHints: PlasmaCore.Types.TranslucentBackground | PlasmaCore.Types.ConfigurableBackground
    preferredRepresentation: fullRepresentation
    implicitWidth: 350
    implicitHeight: preferredHeight
    toolTipMainText: Plasmoid.title
    toolTipSubText: state === "ready"
        ? (ru ? "Смонтированных файловых систем: " : "Mounted filesystems: ") + disks.count
        : errorText

    ListModel { id: disks }

    function text(ruText, enText) { return ru ? ruText : enText }

    function formatBytes(bytes) {
        const names = ru ? ["Б", "КиБ", "МиБ", "ГиБ", "ТиБ", "ПиБ"]
                         : ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]
        let value = Number(bytes)
        let unit = 0
        while (value >= 1024 && unit < names.length - 1) {
            value /= 1024
            unit++
        }
        const decimals = unit >= 3 ? 1 : 0
        return Qt.locale(ru ? "ru_RU" : "en_US").toString(value, "f", decimals) + " " + names[unit]
    }

    function displayName(item) {
        if (item.label && String(item.label).trim().length)
            return String(item.label)
        if (item.target === "/")
            return text("Система", "System")
        if (item.target === "/home")
            return text("Домашний раздел", "Home")
        const parts = String(item.target).split("/")
        const last = parts[parts.length - 1]
        return last || String(item.source)
    }

    function iconFor(item) {
        const label = String(item.label || "").toLowerCase()
        if (label.indexOf("game") >= 0)
            return "folder-games"
        if (item.target === "/")
            return "drive-harddisk-root"
        if (String(item.fstype).indexOf("nfs") >= 0 || String(item.fstype).indexOf("cifs") >= 0)
            return "folder-network"
        return "drive-harddisk"
    }

    function fileUrl(path) {
        return "file://" + String(path).split("/").map(encodeURIComponent).join("/")
    }

    function shouldShow(item) {
        const target = String(item.target || "")
        if (!target || target[0] !== "/")
            return false
        if (!Plasmoid.configuration.showRoot && target === "/")
            return false
        if (!Plasmoid.configuration.showBoot && (target === "/boot" || target.indexOf("/boot/") === 0))
            return false
        return Number(item.size || 0) > 0
    }

    function parseResult(stdout) {
        let document
        try {
            document = JSON.parse(stdout)
        } catch (error) {
            state = "error"
            errorText = text("Не удалось разобрать ответ findmnt", "Unable to parse the findmnt response")
            return
        }

        const filesystems = document.filesystems || []
        const result = []
        const seen = {}
        for (let i = 0; i < filesystems.length; ++i) {
            const item = filesystems[i]
            if (!shouldShow(item))
                continue

            // One physical/logical filesystem can be mounted in several places.
            // Keep one card, preferring / and then the shortest mount path.
            const rawSource = String(item.source || "")
            const identity = rawSource.replace(/\[.*\]$/, "") || String(item.target)
            if (seen[identity] !== undefined) {
                const old = result[seen[identity]]
                if (old.target === "/" || String(old.target).length <= String(item.target).length)
                    continue
                result[seen[identity]] = item
                continue
            }
            seen[identity] = result.length
            result.push(item)
        }

        result.sort(function(a, b) {
            if (a.target === "/") return -1
            if (b.target === "/") return 1
            return displayName(a).localeCompare(displayName(b))
        })

        disks.clear()
        for (let j = 0; j < result.length; ++j) {
            const item = result[j]
            const percentText = String(item["use%"] || "0").replace("%", "")
            disks.append({
                sourcePath: String(item.source || ""),
                volumeLabel: String(item.label || ""),
                fileSystem: String(item.fstype || ""),
                totalBytes: Number(item.size || 0),
                availableBytes: Number(item.avail || 0),
                usedPercent: Math.max(0, Math.min(100, parseInt(percentText) || 0)),
                mountPath: String(item.target || ""),
                title: displayName(item),
                iconName: iconFor(item)
            })
        }

        state = "ready"
        errorText = disks.count ? "" : text("Доступные диски не найдены", "No accessible disks found")
    }

    function refresh() {
        if (requestRunning) {
            requestPending = true
            return
        }
        requestRunning = true
        if (!disks.count)
            state = "loading"
        command.connectSource("LC_ALL=C findmnt --kernel --real --list --bytes --json --output SOURCE,LABEL,FSTYPE,SIZE,AVAIL,USE%,TARGET")
    }

    function finishRequest() {
        requestRunning = false
        if (requestPending) {
            requestPending = false
            Qt.callLater(refresh)
        }
    }

    Plasma5Support.DataSource {
        id: command
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            const exitCode = Number(data["exit code"])
            if (exitCode === 0) {
                root.parseResult(String(data["stdout"] || ""))
            } else {
                root.state = "error"
                root.errorText = String(data["stderr"] || root.text("Ошибка запуска findmnt", "Unable to run findmnt")).trim()
            }
            disconnectSource(sourceName)
            root.finishRequest()
        }
    }

    Timer {
        interval: Math.max(10, Plasmoid.configuration.updateInterval) * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Connections {
        target: Plasmoid.configuration
        function onShowRootChanged() { root.refresh() }
        function onShowBootChanged() { root.refresh() }
    }

    Component.onCompleted: refresh()

    fullRepresentation: Item {
        implicitWidth: 350
        implicitHeight: root.preferredHeight

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.headerHeight

                Kirigami.Icon {
                    source: "drive-harddisk"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                }
                QQC2.Label {
                    text: root.text("Диски", "Disks")
                    font.bold: true
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.15
                }
                Item { Layout.fillWidth: true }
                QQC2.Label {
                    text: disks.count
                    color: Kirigami.Theme.disabledTextColor
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.state !== "ready" || disks.count === 0

                Column {
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: root.state === "error" ? "dialog-error" : "view-refresh"
                        width: Kirigami.Units.iconSizes.large
                        height: width
                    }
                    QQC2.Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.state === "loading"
                            ? root.text("Поиск дисков…", "Searching for disks…")
                            : root.errorText
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.state === "ready" && disks.count > 0
                model: disks
                clip: true
                spacing: 0

                delegate: Item {
                    id: card
                    required property string sourcePath
                    required property string volumeLabel
                    required property string fileSystem
                    required property real totalBytes
                    required property real availableBytes
                    required property int usedPercent
                    required property string mountPath
                    required property string title
                    required property string iconName
                    width: ListView.view.width
                    height: root.rowHeight

                    readonly property color statusColor: usedPercent >= Plasmoid.configuration.criticalPercent
                        ? Kirigami.Theme.negativeTextColor
                        : usedPercent >= Plasmoid.configuration.warningPercent
                            ? Kirigami.Theme.neutralTextColor
                            : Kirigami.Theme.textColor

                    Rectangle {
                        anchors.fill: parent
                        radius: Kirigami.Units.cornerRadius
                        color: mouse.containsMouse ? Kirigami.Theme.hoverColor : "transparent"
                        opacity: mouse.containsMouse ? 0.35 : 0
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Kirigami.Units.smallSpacing
                        anchors.rightMargin: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.largeSpacing

                        Kirigami.Icon {
                            source: card.iconName
                            Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                            Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            QQC2.Label {
                                Layout.fillWidth: true
                                text: card.title
                                font.bold: true
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
                                elide: Text.ElideRight
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                color: card.statusColor
                                text: root.ru
                                    ? root.formatBytes(card.availableBytes) + " свободно из " + root.formatBytes(card.totalBytes)
                                    : root.formatBytes(card.availableBytes) + " free of " + root.formatBytes(card.totalBytes)
                                elide: Text.ElideRight
                            }

                            QQC2.ProgressBar {
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: card.usedPercent
                            }

                            QQC2.Label {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                color: card.statusColor
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                text: root.ru ? card.usedPercent + "% занято" : card.usedPercent + "% used"
                            }
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(root.fileUrl(card.mountPath))
                    }

                    QQC2.ToolTip.visible: mouse.containsMouse
                    QQC2.ToolTip.text: root.ru
                        ? card.mountPath + "\n" + card.fileSystem + " · нажмите, чтобы открыть"
                        : card.mountPath + "\n" + card.fileSystem + " · click to open"
                }
            }
        }
    }
}
