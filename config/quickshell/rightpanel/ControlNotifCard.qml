import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import ".."
import "../panels"
import "../ui"

// Notification list card of the control panel
Rectangle {
    id: cpNotifCard
    anchors.fill: parent
    radius: 16
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    opacity: globalState.cpModulesPage === 1 ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { M3NumberAnim {} }

    property var _notifs: {
        var v = notificationsBackend.trackedNotifications.values.slice();
        v.reverse();
        return v;
    }

    Component {
        id: cpNotifDelayTimerComp
        Timer { repeat: false }
    }
    function _delayedCall(delayMs, fn) {
        var t = cpNotifDelayTimerComp.createObject(cpNotifCard, { interval: Math.max(0, delayMs) });
        if (!t) { fn(); return; }
        t.triggered.connect(function () { fn(); t.destroy(); });
        t.start();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                text: "\ue7f4"; font.family: "Material Symbols Rounded"; font.pixelSize: 15
                color: pal.primary; opacity: globalState.glassMode ? 0.88 : 1.0
            }
            Text {
                text: tr("notifications"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar; opacity: globalState.glassMode ? 0.88 : 1.0
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: cpNotifCard._notifs.length > 0
                text: cpNotifCard._notifs.length + " " + tr("notifications_lbl")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); color: pal.muted
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ControlNotifList { id: controlNotifList }

            ColumnLayout {
                anchors.centerIn: parent
                visible: cpNotifCard._notifs.length === 0
                spacing: 12

                NotifDinoCanvas { id: cpNotifDinoCanvas }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: tr("nothing_here")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(16 * globalState.fontScale); font.weight: Font.Medium; color: pal.muted
                }
            }
        }
        Rectangle {
            id: cpClearAllBtn
            Layout.fillWidth: true
            height: 40; radius: 14
            enabled: cpNotifCard._notifs.length > 0
            opacity: enabled ? 1.0 : 0.4
            Behavior on opacity { M3NumberAnim {} }
            color: {
                var c = containerDark(pal.secondaryCont);
                return (globalState.glassMode && true) ? ga(c, 0.78) : c;
            }
            Behavior on color { M3ColorAnim {} }
            Rectangle { anchors.fill: parent; radius: parent.radius; color: pal.colorOnSurface; opacity: cpClearAllBtnMa.pressed ? 0.12 : (cpClearAllHov.hovered ? 0.08 : 0); Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text {
                    text: "\ue16c"; font.family: "Material Symbols Rounded"; font.pixelSize: 16
                    color: pal.primary
                    Behavior on color { M3ColorAnim {} }
                }
                Text {
                    text: tr("clear_all"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                    color: pal.colorOnSurface
                    Behavior on color { M3ColorAnim {} }
                }
            }
            HoverHandler { id: cpClearAllHov }
            MouseArea { id: cpClearAllBtnMa;
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                enabled: cpClearAllBtn.enabled
                onClicked: {
                    var n = controlNotifList.cpNotifRepeater.count;
                    if (n === 0) return;
                    globalState.playUiSound("5");
                    var maxSweepMs = 500;
                    var stagger = n > 1 ? Math.min(70, maxSweepMs / (n - 1)) : 0;
                    var notifRefs = cpNotifCard._notifs.slice();
                    for (var idx = n - 1; idx >= 0; idx--) {
                        var order = (n - 1) - idx;
                        cpNotifCard._delayedCall(order * stagger, (function (capturedIdx) {
                            return function () {
                                var it = controlNotifList.cpNotifRepeater.itemAt(capturedIdx);
                                if (it) it._removing = true;
                            };
                        })(idx));
                    }
                    var totalMs = (n - 1) * stagger + 330;
                    cpNotifCard._delayedCall(totalMs, function () {
                        for (var i = 0; i < notifRefs.length; i++) notifRefs[i].dismiss();
                    });
                }
            }
        }
    }
}
