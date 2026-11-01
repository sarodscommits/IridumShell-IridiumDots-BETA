import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../panels"
import "../ui"

// Floating Control Center content: tabs, control page and overview
Item {
    id: controlCenterContent
    readonly property var eqRepeater: ncPage1GroupLoader.item ? ncPage1GroupLoader.item.eqRep : null
    Item {
        id: notchControlPanel
        x: 0
        width: parent.width
        height: parent.height
        y: 0
        clip: true
        visible: globalState.notchControlOpen || ccFloatWindow.prog > 0.005
        opacity: 1
        enabled: globalState.notchControlOpen

        Item {
            id: notchControlContent
            x: 0
            width: parent.width
            height: parent.height
            y: 0
            clip: true

            Loader {
                anchors.fill: parent
                z: 1000
                property bool isPerfMorphHost: true
                property real dimRadius: 28
                sourceComponent: perfMorphComp
            }
            HoverHandler {
                id: notchControlHover
                onHoveredChanged: {
                    if (hovered) {
                        notchControlCloseTimer.stop();
                    } else {
                        notchControlCloseTimer.restart();
                    }
                }
            }
            Timer {
                id: notchControlCloseTimer
                interval: 350
                repeat: false
                onTriggered: {
                    if (globalState.ncEditMode) return;
                    if (globalState.ccFloat) return;
                    if (!notchControlHover.hovered && !topBarHover.hovered && !(ncSideHitArea.active && ncSideHitHover.hovered) && !mediaPanel.eqDragging) globalState.notchControlOpen = false;
                }
            }
            Connections {
                target: topBarHover
                function onHoveredChanged() {
                    if (!topBarHover.hovered && globalState.notchControlOpen) notchControlCloseTimer.restart();
                    else notchControlCloseTimer.stop();
                }
            }
            Connections {
                target: globalState
                function onNcEditModeChanged() {
                    if (!globalState.ncEditMode && !notchControlHover.hovered && globalState.notchControlOpen) notchControlCloseTimer.restart();
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
                        onClicked: globalState.notchControlOpen = false
                    }
                    Item { Layout.fillWidth: true }
                    ESegmented {
                        id: ncPageTabsWrap
                        size: "s"
                        options: [{ icon: "\ue8b8", label: tr("ic_page_control"), value: 0 }, { icon: "\ue871", label: tr("nc_page_overview"), value: 1 }]
                        current: globalState.notchControlPage
                        onPicked: (v) => { if (globalState.notchControlPage !== v) globalState.playUiSound("3"); globalState.notchControlPage = v; }
                    }
                    Item { Layout.fillWidth: true }
                    EIconButton {
                        visible: globalState.ncEditMode
                        variant: "tonal"
                        icon: "\ue042"
                        onClicked: globalState.ncResetLayout(globalState.notchControlPage)
                    }
                    EIconButton {
                        variant: "tonal"
                        toggleable: true
                        checked: globalState.ncEditMode
                        icon: globalState.ncEditMode ? "\ue5ca" : "\ue3c9"
                        onClicked: { globalState.ncEditMode = !globalState.ncEditMode; globalState.ncCcSelected = ""; }
                    }
                }

                Item {
                    id: ncStack
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        id: ncPage0
                        x: 0
                        y: 0
                        width:  true ? parent.width : (parent.width - 16) / 2
                        height: true ? Math.round((parent.height - 16) * 0.66) : parent.height
                        spacing: 16
                        opacity: globalState.notchControlPage === 0 ? 1 : 0
                        visible: opacity > 0.01
                        Behavior on opacity { M3NumberAnim {} }

                        Item {
                            id: ncCcGridBlock
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            Layout.preferredHeight: ncCcGridLoader.item ? Math.max(ncCcGridLoader.item.implicitHeight + 32, (ncPage0.height - 29) * 0.54) : 0
                            Loader {
                                id: ncCcGridLoader
                                anchors.fill: parent
                                anchors.margins: 0
                                sourceComponent: ccGridComp
                            }
                        }

                        Loader {
                            visible: globalState.ncEditMode
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            sourceComponent: ccTrayComp
                        }

                        Loader {
                            id: ncHeroLoader
                            property bool live: globalState.notchControlOpen && globalState.notchControlPage === 0 && !ccFloatWindow.animating
                            visible: !globalState.ncEditMode
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.topMargin: 8
                            Layout.minimumHeight: 170
                            sourceComponent: ccMediaCardComp
                        }
                    }

                    NotifCenterPage {
                        id: ncPage2
                        width:  true ? parent.width : (parent.width - 16) / 2
                        height: true ? (parent.height - 16 - ncPage0.height) : parent.height
                        x: true ? 0 : parent.width - width
                        y: true ? parent.height - height : 0
                        opacity: globalState.notchControlPage === 0 ? 1 : 0
                    }

                    Item {
                        id: ncPage1GroupHost
                        anchors.fill: parent
                        readonly property bool wanted: globalState.notchControlOpen && globalState.notchControlPage === 1
                        property bool keep: false
                        onWantedChanged: {
                            if (wanted) {
                                keep = true; ncPage1GroupKeepTimer.stop();
                                if (!ncPage1GroupLoader.item) Qt.callLater(globalState.reloadWeather);
                            } else ncPage1GroupKeepTimer.restart();
                        }
                        Timer { id: ncPage1GroupKeepTimer; interval: 20000; repeat: false; onTriggered: { ncPage1GroupHost.keep = false; if (!ncPage1GroupHost.wanted) gcTimer.restart(); } }
                        Loader {
                            id: ncPage1GroupLoader
                            anchors.fill: parent
                            asynchronous: false
                            active: ncPage1GroupHost.wanted || ncPage1GroupHost.keep
                            onStatusChanged: {
                                var st = ["Null", "Ready", "Loading", "Error"][status];
                                console.log("[notchPanel] Overview page:", st);
                                if (status === Loader.Error) console.warn("[notchPanel] ERROR creating the Overview page (see the QML error right above)");
                            }
                            property bool vert: true
                            property bool pageOn: globalState.notchControlPage === 1
                            property bool open: globalState.notchControlOpen
                            sourceComponent: ccOverviewComp
                        }
                    }
                }
            }
        }
    }
}
