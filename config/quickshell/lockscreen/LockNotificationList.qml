import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../panels"

// Expanded notification list of the lockscreen pill
Item {
    id: lockNotifPanel
    anchors.fill: parent
    opacity: lockNotifPill.expanded ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { M3NumberAnim { duration: lockNotifPill.expanded ? 320 : 100 } }

    MouseArea { anchors.fill: parent; onClicked: hiddenInput.forceActiveFocus() }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            spacing: 8
            Item { Layout.fillWidth: true }
            FadeIcon {
                text: lockNotifPill.weatherGlyph
                font.family: "Material Symbols Rounded"; font.pixelSize: 17
                color: lockNotifPill.weatherColor
            }
            Text {
                text: lockNotifPill.weatherTempText
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurface
            }
            PressIconButton {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Layout.leftMargin: 2
                cornerRadius: 14
                icon: ""
                iconSize: 20
                iconColor: pal.colorOnSurfVar
                hoverColor: pal.surfaceVar
                idleColor: "transparent"
                onClicked: { lockNotifPill.expanded = false; hiddenInput.forceActiveFocus(); }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            RowLayout {
                anchors.fill: parent
                spacing: 8
                Text {
                    text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 17
                    color: pal.primary
                }
                Text {
                    text: tr("notifications")
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.DemiBold
                    color: pal.colorOnSurface
                }
                Text {
                    visible: lockNotifPill._notifs.length > 0
                    text: "· " + lockNotifPill._notifs.length
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                    color: pal.muted
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    visible: lockNotifPill._notifs.length > 0
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: lockNotifClearTxt.implicitWidth + 20
                    Layout.leftMargin: 4
                    radius: 13
                    color: lockNotifClearHov.hovered ? pal.primary : (globalState.glassMode ? ga(pal.surface, 0.55) : pal.surface)
                    Behavior on color { M3ColorAnim {} }
                    Text {
                        id: lockNotifClearTxt
                        anchors.centerIn: parent
                        text: tr("clear_all")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
                        color: lockNotifClearHov.hovered ? pal.colorOnPrimary : pal.colorOnSurface
                    }
                    HoverHandler { id: lockNotifClearHov }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            globalState.clearAllNotifications();
                            hiddenInput.forceActiveFocus();
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                id: lockNotifScroll
                anchors.fill: parent
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    id: lockNotifListCol
                    width: lockNotifScroll.availableWidth
                    spacing: 8

                    Repeater {
                        id: lockNotifRepeater
                        model: lockNotifPill._groups
                        delegate: NotifGroupCard {
                            clipFlick: lockNotifScroll.contentItem
                            required property var modelData
                            required property int index
                            width: lockNotifListCol.width
                            items: modelData.items
                            appName: modelData.appName
                            expanded: !!globalState.notifExpanded[modelData.key]
                            clearing: globalState.notifClearing
                            clearDelay: Math.min(index * 60, 360)
                            isFirst: index === 0
                            isLast: index === lockNotifRepeater.count - 1
                            maxRadius: 10
                            edgeRadius: 28
                            cardColor: globalState.glassMode ? ga(pal.surface, 0.55) : pal.surface
                            hoverColor: pal.surfaceVar
                            textColor: pal.colorOnSurface
                            subColor: pal.colorOnSurfVar
                            mutedColor: pal.muted
                            accentColor: pal.primary
                            accentTextColor: pal.colorOnPrimary
                            errorColor: pal.error
                            onToggleExpand: { globalState.toggleNotifGroup(modelData.key); hiddenInput.forceActiveFocus(); }
                            onDismissNotif: (n) => { globalState.dismissNotifications([n]); hiddenInput.forceActiveFocus(); }
                            onDismissGroup: (list) => { globalState.dismissNotifications(list); hiddenInput.forceActiveFocus(); }
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                visible: lockNotifPill._notifs.length === 0
                spacing: 8
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 40
                    color: pal.muted
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: tr("nothing_here")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale)
                    color: pal.muted
                }
            }
        }
    }
}
