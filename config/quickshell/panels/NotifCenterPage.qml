import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../panels"
import "../ui"

// Notification center page (island panel and Control Center)
Item {
    id: notifPage
    visible: opacity > 0.01
    Behavior on opacity { M3NumberAnim {} }

    property var _notifs: {
        var v = notificationsBackend.trackedNotifications.values.slice();
        v.reverse();
        return v;
    }
    property var _groups: globalState.groupNotifications(_notifs)
    function _delayedCall(delayMs, fn) {
        var t = notifDelayTimerComp.createObject(notifPage, { interval: Math.max(0, delayMs) });
        if (!t) { fn(); return; }
        t.triggered.connect(function () { fn(); t.destroy(); });
        t.start();
    }
    Component {
        id: notifDelayTimerComp
        Timer { repeat: false }
    }

    Rectangle {
        id: notifCard
        anchors.fill: parent
        radius: 28
        color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: 8
                Text {
                    text: "\ue7f4"; font.family: "Material Symbols Rounded"; font.pixelSize: 15
                    color: pal.primary; opacity: globalState.glassMode ? 0.88 : 1.0
                }
                Text {
                    text: tr("notifications"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.colorOnSurfVar; opacity: globalState.glassMode ? 0.88 : 1.0
                }
                Text {
                    visible: notifPage._notifs.length > 0
                    text: notifPage._notifs.length + " " + tr("notifications_lbl")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); color: pal.muted
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    id: clearAllBtn
                    visible: notifPage._notifs.length > 0
                    width: clearAllRow.implicitWidth + 32; height: 40; radius: 20
                    color: {
                        var c = containerDark(pal.secondaryCont);
                        return (globalState.glassMode && true) ? ga(c, 0.78) : c;
                    }
                    Behavior on color { M3ColorAnim {} }
                    Rectangle { anchors.fill: parent; radius: parent.radius; color: pal.colorOnSurface; opacity: clearAllBtnMa.pressed ? 0.12 : (clearAllHov.hovered ? 0.08 : 0); Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
                    RowLayout {
                        id: clearAllRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text { text: "\ue16c"; font.family: "Material Symbols Rounded"; font.pixelSize: 13; color: pal.primary }
                        Text { text: tr("clear_all"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium; color: pal.colorOnSurface }
                    }
                    HoverHandler { id: clearAllHov }
                    MouseArea { id: clearAllBtnMa;
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: globalState.clearAllNotifications()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ScrollView {
                    id: notifScroll
                    anchors.fill: parent
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    visible: notifPage._notifs.length > 0

                    ColumnLayout {
                        id: notifListCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            id: notifRepeater
                            model: notifPage._groups
                            delegate: NotifGroupCard {
                                clipFlick: notifScroll.contentItem
                                required property var modelData
                                required property int index
                                Layout.fillWidth: true
                                items: modelData.items
                                appName: modelData.appName
                                expanded: !!globalState.notifExpanded[modelData.key]
                                clearing: globalState.notifClearing
                                clearDelay: Math.min(index * 60, 360)
                                isFirst: index === 0
                                isLast: index === notifRepeater.count - 1
                                edgeRadius: 28
                                cardColor: globalState.glassMode ? ga(pal.notifCard, 0.6) : pal.notifCard
                                maxRadius: 10
                                hoverColor: pal.surfaceVar
                                textColor: pal.colorOnSurface
                                subColor: pal.colorOnSurfVar
                                mutedColor: pal.muted
                                accentColor: pal.primary
                                accentTextColor: pal.colorOnPrimary
                                errorColor: pal.error
                                onToggleExpand: { globalState.toggleNotifGroup(modelData.key); }
                                onDismissNotif: (n) => globalState.dismissNotifications([n])
                                onDismissGroup: (list) => globalState.dismissNotifications(list)
                            }
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    visible: notifPage._notifs.length === 0
                    spacing: 10

                    NotifDinoCanvas { id: notifDinoCanvas }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: tr("nothing_here")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(16 * globalState.fontScale); font.weight: Font.Medium; color: pal.muted
                    }
                }
            }
        }
    }
}
