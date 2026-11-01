import QtQuick
import QtQuick.Layouts
import "../ui"
import "../widgets"

// Liquid-gauge metric widget (cpu / ram / disk) of the desktop layer
DesktopWidgetFrame {
    id: mgw
    dragging: dragArea.drag.active
    property string key: ""
    property real percent: 0
    property string shapePath: ""
    property real gw: 80
    property real gh: 80
    property real gx: 10
    property real gy: 10
    dwOn: globalState[key + "WidgetEnabled"]
    x: globalState[key + "WidgetX"]
    y: globalState[key + "WidgetY"]
    width:  Math.ceil((220 * globalState[key + "WidgetScale"]) / desktopWidgetLayer.gridCell) * desktopWidgetLayer.gridCell
    height: Math.ceil((220 * globalState[key + "WidgetScale"]) / desktopWidgetLayer.gridCell) * desktopWidgetLayer.gridCell

    MouseArea {
        id: dragArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: { if (!globalState.desktopEditMode) desktopWidgetMenu.openFor(mgw, mgw.key); }
    }

    Loader {
        id: vis
        anchors.fill: parent
        anchors.margins: desktopWidgetLayer.widgetGap
        active: mgw.visible
        sourceComponent: Component {
            Item {
                anchors.fill: parent
                ShapeGauge {
                    readonly property real fk: Math.min(parent.width / mgw.gw, parent.height / mgw.gh)
                    width: 100 * fk; height: 100 * fk
                    x: (parent.width - mgw.gw * fk) / 2 - mgw.gx * fk
                    y: (parent.height - mgw.gh * fk) / 2 - mgw.gy * fk
                    glassEmpty: false
                    waveEffect: true
                    wavePhase: desktopWidgetLayer.desktopGaugeWavePhase
                    pct: mgw.percent / 100
                    shapePath: mgw.shapePath
                    fillColor: pal.primary
                    emptyColor: globalState.glassMode ? ga(containerDark(pal.secondaryCont), currentFrameOpacity()) : containerDark(pal.secondaryCont)
                    outlineColor: "transparent"
                }
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2
                    Text { Layout.alignment: Qt.AlignHCenter; text: tr(mgw.key + "_lbl"); font.family: globalState.fontSecondary; font.pixelSize: Math.max(10, Math.round(parent.parent.width * 0.085 * globalState.fontScale)); font.weight: Font.DemiBold; color: mgw.percent >= 64 ? pal.colorOnPrimary : pal.colorOnSurfVar }
                    Text { Layout.alignment: Qt.AlignHCenter; text: mgw.percent + "%"; font.family: globalState.fontPrimary; font.pixelSize: Math.max(16, Math.round(parent.parent.width * 0.21 * globalState.fontScale)); font.weight: Font.Black; color: mgw.percent >= 50 ? pal.colorOnPrimary : pal.colorOnSurface }
                }
            }
        }
    }
}
