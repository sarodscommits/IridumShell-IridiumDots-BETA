import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Wallpaper thumbnails of the appearance page
Repeater {
    id: appearanceWallpaperGrid
    model: (wpBrowser.visible && settingsWindow.winOpen) ? globalState.wallpaperList.length : 0

    delegate: Item {
        id: wpCell
        required property int index
        readonly property var wp: globalState.wallpaperList[index]
        readonly property bool isCurrent: wp !== undefined && wp.path === globalState.currentWallpaper
        readonly property bool hasProfile: wp ? profileStore.has(wp.path) : false
        readonly property bool confirming: wp !== undefined && globalState.wpDeleteConfirm === wp.path
        width: wpGrid.cellW
        height: wpGrid.cellH + 24

        HoverHandler { id: wpCellHov }

        Item {
            id: wpCellCard
            width: wpGrid.cellW; height: wpGrid.cellH
            scale: wpCellHov.hovered ? 1.03 : 1
            Behavior on scale { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }

            SettingsWpThumb {
                anchors.fill: parent
                radius: 10
                maskItem: wpGridMask
                loadWidth: 360
                source: wpCell.wp ? "file://" + (wpCell.wp.thumb !== "" ? wpCell.wp.thumb : wpCell.wp.path) : ""
                placeholderColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                iconColor: pal.mutedDeep
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (wpCell.wp && !wpCell.isCurrent) applyWallpaperSmooth(wpCell.wp.path)
            }

            Row {
                anchors.top: parent.top; anchors.left: parent.left
                anchors.margins: 6
                spacing: 4
                Rectangle {
                    visible: wpCell.hasProfile
                    width: 22; height: 22; radius: 11
                    color: Qt.rgba(0,0,0,0.55)
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Material Symbols Rounded"; font.pixelSize: 13
                        color: pal.primary
                    }
                }
                Rectangle {
                    visible: wpCell.wp ? wpCell.wp.animated : false
                    width: 22; height: 22; radius: 11
                    color: Qt.rgba(0,0,0,0.55)
                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: 1
                        text: "▶"
                        font.pixelSize: 9
                        color: "#FFFFFF"
                    }
                }
            }

            Rectangle {
                visible: wpCell.isCurrent
                anchors.top: parent.top; anchors.right: parent.right
                anchors.margins: 6
                width: 22; height: 22; radius: 11
                color: pal.primary
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Material Symbols Rounded"; font.pixelSize: 15
                    color: pal.colorOnPrimary
                }
            }

            Row {
                anchors.bottom: parent.bottom; anchors.right: parent.right
                anchors.margins: 6
                spacing: 4
                opacity: wpCellHov.hovered && !wpCell.confirming ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { M3NumberAnim { duration: m3.durFast } }

                PressIconButton {
                    visible: !wpCell.isCurrent
                    width: 26
                    height: 26
                    cornerRadius: 13
                    icon: "\ue92b"
                    iconSize: 15
                    iconColor: hovered ? pal.colorOnPrimary : "#FFFFFF"
                    hoverColor: pal.error
                    idleColor: Qt.rgba(0,0,0,0.6)
                    colorDuration: m3.durFast
                    onClicked: if (wpCell.wp) globalState.wpDeleteConfirm = wpCell.wp.path
                }

                PressIconButton {
                    visible: wpCell.hasProfile
                    width: 26
                    height: 26
                    cornerRadius: 13
                    icon: ""
                    iconSize: 15
                    iconColor: "#FFFFFF"
                    hoverColor: Qt.rgba(1,0,0,0.55)
                    idleColor: Qt.rgba(0,0,0,0.6)
                    colorDuration: m3.durFast
                    onClicked: if (wpCell.wp) deleteWallpaperProfile(wpCell.wp.path)
                }
                PressIconButton {
                    width: 26
                    height: 26
                    cornerRadius: 13
                    icon: ""
                    iconSize: 15
                    iconColor: hovered ? pal.colorOnPrimary : "#FFFFFF"
                    hoverColor: pal.primary
                    idleColor: Qt.rgba(0,0,0,0.6)
                    colorDuration: m3.durFast
                    onClicked: {
                        if (!wpCell.wp) return;
                        var p = wpCell.wp.path;
                        settingsWindow.closeWin();
                        startWallpaperProfileEdit(p);
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: "transparent"
                border.width: wpCell.isCurrent ? 2.5 : 1
                border.color: wpCell.isCurrent ? pal.primary
                : Qt.rgba(1,1,1, wpCellHov.hovered ? 0.28 : 0.08)
                Behavior on border.color { M3ColorAnim {} }
            }

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: Qt.rgba(0, 0, 0, 0.72)
                border.width: 2
                border.color: pal.error
                opacity: wpCell.confirming ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { M3NumberAnim { duration: m3.durFast } }

                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 16
                    spacing: 6
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: tr("wpd_confirm")
                        elide: Text.ElideRight
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                        color: "#FFFFFF"
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible: wpGrid.cellH > 90
                        text: tr("wpd_note")
                        elide: Text.ElideRight
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale)
                        color: Qt.rgba(1, 1, 1, 0.65)
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6
                        Rectangle {
                            width: wpCellNoTxt.implicitWidth + 18; height: 24; radius: 12
                            color: wpCellNoHov.hovered ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.12)
                            Behavior on color { M3ColorAnim { duration: m3.durFast } }
                            Text {
                                id: wpCellNoTxt
                                anchors.centerIn: parent
                                text: tr("wpd_cancel")
                                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                                color: "#FFFFFF"
                            }
                            HoverHandler { id: wpCellNoHov; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: globalState.wpDeleteConfirm = "" }
                        }
                        Rectangle {
                            width: wpCellYesRow.implicitWidth + 18; height: 24; radius: 12
                            color: wpCellYesHov.hovered ? Qt.lighter(pal.error, 1.1) : pal.error
                            Behavior on color { M3ColorAnim { duration: m3.durFast } }
                            Row {
                                id: wpCellYesRow
                                anchors.centerIn: parent
                                spacing: 3
                                Text { text: "\ue92b"; font.family: "Material Symbols Rounded"; font.pixelSize: 13; color: pal.colorOnPrimary; anchors.verticalCenter: parent.verticalCenter }
                                Text {
                                    text: tr("wpd_delete")
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
                                    color: pal.colorOnPrimary
                                }
                            }
                            HoverHandler { id: wpCellYesHov; cursorShape: Qt.PointingHandCursor }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (wpCell.wp) wpDeleteFile(wpCell.wp.path) }
                        }
                    }
                }
            }
        }

        Text {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 18
            text: wpCell.wp ? wpCell.wp.name : ""
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
            font.weight: wpCell.isCurrent ? Font.Medium : Font.Normal
            color: wpCell.isCurrent ? pal.primary : pal.muted
            elide: Text.ElideMiddle
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
