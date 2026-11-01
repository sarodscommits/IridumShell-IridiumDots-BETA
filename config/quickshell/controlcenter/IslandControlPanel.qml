import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../panels"
import "../ui"

// Island control panel: pages, grid, media and notifications
Item {
    id: islandControlPanel
    readonly property var eqRepeater: icPage1Loader.item ? icPage1Loader.item.eqRep : null
    anchors.fill: parent
    visible: unifiedFrame.islandMode && (globalState.islandControlOpen || opacity > 0.01)
    opacity: (unifiedFrame.islandMode && globalState.islandControlOpen) ? 1 : 0
    enabled: unifiedFrame.islandMode && globalState.islandControlOpen
    Behavior on opacity { M3NumberAnim {} }

    Item {
        id: islandControlContent
        width: unifiedFrame.islandControlContentWidth
        Behavior on width { M3SpringAnim { token: "spatialFast" } }
        readonly property real vertH: unifiedFrame.topBaseH + unifiedFrame.islandControlExtraH - 18
        x: unifiedFrame.barVertical
        ? (unifiedFrame.barAtRight ? (parent.width - width - 9) : 9)
        : (parent.width - width) / 2
        y: unifiedFrame.barVertical ? (parent.height - height) / 2 : (unifiedFrame.barAtBottom ? 10 : 8)
        height: unifiedFrame.barVertical ? vertH : Math.max(0, parent.height - 18)
        clip: true

        Loader {
            anchors.fill: parent
            z: 1000
            property bool isPerfMorphHost: true
            property real dimRadius: 24
            sourceComponent: perfMorphComp
        }
        HoverHandler {
            id: islandControlHover
            onHoveredChanged: {
                if (hovered) {
                    islandControlCloseTimer.stop();
                } else {
                    islandControlCloseTimer.restart();
                }
            }
        }
        Timer {
            id: islandControlCloseTimer
            interval: 350
            repeat: false
            onTriggered: {
                if (globalState.ncEditMode) return;
                if (!islandControlHover.hovered && !rightPanelContent.mediaPanel.eqDragging) globalState.islandControlOpen = false;
            }
        }
        Connections {
            target: globalState
            function onNcEditModeChanged() {
                if (!globalState.ncEditMode && !islandControlHover.hovered && globalState.islandControlOpen) islandControlCloseTimer.restart();
            }
            function onIslandControlPageChanged() {
                if (globalState.islandControlPage > 1 && globalState.ncEditMode) { globalState.ncEditMode = false; globalState.ncCcSelected = ""; }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                spacing: 8
                EIconButton {
                    icon: "\ue5cd"
                    onClicked: globalState.islandControlOpen = false
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    id: icPageTabsWrap
                    Layout.preferredWidth: icPageTabsRow.implicitWidth + 16
                    Layout.preferredHeight: 56
                    radius: 28
                    color: globalState.glassMode ? ga(pal.surfaceHigh, 0.6) : pal.surfaceHigh
                    Row {
                        id: icPageTabsRow
                        anchors.centerIn: parent
                        spacing: 4
                        Repeater {
                            id: icPageTabsRepeater
                            model: [
                            { icon: "\ue8b8", labelKey: "ic_page_control" },
                            { icon: "\ue935", labelKey: "ic_page_info" },
                            { icon: "\ue7f4", labelKey: "ic_page_notif" },
                            { icon: "\ue322", labelKey: "ic_page_monitor" }
                            ]
                            EIconButton {
                                required property var modelData
                                required property int index
                                readonly property bool active: globalState.islandControlPage === index
                                anchors.verticalCenter: parent.verticalCenter
                                icon: modelData.icon
                                widthMode: active ? "wide" : "default"
                                variant: active ? "filled" : "standard"
                                onClicked: {
                                    if (globalState.islandControlPage !== index) globalState.playUiSound("3");
                                    globalState.islandControlPage = index;
                                }
                            }
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                EIconButton {
                    visible: globalState.ncEditMode && globalState.islandControlPage <= 1
                    variant: "tonal"
                    icon: "\ue042"
                    onClicked: globalState.ncResetLayout(globalState.islandControlPage)
                }
                EIconButton {
                    visible: globalState.islandControlPage <= 1
                    variant: "tonal"
                    toggleable: true
                    checked: globalState.ncEditMode
                    icon: globalState.ncEditMode ? "\ue5ca" : "\ue3c9"
                    onClicked: { globalState.ncEditMode = !globalState.ncEditMode; globalState.ncCcSelected = ""; }
                }
                EIconButton {
                    variant: "tonal"
                    toggleable: true
                    checked: globalState.settingsOpen
                    icon: "\ue8b8"
                    onClicked: { globalState.islandControlOpen = false; globalState.settingsOpen = !globalState.settingsOpen; }
                }
            }

            Item {
                id: icStack
                Layout.fillWidth: true
                Layout.fillHeight: true

                GridLayout {
                    id: icPage0
                    anchors.fill: parent
                    columns: unifiedFrame.barVertical ? 1 : 2
                    rowSpacing: 24
                    columnSpacing: 24
                    opacity: globalState.islandControlPage === 0 ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on opacity { M3NumberAnim {} }

                    Item {
                        id: icCcGridBlock
                        Layout.fillWidth: true
                        Layout.fillHeight: !unifiedFrame.barVertical
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredHeight: unifiedFrame.barVertical
                        ? (icCcGridLoader.item ? Math.max(icCcGridLoader.item.implicitHeight + 32, (icPage0.height - 29) * 0.54) : 0)
                        : (icCcGridLoader.item ? icCcGridLoader.item.implicitHeight + 32 : 0)
                        Loader {
                            id: icCcGridLoader
                            anchors.fill: parent
                            anchors.margins: 0
                            sourceComponent: ccGridComp
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: unifiedFrame.barVertical
                        Layout.fillHeight: true
                        Layout.preferredWidth: unifiedFrame.barVertical ? -1 : Math.min(560, Math.round(icPage0.width * 0.5))
                        Layout.maximumWidth: unifiedFrame.barVertical ? Number.POSITIVE_INFINITY : Math.min(560, Math.round(icPage0.width * 0.5))
                        spacing: 16

                        Loader {
                            visible: globalState.ncEditMode
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: ccTrayComp
                        }

                        Loader {
                            property bool live: globalState.islandControlOpen && globalState.islandControlPage === 0
                            visible: !globalState.ncEditMode
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 200
                            sourceComponent: ccMediaCardComp
                        }
                    }
                }

                Item {
                    id: icPage1Host
                    anchors.fill: parent
                    readonly property bool wanted: globalState.islandControlOpen && globalState.islandControlPage === 1
                    property bool keep: false
                    onWantedChanged: {
                        if (wanted) {
                            keep = true; icPage1KeepTimer.stop();
                            if (!icPage1Loader.item) Qt.callLater(globalState.reloadWeather);
                        } else icPage1KeepTimer.restart();
                    }
                    Timer { id: icPage1KeepTimer; interval: 20000; repeat: false; onTriggered: { icPage1Host.keep = false; if (!icPage1Host.wanted) gcTimer.restart(); } }
                    Loader {
                        id: icPage1Loader
                        anchors.fill: parent
                        asynchronous: false
                        active: icPage1Host.wanted || icPage1Host.keep
                        property bool vert: true
                        property bool pageOn: globalState.islandControlPage === 1
                        property bool open: globalState.islandControlOpen
                        sourceComponent: ccOverviewComp
                    }
                }

                Item {
                    id: icPage2Host
                    anchors.fill: parent
                    readonly property bool wanted: globalState.islandControlOpen && globalState.islandControlPage === 2
                    property bool keep: false
                    onWantedChanged: { if (wanted) { keep = true; icPage2KeepTimer.stop(); } else icPage2KeepTimer.restart(); }
                    Timer { id: icPage2KeepTimer; interval: 20000; repeat: false; onTriggered: { icPage2Host.keep = false; if (!icPage2Host.wanted) gcTimer.restart(); } }
                    Loader {
                        id: icPage2Loader
                        anchors.fill: parent
                        asynchronous: false
                        active: icPage2Host.wanted || icPage2Host.keep
                        sourceComponent: Component {
                            NotifCenterPage {
                                id: icPage2
                                anchors.fill: parent
                                opacity: globalState.islandControlPage === 2 ? 1 : 0
                            }
                        }
                    }
                }

                Item {
                    id: icPage3Host
                    anchors.fill: parent
                    readonly property bool wanted: globalState.islandControlOpen && globalState.islandControlPage === 3
                    property bool keep: false
                    onWantedChanged: { if (wanted) { keep = true; icPage3KeepTimer.stop(); } else icPage3KeepTimer.restart(); }
                    Timer { id: icPage3KeepTimer; interval: 20000; repeat: false; onTriggered: { icPage3Host.keep = false; if (!icPage3Host.wanted) gcTimer.restart(); } }
                    Loader {
                        id: icPage3Loader
                        anchors.fill: parent
                        asynchronous: false
                        active: icPage3Host.wanted || icPage3Host.keep
                        property bool live: icPage3Host.wanted
                        opacity: globalState.islandControlPage === 3 ? 1 : 0
                        visible: opacity > 0.01
                        Behavior on opacity { M3NumberAnim {} }
                        sourceComponent: ccMonitorComp
                    }
                }

            }
        }
    }
}
