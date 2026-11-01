import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// System info card of the overview dashboard
Rectangle {
    id: ncFetchWidgetItem
    visible: ncDashLayer.shown("fetch")
    x: ncDashLayer.rFetch.x
    y: ncDashLayer.rFetch.y
    Behavior on y { enabled: globalState.ncEditMode; M3SpringAnim { token: "spatialDefault" } }
    width: ncDashLayer.rFetch.width
    height: ncDashLayer.rFetch.height
    radius: 28
    clip: true
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)

    AutoShape {
        x: parent.width - width * 0.62
        y: parent.height - height * 0.62
        width: Math.min(parent.width, parent.height) * 0.9; height: width
        inset: 1.0
        seq: ["Cookie12Sided", "Flower", "Clover4Leaf", "Puffy", "Cookie7Sided"]
        interval: 5200
        spinStep: 24
        fill: ga(pal.primary, 0.06)
        running: ncFetchWidgetItem.visible && (globalState.notchControlOpen || globalState.islandControlOpen)
    }

    RowLayout {
        id: ncFetchHeader
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 14
        spacing: 10
        Item {
            width: 30; height: 30
            MShape { anchors.fill: parent; inset: 1.0; from: m3.accentShape; to: m3.accentShape; fill: ga(pal.primary, 0.18) }
            Text { anchors.centerIn: parent; text: distroIconGlyph(globalState.fetchOS); font.family: "Symbols Nerd Font"; font.pixelSize: 16; color: pal.primary }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text { Layout.fillWidth: true; text: globalState.fetchUser !== "" ? globalState.fetchUser : "—"; font.family: globalState.fontPrimary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.Bold; color: pal.colorOnSurface; elide: Text.ElideRight }
            Text { Layout.fillWidth: true; text: tr("system"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); color: pal.colorOnSurfVar; elide: Text.ElideRight }
        }
    }

    // Fetch module cards: side by side when wide, stacked when narrow
    GridLayout {
        id: ncFetchCards
        anchors.left: parent.left; anchors.right: parent.right
        anchors.top: ncFetchHeader.bottom; anchors.bottom: parent.bottom
        anchors.margins: 12; anchors.topMargin: 10
        columns: ncFetchWidgetItem.width >= 520 ? 3 : 1
        rowSpacing: 8; columnSpacing: 8
        // Captions only when each card has room for them on top of its 4 rows
        readonly property bool roomy: columns > 1 || (height - rowSpacing * 2) / 3 >= 100

        OverviewFetchGroup {
            icon: "\ue00f"; title: tr("sys_software"); accent: pal.primary
            showTitle: ncFetchCards.roomy
            rows: [
            { icon: "\ue00f", label: "OS",     value: globalState.fetchOS,     color: pal.primary },
            { icon: "\ue40d", label: "Kernel", value: globalState.fetchKernel, color: pal.accent },
            { icon: "\uf8b4", label: "WM",     value: globalState.fetchWM,     color: pal.tertiary },
            { icon: "\ue425", label: "Uptime", value: globalState.fetchUptime, color: "#CE93D8" }
            ]
        }
        OverviewFetchGroup {
            icon: "\ue322"; title: tr("sys_hardware"); accent: pal.tertiary
            showTitle: ncFetchCards.roomy
            rows: [
            { icon: "\ue322", label: "CPU",  value: globalState.fetchCPU,  color: pal.error },
            { icon: "\ue3af", label: "GPU",  value: globalState.fetchGPU,  color: pal.positive },
            { icon: "\uf7a3", label: "RAM",  value: globalState.fetchRAM,  color: pal.primary },
            { icon: "\ue1db", label: "Disk", value: globalState.fetchDisk, color: "#FFCC80" }
            ]
        }
        OverviewFetchGroup {
            icon: "\ue7fd"; title: tr("sys_session"); accent: pal.accent
            showTitle: ncFetchCards.roomy
            rows: [
            { icon: "\ue30c", label: "Display",  value: globalState.fetchDisplay,  color: pal.tertiary },
            { icon: "\ue86f", label: "Shell",    value: globalState.fetchShell,    color: pal.primary },
            { icon: "\uf187", label: "Packages", value: globalState.fetchPackages, color: "#FFCC80" },
            { icon: "\ue894", label: "Locale",   value: globalState.fetchLocale,   color: "#CE93D8" }
            ]
        }
    }
}
