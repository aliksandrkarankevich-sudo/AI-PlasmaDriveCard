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

    property real totalBytes: 0
    property real availableBytes: 0
    property int usedPercent: 0
    property string status: "loading"
    property string errorText: ""
    property bool requestActive: false
    property bool refreshPending: false

    readonly property string mountPath: String(Plasmoid.configuration.mountPath || "").trim()
    readonly property string displayName: String(Plasmoid.configuration.displayName || "").trim() || mountPath || i18n("Drive Card")
    readonly property bool ready: status === "ready"
    readonly property int warningAt: Math.max(1, Math.min(99, Number(Plasmoid.configuration.warningPercent || 85)))
    readonly property int criticalAt: Math.max(warningAt + 1, Math.min(100, Number(Plasmoid.configuration.criticalPercent || 95)))
    readonly property color valueColor: {
        if (!ready)
            return Kirigami.Theme.disabledTextColor
        if (usedPercent >= criticalAt)
            return Kirigami.Theme.negativeTextColor
        if (usedPercent >= warningAt)
            return Kirigami.Theme.neutralTextColor
        return Kirigami.Theme.textColor
    }

    Plasmoid.title: displayName
    Plasmoid.icon: String(Plasmoid.configuration.iconName || "") || "drive-harddisk"
    Plasmoid.backgroundHints: PlasmaCore.Types.TranslucentBackground | PlasmaCore.Types.ConfigurableBackground
    Plasmoid.configurationRequired: !isValidPath(mountPath)
    Plasmoid.busy: requestActive && status === "loading"

    preferredRepresentation: fullRepresentation
    switchWidth: Kirigami.Units.gridUnit * 12
    switchHeight: Kirigami.Units.gridUnit * 6
    toolTipMainText: displayName
    toolTipSubText: ready
        ? i18n("%1 free of %2\n%3", formatBytes(availableBytes), formatBytes(totalBytes), mountPath)
        : (errorText || i18n("Waiting for disk information"))

    function isValidPath(path) {
        return path.length > 0 && path.startsWith("/") && path.indexOf("\n") < 0 && path.indexOf("\r") < 0
    }

    function posixQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'"
    }

    function buildCommand(path) {
        const quoted = posixQuote(path)
        return "p=" + quoted
            + "; if [ \"$p\" = / ] || findmnt -rn -M \"$p\" >/dev/null 2>&1; then "
            + "LC_ALL=C df -B1 --output=size,avail,pcent -- \"$p\"; "
            + "else printf '__DC_UNMOUNTED__\\n'; fi"
    }

    function refresh() {
        if (!isValidPath(mountPath)) {
            status = "error"
            errorText = i18n("Specify an absolute mount point in the widget settings")
            return
        }
        if (requestActive) {
            refreshPending = true
            return
        }
        requestActive = true
        if (status !== "ready")
            status = "loading"
        source.connectSource(buildCommand(mountPath))
    }

    function parseOutput(data) {
        const stdout = String(data["stdout"] || "").trim()
        if (stdout === "__DC_UNMOUNTED__") {
            status = "unmounted"
            errorText = i18n("The disk is not mounted")
            return
        }
        if (Number(data["exit code"]) !== 0) {
            status = "error"
            errorText = String(data["stderr"] || i18n("Unable to read disk information")).trim()
            return
        }
        const lines = stdout.split(/\r?\n/)
        const match = lines.length > 1 ? lines[lines.length - 1].trim().match(/^(\d+)\s+(\d+)\s+(\d+)%$/) : null
        if (!match || Number(match[1]) <= 0) {
            status = "error"
            errorText = i18n("Unexpected response from df")
            return
        }
        totalBytes = Number(match[1])
        availableBytes = Number(match[2])
        usedPercent = Math.max(0, Math.min(100, Number(match[3])))
        status = "ready"
        errorText = ""
    }

    function finishRequest() {
        requestActive = false
        if (refreshPending) {
            refreshPending = false
            Qt.callLater(refresh)
        }
    }

    function formatBytes(bytes) {
        const units = [i18n("B"), i18n("KiB"), i18n("MiB"), i18n("GiB"), i18n("TiB")]
        let value = Math.max(0, Number(bytes))
        let index = 0
        while (value >= 1024 && index < units.length - 1) {
            value /= 1024
            index += 1
        }
        return Qt.locale().toString(value, "f", index === 0 ? 0 : 1) + " " + units[index]
    }

    function fileUrlFor(path) {
        return "file://" + path.split("/").map(encodeURIComponent).join("/")
    }

    function openDisk() {
        if (ready)
            Qt.openUrlExternally(fileUrlFor(mountPath))
    }

    Plasma5Support.DataSource {
        id: source
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            root.parseOutput(data)
            disconnectSource(sourceName)
            root.finishRequest()
        }
    }

    Timer {
        interval: Math.max(10, Number(Plasmoid.configuration.updateInterval || 60)) * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    onMountPathChanged: Qt.callLater(root.refresh)
    Component.onCompleted: Qt.callLater(root.refresh)

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh")
            icon.name: "view-refresh"
            enabled: !root.requestActive
            onTriggered: root.refresh()
        },
        PlasmaCore.Action {
            text: i18n("Open disk")
            icon.name: "document-open-folder"
            enabled: root.ready
            onTriggered: root.openDisk()
        }
    ]

    compactRepresentation: MouseArea {
        id: compactRoot
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        onClicked: root.openDisk()

        Kirigami.Icon {
            anchors.fill: parent
            source: Plasmoid.icon
            active: compactRoot.containsMouse
            opacity: root.ready ? 1 : 0.55
        }
        QQC2.Label {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            visible: root.ready
            text: root.usedPercent + "%"
            font.pixelSize: Math.max(8, Math.round(parent.height * 0.28))
            color: root.valueColor
        }
        QQC2.ToolTip.visible: compactRoot.containsMouse
        QQC2.ToolTip.text: root.toolTipSubText
    }

    fullRepresentation: Item {
        id: fullRoot
        Layout.minimumWidth: Kirigami.Units.gridUnit * 14
        Layout.minimumHeight: Kirigami.Units.gridUnit * 5
        Layout.preferredWidth: Kirigami.Units.gridUnit * 18
        Layout.preferredHeight: Kirigami.Units.gridUnit * 6
        implicitWidth: Layout.preferredWidth
        implicitHeight: Layout.preferredHeight

        HoverHandler { id: hoverHandler }
        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: root.openDisk()
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.largeSpacing

            Kirigami.Icon {
                source: Plasmoid.icon
                Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                opacity: root.ready ? 1 : 0.55
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    Layout.fillWidth: true
                    text: root.displayName
                    font.bold: true
                    elide: Text.ElideRight
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    color: root.valueColor
                    elide: Text.ElideRight
                    text: {
                        if (root.status === "ready")
                            return i18n("%1 free of %2", root.formatBytes(root.availableBytes), root.formatBytes(root.totalBytes))
                        if (root.status === "loading")
                            return i18n("Reading disk…")
                        return root.errorText
                    }
                }
                QQC2.ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: root.ready ? root.usedPercent : 0
                    indeterminate: root.status === "loading"
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    visible: root.ready
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    color: root.valueColor
                    text: i18n("%1% used", root.usedPercent)
                }
            }
        }

        QQC2.ToolTip.visible: hoverHandler.hovered
        QQC2.ToolTip.text: root.ready ? i18n("Click to open %1", root.mountPath) : (root.errorText || "")
    }
}
