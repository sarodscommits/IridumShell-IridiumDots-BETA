import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../gaming"
import "../panels"
import "../ui"

// Gaming panel content: backdrop, cards and edge tab
Item {
    id: gmRoot
    readonly property Item panelItem: gmPanel
    readonly property Item colItem: gmCol
    readonly property Item floatRowItem: gmFloatRow
    readonly property Item tabItem: gmTab
    readonly property Item bgItem: gmBg
    width: parent.width; height: parent.height
    x: gamingWindow.floatX + (gamingWindow.prog - 1) * (gamingWindow.margin + gamingWindow.panelW + 30) - (1 - gamingWindow.modeFade) * 40
    y: gamingWindow.floatY
    opacity: Math.min(1, gamingWindow.prog * 1.6) * gamingWindow.modeFade

    GamingBackdrop { id: gmBg }

    Item {
        id: gmPanel
        x: gamingWindow.margin
        y: 12
        width: gamingWindow.panelW
        height: gmCol.implicitHeight + (gamingWindow.floatLayout ? 0 : 40)

        ColumnLayout {
            id: gmCol
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.margins: gamingWindow.floatLayout ? 0 : 20
            spacing: gamingWindow.floatLayout ? 8 : 16

            GamingHeader { id: gamingHeader }

            GamingFloatRow { id: gmFloatRow }

            GamingHero { id: gmHero }

            GamingActions { id: gmActions }

            GridLayout {
                readonly property var keys: gamingWindow.floatLayout
                ? globalState.gamingMetricKeys
                : globalState.gamingMetricKeys.filter(function (k) { return k !== "fps" && (!gamingWindow.modOn("rings") || (k !== "cpu" && k !== "gpu")); })
                visible: keys.length > 0
                Layout.fillWidth: true
                columns: 2
                columnSpacing: gamingWindow.floatLayout ? 8 : 12; rowSpacing: gamingWindow.floatLayout ? 8 : 12
                Repeater {
                    id: gmMetricRepeater
                    model: parent.keys
                    property color _card:     pal.surfaceElevated
                    property color _primary:  pal.primary
                    property color _onSurf:   pal.colorOnSurface
                    property color _onSurfVar: pal.colorOnSurfVar
                    property color _error:    pal.error
                    property color _accent:   pal.accent
                    property bool  _glass:    globalState.glassMode

                    delegate: GamingMetricCard { id: gmCard }
                }
            }

            GamingPerfCard { id: gmPerfCard }

            GamingSlidersCard { id: gamingSlidersCard }
        }
    }

    Rectangle {
        id: gmFloatRec
        readonly property bool wanted: gamingWindow.floatLayout && globalState.recActive
        x: gmPanel.x + gmCol.x + gmCol.width - width
        y: gmPanel.y + gmCol.y + gmFloatRow.y
        height: gmFloatRow.height
        width: gmFloatRecRow.implicitWidth + 26
        radius: height / 2
        color: ga(pal.surfaceElevated, gamingWindow.floatAlpha)
        opacity: wanted ? 1 : 0
        visible: opacity > 0.01
        scale: wanted ? 1 : 0.85
        Behavior on opacity { M3NumberAnim {} }
        Behavior on scale   { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }

        RowLayout {
            id: gmFloatRecRow
            anchors.centerIn: parent
            spacing: 8
            RecIndicator {
                size: 13
                running: gmFloatRec.wanted
            }
            Text {
                text: globalState.recSaving ? tr("rec_saving") : globalState.recFmt(globalState.recElapsedMs)
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
                color: globalState.recPaused ? pal.colorOnSurfVar : pal.colorOnSurface
            }
        }
    }

    GamingTab { id: gmTab }
}
