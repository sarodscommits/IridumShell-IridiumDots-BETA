import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "WidgetTypes.js" as WT

// Right-click context menu of desktop widgets
Item {
    id: desktopWidgetMenu
    anchors.fill: parent
    z: 998
    visible: targetItem !== null

    property Item targetItem: null
    property string widgetType: ""

    function openFor(item, type) {
        targetItem = item;
        widgetType = type;
    }
    function close() {
        targetItem = null;
        widgetType = "";
    }
    function enabledPropFor(type) { return WT.prop(type, "Enabled"); }
    readonly property var widgetFamilies: ({
        music:   { base: "widget_name_music",    types: ["music", "mediapill"] },
        weather: { base: "widget_name_weather",  types: ["weather", "weatherDetail", "wpills"] },
        clock:   { base: "widget_name_clock",    types: ["clock", "clockDetail", "bigtime"] },
        cal:     { base: "widget_name_calendar", types: ["calendar", "calDetail", "date", "countdown"] },
        lyrics:  { base: "lyrics_title",         types: ["lyrcard", "lyrline", "lyrbubble"] }
    })
    function titleFor(type) {
        for (var k in widgetFamilies) {
            var fam = widgetFamilies[k], i = fam.types.indexOf(type);
            if (i >= 0) return tr(fam.base) + " " + (i + 1);
        }
        if (["cpu", "ram", "disk", "sys", "gpu", "charge"].indexOf(type) >= 0) return tr("widget_name_" + type);
        return "";
    }
    function scalePropFor(type) { return WT.prop(type, "Scale"); }
    function widthPropFor(type) { return WT.prop(type, "W"); }
    function heightPropFor(type) { return WT.prop(type, "H"); }
    function xPropFor(type) { return WT.prop(type, "X"); }
    function yPropFor(type) { return WT.prop(type, "Y"); }
    property var settingsMap: ({
        music: [
        { label: tr("desktop_setting_show_album_art"),    prop: "musicShowAlbumArt" },
        { label: tr("desktop_setting_show_progress_bar"), prop: "musicShowProgressBar" },
        { label: tr("desktop_setting_compact_mode"),      prop: "musicCompactMode" }
        ],
        weather: [
        { label: tr("feels_like"), prop: "weatherShowFeelsLike" },
        { label: tr("humidity"),   prop: "weatherShowHumidity" },
        { label: tr("wind"),       prop: "weatherShowWind" }
        ],
        clock: [
        { label: tr("desktop_setting_clock_hands"),   prop: "clockShowHandsDesktop" },
        { label: tr("desktop_setting_clock_numbers"), prop: "clockShowNumbersDesktop" },
        { label: tr("desktop_setting_clock_circle"),  prop: "clockCircleStyleDesktop" }
        ],
        calendar: [
        { label: tr("desktop_setting_cal_day_month"), prop: "calShowDayMonth" },
        { label: tr("desktop_setting_cal_year"),       prop: "calShowYear" }
        ]
    })

    MouseArea {
        anchors.fill: parent
        onClicked: desktopWidgetMenu.close()
    }

    Rectangle {
        id: desktopWidgetMenuCard
        x: {
            if (!desktopWidgetMenu.targetItem) return 0;
            var t = desktopWidgetMenu.targetItem;
            var raw = t.x + t.width + 12;
            return Math.max(8, Math.min(raw, desktopPopupsWindow.width - width - 8));
        }
        y: {
            if (!desktopWidgetMenu.targetItem) return 0;
            var t = desktopWidgetMenu.targetItem;
            return Math.max(8, Math.min(t.y, desktopPopupsWindow.height - height - 8));
        }
        width: 260
        height: desktopWidgetMenuColumn.implicitHeight + 24
        radius: 20
        color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.72) : containerDark(pal.secondaryCont)

        MouseArea { anchors.fill: parent }

        ColumnLayout {
            id: desktopWidgetMenuColumn
            anchors.fill: parent
            anchors.margins: 12
            spacing: 2

            Text {
                Layout.bottomMargin: 8
                text: desktopWidgetMenu.titleFor(desktopWidgetMenu.widgetType)
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(16 * globalState.fontScale); font.weight: Font.Bold
                color: pal.colorOnSurface
            }

            Repeater {
                id: desktopWidgetMenuActions
                property color btnColor:  globalState.glassMode ? ga(pal.surface, 0.6) : pal.surface
                property color btnHover:  globalState.glassMode ? ga(pal.surfaceVar, 0.7) : pal.surfaceVar
                property color txtColor:  pal.colorOnSurface
                property color iconColor: pal.primary
                model: [
                { key: "mode",   icon: "\ue3c9", label: tr("desktop_widget_edit_mode") },
                { key: "widget", icon: "\ue8b8", label: tr("desktop_widget_edit_widget") }
                ]
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool first: index === 0
                    readonly property bool last: index === desktopWidgetMenuActions.count - 1
                    property real r: dwmActHov.hovered ? 19 : 4
                    Behavior on r { M3SpringAnim { token: "spatialFast" } }
                    Layout.fillWidth: true
                    height: 44
                    topLeftRadius: first ? 18 : r; topRightRadius: first ? 18 : r
                    bottomLeftRadius: last ? 18 : r; bottomRightRadius: last ? 18 : r
                    color: dwmActHov.hovered ? Qt.tint(desktopWidgetMenuActions.btnColor, Qt.rgba(desktopWidgetMenuActions.txtColor.r, desktopWidgetMenuActions.txtColor.g, desktopWidgetMenuActions.txtColor.b, 0.08)) : desktopWidgetMenuActions.btnColor
                    Behavior on color { M3ColorAnim { duration: m3.durFast } }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12; anchors.rightMargin: 12
                        spacing: 10
                        Text {
                            text: modelData.icon
                            font.family: "Material Symbols Rounded"; font.pixelSize: 18
                            color: desktopWidgetMenuActions.iconColor
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.label
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale)
                            color: desktopWidgetMenuActions.txtColor
                            elide: Text.ElideRight
                        }
                    }
                    HoverHandler { id: dwmActHov }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var ty = desktopWidgetMenu.widgetType;
                            desktopWidgetMenu.close();
                            if (!globalState.desktopEditMode) globalState.toggleDesktopEditMode();
                            if (modelData.key === "widget") desktopEditorPopup.openWidgetConfig(ty);
                        }
                    }
                }
            }
        }
    }
}
