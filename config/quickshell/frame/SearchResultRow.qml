import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Launcher result row (app, file or header)
Item {
    id: srr
    property ListView list: null
    property Item guard: null
    property real blockRadius: 18
    property bool pillHover: false
    property color hoverColor: pal.surfacePop
    property bool roundIcons: false
    signal launched()
    required property var modelData
    required property int index
    // Segmented cards 2px apart: large corners at group ends, small in between
    readonly property bool isHeader: !!modelData.isHeader
    readonly property bool inBlk: !!modelData.inBlock
    readonly property bool segFirst: inBlk ? !!modelData.segFirst : index === 0
    readonly property bool segLast: inBlk ? !!modelData.blockLast : (srr.list !== null && index === srr.list.count - 1)
    readonly property real rowH: isHeader ? 30 : 32
    readonly property real padTop: (inBlk && isHeader && index > 0) ? 6 : 0
    readonly property real gapAfter: isHeader ? 2 : (segLast ? (inBlk ? 6 : 0) : 2)
    readonly property real smallR: 4
    readonly property real bigR: srr.blockRadius
    readonly property bool hov: !isHeader && itemHov.hovered
    readonly property real hovR: srr.pillHover ? rowH / 2 : 12
    property real topR: hov ? Math.max(hovR, segFirst ? bigR : 0) : (segFirst ? bigR : smallR)
    property real botR: hov ? Math.max(hovR, segLast ? bigR : 0) : (segLast ? bigR : smallR)
    Behavior on topR { M3SpringAnim { token: "spatialFast" } }
    Behavior on botR { M3SpringAnim { token: "spatialFast" } }
    width: srr.list.width
    height: padTop + rowH + gapAfter

    Rectangle {
        visible: !srr.isHeader
        y: srr.padTop
        width: parent.width
        height: srr.rowH
        topLeftRadius: srr.topR; topRightRadius: srr.topR
        bottomLeftRadius: srr.botR; bottomRightRadius: srr.botR
        color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
        Rectangle {
            anchors.fill: parent
            topLeftRadius: srr.topR; topRightRadius: srr.topR
            bottomLeftRadius: srr.botR; bottomRightRadius: srr.botR
            color: srr.hov ? srr.hoverColor : "transparent"
            Behavior on color { M3ColorAnim { duration: srr.pillHover ? m3.durFast : m3.durDefault } }
        }
    }

    Item {
        x: 0
        y: srr.padTop
        width: parent.width
        height: srr.rowH

        RowLayout {
            visible: !!modelData.isHeader
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 6
            Text {
                text: modelData.glyph || ""
                font.family: "Material Symbols Rounded"; font.pixelSize: 13
                color: pal.primary
            }
            Text {
                text: modelData.name.toUpperCase()
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Bold
                font.letterSpacing: 1.2
                color: pal.muted
            }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            visible: !modelData.isHeader
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Rectangle {
                width: 22; height: 22; radius: (srr.roundIcons || modelData.internal) ? 11 : 6
                color: modelData.internal ? pal.primary : (modelData.icon ? "transparent" : pal.surfaceElevated)
                Behavior on color { M3ColorAnim {} }
                Text {
                    anchors.centerIn: parent
                    visible: !!modelData.internal && globalState.searchMode !== "files"
                    text: modelData.glyph || ""
                    font.family: "Material Symbols Rounded"; font.pixelSize: 15
                    color: pal.surfaceLowest
                }
                Image {
                    sourceSize: Qt.size(96, 96)
                    anchors.fill: parent
                    source: modelData.icon ? ("file://" + modelData.icon) : ""
                    fillMode: Image.PreserveAspectFit
                    visible: modelData.icon !== ""
                    smooth: true
                    mipmap: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: (!modelData.icon || modelData.icon === "") && globalState.searchMode === "files"
                    text: "\ue873"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 13
                    color: srr.list.appIconColor
                }
                Text {
                    anchors.centerIn: parent
                    visible: (!modelData.icon || modelData.icon === "") && !modelData.internal && globalState.searchMode !== "files"
                    text: modelData.name.charAt(0).toUpperCase()
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Bold
                    color: srr.list.appIconColor
                }
            }

            Text {
                Layout.fillWidth: true
                text: modelData.name
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Medium
                color: srr.list.appTitleColor
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        HoverHandler { id: itemHov; enabled: !modelData.isHeader }
        MouseArea {
            enabled: !modelData.isHeader
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onPressed: {
                topBarContent.searchBtn.topSearchInputHome.islandSearchCloseTimer.stop();
                srr.guard.clickGuard = true;
            }
            onReleased: srr.guard.clickGuard = false
            onClicked: {
                if (globalState.searchMode !== "files") globalState.launchApp(modelData);
                else Quickshell.execDetached(["bash", "-c", modelData.exec]);
                topBarContent.searchBtn.topSearchInputHome.topSearchInput.text = "";
                leftPanelContent.leftLauncherCard.searchQuery = "";
                srr.launched();
            }
        }
    }
}
