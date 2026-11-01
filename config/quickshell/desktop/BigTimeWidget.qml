import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../widgets"

// Large time desktop widget
ExprDesktopWidget {
    id: bigTimeWidgetRoot
    wType: "bigtime"
    enabledProp: "bigTimeWidgetEnabled"; xProp: "bigTimeWidgetX"; yProp: "bigTimeWidgetY"; scaleProp: "bigTimeWidgetScale"
    baseW: 220; baseH: 220
    face: Component {
        Item {
            id: btFace
            readonly property real u: width / 220
            property var now: new Date()
            Timer {
                interval: 1000; running: bigTimeWidgetRoot.live; repeat: true; triggeredOnStart: true
                onTriggered: {
                    var d = new Date();
                    if (d.getMinutes() !== btFace.now.getMinutes() || d.getHours() !== btFace.now.getHours()) {
                        btFace.now = d;
                        btSpin.target += 45;
                    }
                }
            }
            Spring { id: btSpin; target: 0; token: "spatialSlow"; eps: 0.05 }
            readonly property string hh: {
                var h = now.getHours();
                if (!globalState.clockFormat24h) { h = h % 12; if (h === 0) h = 12; }
                return (h < 10 ? "0" : "") + h;
            }
            readonly property string mm: (now.getMinutes() < 10 ? "0" : "") + now.getMinutes()
            MBox {
                anchors.fill: parent
                from: "Flower"
                rot: btSpin.value
                fill: desktopWidgetLayer.exprDark
                split: 0.8
                fill2: m3.primaryContainer
            }
            Column {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -4 * btFace.u
                spacing: -18 * btFace.u
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: btFace.hh
                    font.family: globalState.fontPrimary; font.pixelSize: Math.max(14, Math.round(66 * btFace.u)); font.weight: Font.Black
                    color: m3.primary
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: btFace.mm
                    font.family: globalState.fontPrimary; font.pixelSize: Math.max(14, Math.round(66 * btFace.u)); font.weight: Font.Black
                    color: pal.colorOnSurface
                }
            }
        }
    }
}
