import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../panels"

// Scaled workspace screen with animated window tiles
Rectangle {
    id: wsPreviewScreen
    property alias wsPreviewRepeater: wsPreviewRepeater
    x: 12; y: 12 + wsPreviewPopup.headerH + 8
    width: wsPreviewPopup.thumbW
    height: wsPreviewPopup.thumbH
    radius: 12
    clip: true
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)

    EmptyHint {
        anchors.centerIn: parent
        visible: wsPreviewPopup.wsClients.length === 0
        text: tr("nothing_here")
        key: "" + globalState.wsPreviewId
        shapeSize: 22
    }

    Rectangle {
        id: wsPreviewViewport
        visible: wsPreviewPopup.bbox.zoomedOut
        x: wsPreviewPopup.offX
        y: wsPreviewPopup.offY
        width: wsPreviewPopup.screenW * wsPreviewPopup.sc
        height: wsPreviewPopup.screenH * wsPreviewPopup.sc
        radius: 6
        color: ga(pal.primary, 0.07)
        border.width: 1.5
        border.color: ga(pal.primary, 0.6)
    }
    Rectangle {
        visible: wsPreviewPopup.bbox.zoomedOut
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.margins: 6
        width: wsZoomTxt.implicitWidth + 12; height: 18; radius: 9
        color: ga(pal.primary, 0.18)
        z: 10
        Text {
            id: wsZoomTxt
            anchors.centerIn: parent
            text: "×" + (wsPreviewPopup.thumbW / wsPreviewPopup.screenW / wsPreviewPopup.sc).toFixed(1)
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
            color: pal.primary
        }
    }

    Repeater {
        id: wsPreviewRepeater
        model: wsPreviewPopup.poolSize
        property color _win: pal.surface
        property color _border: ga(pal.primary, 0.55)
        property color _text: pal.colorOnSurface
        property color _icon: pal.primary
        delegate: Rectangle {
            id: wsWin
            required property int index
            property var modelData: ({ cls: "", title: "" })
            property bool alive: false
            property bool snap: true
            z: alive ? 10 + index : 5
            opacity: alive ? 1 : 0
            visible: opacity > 0.01
            Behavior on opacity { enabled: !wsWin.snap; M3NumberAnim { duration: wsWin.alive ? 160 : 340 } }
            Behavior on x      { enabled: !wsWin.snap; SpringAnimation { spring: 3.0; damping: 0.2; mass: 0.9; epsilon: 0.2 } }
            Behavior on y      { enabled: !wsWin.snap; SpringAnimation { spring: 3.0; damping: 0.2; mass: 0.9; epsilon: 0.2 } }
            Behavior on width  { enabled: !wsWin.snap; SpringAnimation { spring: 2.6; damping: 0.18; mass: 0.9; epsilon: 0.2 } }
            Behavior on height { enabled: !wsWin.snap; SpringAnimation { spring: 2.6; damping: 0.18; mass: 0.9; epsilon: 0.2 } }
            function place(r, animate) {
                snap = !animate;
                x = r.x; y = r.y; width = Math.max(1, r.w); height = Math.max(1, r.h);
                snap = false;
            }
            radius: Math.max(0, Math.min(8, Math.min(width, height) / 3))
            color: globalState.glassMode ? ga(wsPreviewRepeater._win, 0.85) : wsPreviewRepeater._win
            border.width: 1
            border.color: wsPreviewRepeater._border

            readonly property string qsApp: globalState.internalAppForClient(modelData.cls, modelData.title)
            readonly property string iconPath: (modelData.cls && qsApp === "") ? globalState.windowIconFor(modelData.cls) : ""
            Column {
                anchors.centerIn: parent
                width: parent.width - 8
                spacing: 2
                visible: wsWin.width > 16 && wsWin.height > 16
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    readonly property real sz: Math.max(8, Math.min(26, Math.min(wsWin.width, wsWin.height) * 0.42))
                    width: sz; height: sz
                    InternalAppIcon {
                        anchors.fill: parent
                        visible: wsWin.qsApp !== ""
                        glyph: globalState.internalAppGlyph(wsWin.qsApp)
                    }
                    Image {
                        sourceSize: Qt.size(96, 96)
                        anchors.fill: parent
                        visible: wsWin.iconPath !== ""
                        source: wsWin.iconPath !== "" ? ("file://" + wsWin.iconPath) : ""
                        fillMode: Image.PreserveAspectFit
                        smooth: true; mipmap: true
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: wsWin.iconPath === "" && wsWin.qsApp === ""
                        text: (wsWin.modelData.cls || "?").charAt(0).toUpperCase()
                        font.family: globalState.fontSecondary; font.pixelSize: parent.sz * 0.7; font.bold: true
                        color: wsPreviewRepeater._icon
                    }
                }
                Text {
                    width: parent.width
                    visible: wsWin.height > 44 && wsWin.width > 50
                    horizontalAlignment: Text.AlignHCenter
                    text: wsWin.modelData.title || wsWin.modelData.cls || ""
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale)
                    color: wsPreviewRepeater._text
                    elide: Text.ElideRight
                }
            }
        }
    }
}
