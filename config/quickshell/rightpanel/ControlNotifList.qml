import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import ".."
import "../panels"
import "../ui"

// Scrollable grouped notification list of the control panel
ScrollView {
    id: controlNotifList
    property alias cpNotifRepeater: cpNotifRepeater
    anchors.fill: parent
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ColumnLayout {
        id: cpNotifListCol
        width: parent.width
        spacing: 6

        Repeater {
            id: cpNotifRepeater
            model: cpNotifCard._notifs
            property color _colorOnSurface: pal.colorOnSurface
            property color _colorOnSurfVar: pal.colorOnSurfVar
            property color _muted:          pal.muted
            property color _primary:        pal.primary
            property color _onPrimary:      pal.colorOnPrimary
            property color _error:          pal.error
            property color _cardBg:         containerDark(pal.secondaryCont)
            property color _outline:        pal.mutedDeep
            delegate: Rectangle {
                id: cpNotifDelegate
                required property var modelData
                readonly property real _W: cpNotifDelegate.width
                readonly property int _closeW: 64
                readonly property int _splitGap: 4
                readonly property int _dismissSize: _closeW + _splitGap
                readonly property int _pad: 10
                readonly property int _iconSize: 32
                readonly property int _dismissSizeOld: 24
                readonly property int _gap: 10
                property bool _removing: false
                Layout.fillWidth: true
                radius: 14
                color: "transparent"
                border.width: 0
                border.color: globalState.glassMode ? ga(cpNotifRepeater._outline, 0.25) : ga(cpNotifRepeater._outline, 0.4)
                implicitHeight: Math.max(_iconSize, cpNotifTextCol.height) + _pad * 2
                opacity: _removing ? 0 : 1
                Behavior on opacity { M3NumberAnim { duration: m3.durFast } }

                transform: Translate {
                    x: cpNotifDelegate._removing ? -cpNotifDelegate.width : 0
                    Behavior on x { M3SpringAnim { token: "spatialFast" } }
                }

                Timer {
                    id: cpNotifRemoveTimer
                    interval: 330
                    onTriggered: cpNotifDelegate.modelData.dismiss()
                }
                function startRemove() {
                    if (cpNotifDelegate._removing) return;
                    cpNotifDelegate._removing = true;
                    cpNotifRemoveTimer.start();
                }

                Rectangle {
                    x: 0; y: 0
                    width: Math.max(0, cpNotifDelegate._W - cpNotifDelegate._closeW - cpNotifDelegate._splitGap)
                    height: cpNotifDelegate.height
                    topLeftRadius: height / 2; bottomLeftRadius: height / 2
                    topRightRadius: 8; bottomRightRadius: 8
                    color: globalState.glassMode ? ga(cpNotifRepeater._cardBg, 0.6) : cpNotifRepeater._cardBg
                }
                Rectangle {
                    id: cpNotifCloseSeg
                    width: cpNotifDelegate._closeW
                    x: cpNotifDelegate._W - width; y: 0
                    height: cpNotifDelegate.height
                    z: 5
                    color: "transparent"
                    property color segColor: cpNotifCloseHov.hovered ? Qt.darker(cpNotifRepeater._error, 1.6)
                    : (globalState.glassMode ? ga(cpNotifRepeater._cardBg, 0.6) : cpNotifRepeater._cardBg)
                    PillCloseShape { anchors.fill: parent; segColor: parent.segColor }
                    Behavior on segColor { M3ColorAnim {} }
                    Text {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -2
                        text: "\ue5cd"; font.family: "Material Symbols Rounded"; font.pixelSize: 18
                        color: cpNotifCloseHov.hovered ? cpNotifRepeater._error : cpNotifRepeater._muted
                        scale: cpNotifCloseHov.hovered ? 1.12 : 1
                        Behavior on scale { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
                    }
                    HoverHandler { id: cpNotifCloseHov }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { cpNotifDelegate.startRemove() }
                    }
                }

                Item {
                    id: cpNotifSlide
                    anchors.fill: parent

                    Rectangle {
                        x: cpNotifDelegate._pad
                        y: cpNotifDelegate._pad
                        width: cpNotifDelegate._iconSize
                        height: cpNotifDelegate._iconSize
                        radius: cpNotifDelegate._iconSize / 2
                        color: cpNotifDelegate.modelData.urgency === NotificationUrgency.Critical ? cpNotifRepeater._error : cpNotifRepeater._primary
                        Text {
                            anchors.centerIn: parent
                            text: "\ue7f4"; font.family: "Material Symbols Rounded"; font.pixelSize: 16
                            color: cpNotifRepeater._onPrimary
                        }
                    }

                    Column {
                        id: cpNotifTextCol
                        x: cpNotifDelegate._pad + cpNotifDelegate._iconSize + cpNotifDelegate._gap
                        y: cpNotifDelegate._pad
                        width: cpNotifDelegate._W - x - cpNotifDelegate._gap - cpNotifDelegate._dismissSize - cpNotifDelegate._pad
                        spacing: 2
                        Text {
                            width: parent.width
                            text: cpNotifDelegate.modelData.appName || " "
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium
                            color: cpNotifRepeater._muted
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: cpNotifDelegate.modelData.summary
                            font.family: globalState.fontPrimary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.DemiBold
                            color: cpNotifRepeater._colorOnSurface
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            visible: cpNotifDelegate.modelData.body !== ""
                            text: cpNotifDelegate.modelData.body
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                            color: cpNotifRepeater._colorOnSurfVar
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        id: cpNotifDismiss
                        visible: false
                        x: cpNotifDelegate._W - cpNotifDelegate._pad - cpNotifDelegate._dismissSize
                        y: cpNotifDelegate._pad
                        width: cpNotifDelegate._dismissSize
                        height: cpNotifDelegate._dismissSize
                        radius: cpNotifDelegate._dismissSize / 2
                        color: cpNotifDismissHov.hovered ? Qt.darker(cpNotifRepeater._error, 1.5) : "transparent"
                        Behavior on color { M3ColorAnim {} }
                        Text {
                            anchors.centerIn: parent
                            text: "\ue5cd"; font.family: "Material Symbols Rounded"; font.pixelSize: 14
                            color: cpNotifDismissHov.hovered ? cpNotifRepeater._error : cpNotifRepeater._muted
                        }
                        HoverHandler { id: cpNotifDismissHov }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: cpNotifDelegate.startRemove()
                        }
                    }
                }
            }
        }
    }
}
