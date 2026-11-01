import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../desktop/WidgetTypes.js" as WT

// Per-widget settings panel shown next to the selected widget in edit mode
PanelWindow {
    id: desktopWidgetConfigWindow
    WlrLayershell.namespace: "quickshell:toasts"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: globalState.desktopEditMode && desktopEditorPopup.selectedType !== ""
    mask: Region { item: wcfgCard }

    readonly property string wType: desktopEditorPopup.selectedType
    readonly property Item wItem: {
        var n = WT.rootName(wType);
        return n ? desktopWidgetLayer[n] : null;
    }
    readonly property real _sc: desktopWidgetLayer.editPreviewScale
    readonly property real _wx: wItem ? desktopWidgetLayer.editPreviewBoxX + wItem.x * _sc : 0
    readonly property real _wy: wItem ? desktopWidgetLayer.editPreviewBoxY + wItem.y * _sc : 0
    readonly property real _ww: wItem ? wItem.width  * _sc : 0
    readonly property real _wh: wItem ? wItem.height * _sc : 0

    readonly property var wSettings: desktopWidgetMenu.settingsMap[wType] || []

    Rectangle {
        id: wcfgCard
        width: 264
        height: wcfgCol.implicitHeight + 28
        radius: 22
        x: {
            var w = desktopWidgetConfigWindow;
            var right = w._wx + w._ww + 16;
            var raw = (right + width <= w.width - 8) ? right : (w._wx - width - 16);
            return Math.max(8, Math.min(raw, w.width - width - 8));
        }
        y: Math.max(8, Math.min(desktopWidgetConfigWindow._wy, desktopWidgetConfigWindow.height - height - 8))
        property bool posAnimReady: false
        readonly property bool shown: desktopWidgetConfigWindow.visible && desktopWidgetConfigWindow.width > 100
        onShownChanged: {
            if (shown) { posAnimReady = false; wcfgEnter.restart(); wcfgPosReadyTimer.restart(); }
            else { wcfgPosReadyTimer.stop(); posAnimReady = false; }
        }
        Timer { id: wcfgPosReadyTimer; interval: 60; onTriggered: wcfgCard.posAnimReady = true }
        Behavior on x { enabled: wcfgCard.posAnimReady; M3SpringAnim { token: "spatialDefault" } }
        Behavior on y { enabled: wcfgCard.posAnimReady; M3SpringAnim { token: "spatialDefault" } }
        color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.85) : containerDark(pal.secondaryCont)
        border.width: 1
        border.color: ga(pal.primary, 0.35)

        property real enterOffset: 0
        transform: Translate { y: wcfgCard.enterOffset }
        opacity: shown ? 1 : 0
        ParallelAnimation {
            id: wcfgEnter
            NumberAnimation { target: wcfgCard; property: "enterOffset"; from: desktopWidgetLayer.editMenuSlideFrom * 0.7; to: 0; duration: 360; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }
        }
        Behavior on opacity { M3NumberAnim { duration: m3.durFast } }

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: wcfgCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: ""
                    font.family: "Material Symbols Rounded"; font.pixelSize: 18
                    color: pal.primary
                }
                Text {
                    Layout.fillWidth: true
                    text: desktopWidgetMenu.titleFor(desktopWidgetConfigWindow.wType)
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.Bold
                    color: pal.colorOnSurface
                    elide: Text.ElideRight
                }
                PressIconButton {
                    width: 26
                    height: 26
                    cornerRadius: 13
                    icon: ""
                    iconSize: 16
                    iconColor: pal.colorOnSurfVar
                    hoverColor: ga(pal.colorOnSurfVar, 0.18)
                    idleColor: "transparent"
                    onClicked: desktopEditorPopup.selectedType = ""
                }
            }

            Text {
                Layout.fillWidth: true
                text: tr("desktop_widget_resize_hint")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                color: pal.muted
                wrapMode: Text.WordWrap
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: ga(pal.colorOnSurfVar, 0.2) }

            Text {
                visible: desktopWidgetConfigWindow.wSettings.length === 0
                Layout.fillWidth: true
                text: tr("desktop_widget_no_settings")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                color: pal.colorOnSurfVar
            }

            Repeater {
                id: wcfgSettingsRepeater
                property color textColor:     pal.colorOnSurface
                property color toggleOnColor:  pal.primary
                property color toggleOffColor: ga(pal.surfaceDeep, 0.5)
                model: desktopWidgetConfigWindow.wSettings
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        text: modelData.label
                        color: wcfgSettingsRepeater.textColor
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale)
                        elide: Text.ElideRight
                    }
                    ESwitch {
                        checked: globalState[modelData.prop]
                        scaleF: 0.75
                        onToggled: { globalState[modelData.prop] = !globalState[modelData.prop]; savePrefs(); }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: ga(pal.colorOnSurfVar, 0.2) }

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 12
                color: wcfgRemoveHov.hovered ? Qt.darker(pal.error, 1.6) : (globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface)
                Behavior on color { M3ColorAnim { duration: m3.durFast } }
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.error }
                    Text {
                        text: tr("desktop_widget_remove")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale)
                        color: pal.error
                    }
                }
                HoverHandler { id: wcfgRemoveHov }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var prop = desktopWidgetMenu.enabledPropFor(desktopWidgetConfigWindow.wType);
                        desktopEditorPopup.selectedType = "";
                        if (prop) { globalState[prop] = false; savePrefs(); }
                    }
                }
            }
        }
    }
}
