import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// App launcher page of the left panel
Item {
    id: leftPanelPage2
    readonly property bool hoverActive: leftPanelPage2Hover.hovered
    readonly property bool listMoving: leftInlineAppList.moving
    opacity: (globalState.calendarMenuOpen && globalState.leftPanelPage === 1) ? 1 : 0
    visible: (globalState.calendarMenuOpen && globalState.leftPanelPage === 1) || opacity > 0
    Behavior on opacity { M3NumberAnim {} }

    HoverHandler {
        id: leftPanelPage2Hover
        onHoveredChanged: {
            if (hovered) {
                calCloseTimer.stop();
                globalState.calendarMenuOpen = true;
            } else {
                calCloseTimer.restart();
            }
        }
    }

    property bool leftLauncherOpen: globalState.calendarMenuOpen && globalState.leftPanelPage === 1
    onLeftLauncherOpenChanged: {
        if (leftLauncherOpen) {
            leftLauncherCard.filteredApps = leftLauncherCard.getFilteredApps();
            leftLauncherFocusTimer.start();
        } else {
            topBarContent.searchBtn.topSearchInputHome.topSearchInput.text = "";
            leftLauncherCard.searchQuery = "";
            globalState.fileSearchResults = [];
        }
    }

    Timer {
        id: leftLauncherFocusTimer
        interval: 120
        repeat: false
        onTriggered: {
            topBarContent.searchBtn.topSearchInputHome.topSearchInput.forceActiveFocus();
            topBarContent.searchBtn.topSearchInputHome.topSearchInput.focus = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            id: leftLauncherCardUi
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: (leftLauncherCard.blockMode && leftInlineAppList.visible) ? "transparent" : (globalState.glassMode ? ga(pal.surfaceHigh, 0.6) : pal.surfaceHigh)
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: (leftLauncherCard.blockMode && leftInlineAppList.visible) ? 0 : 10
                spacing: 6

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.centerIn: parent
                        visible: leftLauncherCard.showLoading
                        text: "Loading apps..."
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                        color: pal.muted
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: leftLauncherCard.showEmpty
                        text: tr("no_apps_found")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                        color: pal.muted
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: leftLauncherCard.showEmptyFiles
                        text: tr("no_files_found")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                        color: pal.muted
                    }

                    ListView {
                        id: leftInlineAppList
                        anchors.fill: parent
                        visible: !leftLauncherCard.showLoading && !leftLauncherCard.showEmpty && !leftLauncherCard.showEmptyFiles
                        clip: true
                        spacing: (globalState.searchMode !== "files" && leftLauncherCard && leftLauncherCard.searchQuery.trim().length === 0) ? 0 : 2
                        model: globalState.searchMode === "files" ? globalState.fileSearchResults : leftLauncherCard.filteredApps
                        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                        property color appTitleColor: pal.textPrimary
                        property color appIconColor:  pal.primary

                        WheelHandler {
                            target: null
                            onWheel: (event) => {
                                calCloseTimer.stop();
                                globalState.calendarMenuOpen = true;
                            }
                        }

                        delegate: Item {
                            id: leftInlineAppListDel
                            required property var modelData
                            required property int index
                            readonly property real rowH: modelData.isHeader ? 30 : 32
                            readonly property real padTop: (modelData.inBlock && modelData.isHeader) ? 8 : 0
                            readonly property real padBot: modelData.blockLast ? 8 : 0
                            readonly property real blockGap: modelData.blockLast ? 8 : 0
                            width: leftInlineAppList.width
                            height: padTop + rowH + padBot + blockGap

                            Rectangle {
                                visible: !!modelData.inBlock
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                height: leftInlineAppListDel.padTop + leftInlineAppListDel.rowH + leftInlineAppListDel.padBot + (modelData.blockLast ? 0 : 0.5)
                                color: globalState.glassMode ? ga(pal.surfaceHigh, 0.6) : pal.surfaceHigh
                                topLeftRadius:     modelData.blockFirst ? 14 : 0
                                topRightRadius:    modelData.blockFirst ? 14 : 0
                                bottomLeftRadius:  modelData.blockLast  ? 14 : 0
                                bottomRightRadius: modelData.blockLast  ? 14 : 0
                            }

                            Rectangle {
                                x: modelData.inBlock ? 10 : 0
                                y: leftInlineAppListDel.padTop
                                width: parent.width - 2 * x
                                height: leftInlineAppListDel.rowH
                                radius: 8
                                color: (!modelData.isHeader && leftListItemHov.hovered) ? pal.surfacePop : "transparent"
                                Behavior on color { M3ColorAnim {} }

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
                                        width: 22; height: 22; radius: modelData.internal ? 11 : 6
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
                                            color: leftInlineAppList.appIconColor
                                        }
                                        Text {
                                            anchors.centerIn: parent
                                            visible: (!modelData.icon || modelData.icon === "") && !modelData.internal && globalState.searchMode !== "files"
                                            text: modelData.name.charAt(0).toUpperCase()
                                            font.family: globalState.fontPrimary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Bold
                                            color: leftInlineAppList.appIconColor
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Medium
                                        color: leftInlineAppList.appTitleColor
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }

                                HoverHandler { id: leftListItemHov; enabled: !modelData.isHeader }
                                MouseArea {
                                    enabled: !modelData.isHeader
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onPressed: {
                                        calCloseTimer.stop();
                                        globalState.calendarMenuOpen = true;
                                    }
                                    onClicked: {
                                        if (globalState.searchMode !== "files") globalState.launchApp(modelData);
                                        else Quickshell.execDetached(["bash", "-c", modelData.exec]);
                                        topBarContent.searchBtn.topSearchInputHome.topSearchInput.text = "";
                                        leftLauncherCard.searchQuery = "";
                                        globalState.calendarMenuOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
