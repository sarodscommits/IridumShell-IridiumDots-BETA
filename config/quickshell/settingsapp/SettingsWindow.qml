import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"
import "../panels"

// Settings app window (one instance per window; inst 0 is the main one)
Window {
    id: settingsWindow
    property int inst: (typeof winId === "number") ? winId : 0
    property bool extraOpen: true
    property string extraSection: "home"
    readonly property bool winOpen: inst === 0 ? globalState.settingsOpen : extraOpen
    readonly property string section: inst === 0 ? globalState.settingsSection : extraSection
    function setSection(v) { if (inst === 0) globalState.settingsSection = v; else extraSection = v; }
    function closeWin() {
        if (inst === 0) { globalState.settingsOpen = false; return; }
        extraOpen = false;
        var n = inst;
        Qt.callLater(function() { globalState.closeAppExtra("settings", n); });
    }
    title:   "Iridum Settings"
    visible: winOpen
    color:   "transparent"
    width:   1100
    height:  800
    minimumWidth:  700
    minimumHeight: 500

    onClosing: (close) => { settingsWindow.closeWin(); }
    onVisibleChanged: if (!visible && settingsWindow.winOpen) settingsWindow.closeWin()

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (globalState.wpDeleteConfirm !== "")
            globalState.wpDeleteConfirm = "";
            else if (globalState.wpImportOpen && globalState.wpImportState !== "picking" && globalState.wpImportState !== "copying")
            globalState.wpImportOpen = false;
            else if (!globalState.wpImportOpen && settingsWindow.section !== "home")
            settingsWindow.setSection("home");
            else if (!globalState.wpImportOpen)
            settingsWindow.closeWin();
        }
    }

    Rectangle {
        id: settingsPopup
        anchors.fill: parent
        radius: 0
        color: globalState.glassMode ? ga(pal.surfaceElevated, 0.6) : pal.surfaceElevated
        Behavior on color { M3ColorAnim {} }
        clip:   true

        MouseArea {
            anchors.fill: parent
            onWheel: (event) => {
                if (settingsPopup.activeSection === "wallpaper") {
                    const maxY = Math.max(0, settingsAppearancePage.appearanceFlick.contentHeight - settingsAppearancePage.appearanceFlick.height);
                    const step = (event.angleDelta.y / 120) * 48;
                    settingsAppearancePage.appearanceFlick.contentY = Math.max(0, Math.min(settingsAppearancePage.appearanceFlick.contentY - step, maxY));
                }
            }
        }

        readonly property string activeSection: settingsWindow.section

        Connections {
            target: globalState
            function onSettingsWpBrowseChanged() { if (globalState.settingsWpBrowse) settingsAppearancePage.appearanceFlick.contentY = 0; }
        }
        Component.onCompleted: if (globalState.settingsWpBrowse) settingsAppearancePage.appearanceFlick.contentY = 0

        property var sections: [
        { id: "home",             icon: "\ue1bd", label: tr("sd_home"),       sub: tr("set_sub_home")        },
        { id: "wallpaper",        icon: "\ue3f4", label: tr("settings_section_wallpaper"), sub: tr("set_sub_wallpaper"), group: "personal", gap: true },
        { id: "color",            icon: "\ue3b7", label: tr("sd_color"),      sub: tr("set_sub_color"),       group: "personal" },
        { id: "type",             icon: "\ue262", label: tr("sd_type"),       sub: tr("set_sub_type"),        group: "personal" },
        { id: "shapes",           icon: "\ue836", label: tr("sd_shapes"),     sub: tr("set_sub_shapes"),      group: "personal" },
        { id: "motion",           icon: "\ue71c", label: tr("sd_motion"),     sub: tr("set_sub_motion"),      group: "personal" },
        { id: "components",       icon: "\ue429", label: tr("sd_components"), sub: tr("set_sub_components"),  group: "personal" },
        { id: "bar",              icon: "\ue9b7", label: tr("settings_section_bar"),        sub: tr("set_sub_bar"),     group: "desktop", gap: true },
        { id: "windows",          icon: "\uf088", label: tr("settings_section_windows"),    sub: tr("set_sub_windows"), group: "desktop" },
        { id: "sound",            icon: "\ue894", label: tr("settings_section_sound_lang"), sub: tr("set_sub_sound"),   group: "desktop" },
        { id: "keyboard",         icon: "\ue312", label: tr("sd_keyboard"),   sub: tr("set_sub_keyboard"),    group: "desktop" },
        { id: "connections",      icon: "\ueb55", label: tr("connections"),   sub: tr("set_sub_connections"), group: "system", gap: true },
        { id: "infinite desktop", icon: "\ue871", label: tr("canvas"),        sub: tr("set_sub_canvas"),      group: "system" },
        { id: "screen record",    icon: "\ue04b", label: tr("screen_record"), sub: tr("set_sub_record"),      group: "system" },
        { id: "gaming hub",       icon: "\uea28", label: tr("gaming_hub"),    sub: tr("set_sub_gaming"),      group: "system" },
        { id: "power",            icon: "\ue8ac", label: tr("sd_power"),      sub: tr("set_sub_power"),       group: "system" },
        { id: "system",           icon: "\ue30a", label: tr("system"),        sub: tr("set_sub_system"),      group: "system" }
        ]

        readonly property var groupDefs: [
        { key: "personal", title: tr("set_group_personal"), sub: tr("set_group_personal_d") },
        { key: "desktop",  title: tr("set_group_desktop"),  sub: tr("set_group_desktop_d")  },
        { key: "system",   title: tr("set_group_system"),   sub: tr("set_group_system_d")   }
        ]
        function groupTitle(k) {
            for (var i = 0; i < groupDefs.length; i++) if (groupDefs[i].key === k) return groupDefs[i].title;
            return "";
        }
        function sectionById(id) {
            for (var i = 0; i < sections.length; i++) if (sections[i].id === id) return sections[i];
            return null;
        }
        function sectionsInGroup(k) {
            return sections.filter(function(s) { return s.group === k; });
        }
        function goHome() { settingsWindow.setSection("home"); }
        function sectionSummary(id) {
            switch (id) {
                case "wallpaper": {
                    var e = globalState.currentWallpaperEntry;
                    return e ? e.name + (e.animated ? " · " + globalState.wallpaperFpsLimit + " fps" : "") : tr("set_sub_wallpaper");
                }
                case "color": return (globalState.paletteSource === "preset" ? tr("palette_source_preset") : tr("palette_source_matugen")) + " · " + (globalState.colorMode === "light" ? tr("light") : tr("dark")) + (globalState.glassMode ? " · " + tr("glass_mode") : "");
                case "type": return globalState.fontPrimary + " · " + globalState.fontSecondary + " · " + Math.round(globalState.fontScale * 100) + " %";
                case "shapes": return m3.accentShape + " · " + tr("sd_corners") + " ×" + m3.cornerScale.toFixed(1);
                case "motion": return (m3.expressive ? tr("motion_expressive") : tr("motion_standard")) + " · ×" + m3.speed.toFixed(2) + " · " + tr("sd_bounce").toLowerCase() + " ×" + m3.bounce.toFixed(2);
                case "components": return (m3.wavy ? tr("sd_wavy_on") : tr("sd_wavy_off")) + " · " + tr("sd_thickness").toLowerCase() + " " + m3.progressThickness + " px";
                case "bar": { var bm = 0; for (var k in globalState.barModules) if (globalState.barModules[k]) bm++; return (globalState.shellMode === "notch" ? tr("shell_mode_notch") : tr("shell_mode_island")) + " · " + bm + " " + tr("bar_modules").toLowerCase(); }
                case "windows": return tr("border_size") + " " + globalState.borderSize + " px · " + tr("corner_rounding") + " " + globalState.cornerRounding + " px";
                case "sound": {
                    var ln = globalState.language;
                    for (var i = 0; i < i18n.languages.length; i++) if (i18n.languages[i].code === globalState.language) { ln = i18n.languages[i].name; break; }
                    return ln + " · " + (globalState.clockFormat24h ? "24h" : "12h") + " · " + tr("notification_sound_volume").toLowerCase() + " " + Math.round(globalState.notificationSoundVolume) + " %";
                }
                case "keyboard": return kbCurLayout === "" ? tr("set_sub_keyboard") : kbLayoutDesc(kbCurLayout) + (kbCurVariant !== "" ? " · " + kbVariantDesc(kbCurLayout, kbCurVariant) : "") + (kbHyprBinds.length ? " · " + (kbHyprBinds.length + kbInfiniteBinds.length) + " " + tr("kb_sc_title").toLowerCase() : "");
                case "system": return [globalState.fetchOS, globalState.fetchDisplay].filter(function (v) { return v !== ""; }).join(" · ") || tr("set_sub_system");
                case "power": return globalState.powerConfirmEnabled ? tr("power_confirm_seconds") + " " + globalState.powerConfirmSeconds + " s" : tr("set_sub_power");
                default: { var s = sectionById(id); return s ? s.sub : ""; }
            }
        }

        property bool railExpanded: false


        Item {
            anchors.top:    parent.top
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom

            SettingsSidebar { id: settingsSidebar }

            Rectangle {
                id: settingsPane
                x: settingsSidebar.width
                y: 12
                width: parent.width - settingsSidebar.width - 12
                height: parent.height - 24
                radius: m3.corner(32)
                color: globalState.glassMode ? ga(pal.surface, 0.7) : pal.surface
                Behavior on color { ColorAnimation { duration: m3.durDefault } }

                SettingsHeader { id: settingsHeader }
            }

            Item {
                id: settingsContent
                x: settingsPane.x
                y: settingsPane.y + settingsHeader.anchors.topMargin + settingsHeader.height
                width:  settingsPane.width
                height: settingsPane.height - settingsHeader.anchors.topMargin - settingsHeader.height
                clip: true
                Spring { id: setPgY; target: 0; token: "spatialDefault"; eps: 0.05 }
                Spring { id: setPgO; target: 1; token: "effectsDefault" }
                Connections {
                    target: globalState
                    function onSettingsSectionChanged() { setPgY.snap(48); setPgY.target = 0; setPgO.snap(0); setPgO.target = 1; }
                }
                opacity: Math.max(0, Math.min(1, setPgO.value))
                transform: Translate { y: setPgY.value }


                SettingsHomePage { id: sdHomePage }

                SettingsColorPage { id: sdColorPage }

                SettingsTypePage { id: sdTypePage }

                SettingsShapesPage { id: sdShapesPage }

                SettingsMotionPage { id: sdMotionPage }

                SettingsComponentsPage { id: sdCompPage }

                SettingsAppearancePage { id: settingsAppearancePage }

                SettingsBarPage { id: sdBarPage }

                SettingsWindowsPage { id: sdWindowsPage }

                SettingsSoundPage { id: sdSoundPage }


                SettingsConnectionsPage { id: settingsConnectionsPage }


                SettingsGamingPage { id: settingsGamingPage }

                SettingsRecordingPage { id: settingsRecordingPage }

                SettingsDesktopPage { id: settingsDesktopPage }

                SettingsKeyboardPage { id: kbPage }

                SettingsPowerPage { id: settingsPowerPage }

                SettingsSystemPage { id: settingsSystemPage }
            }
        }

        Item {
            id: wpImportLayer
            anchors.fill: parent
            z: 150
            readonly property bool shown: globalState.wpImportOpen || globalState.wpImportDragHover
            readonly property bool busy:  globalState.wpImportState === "picking" || globalState.wpImportState === "copying"
            readonly property bool hot:   globalState.wpImportDragHover
            visible: opacity > 0.01
            opacity: shown ? 1 : 0
            Behavior on opacity { M3NumberAnim {} }

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.55
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.AllButtons
                onClicked: if (!wpImportLayer.busy) globalState.wpImportOpen = false
                onWheel: (wheel) => { wheel.accepted = true; }
            }

            Rectangle {
                id: wpImportCard
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, 560)
                height: wpImportCol.implicitHeight + 64
                radius: 28
                color: globalState.glassMode ? ga(pal.surfaceHigh, 0.92) : pal.surfaceHigh
                scale: wpImportLayer.shown ? (wpImportLayer.hot ? 1.03 : 1) : 0.94
                Behavior on scale { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
                Behavior on height { M3SpringAnim { token: "spatialDefault" } }

                MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (wheel) => { wheel.accepted = true; } }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 12
                    radius: 20
                    color: pal.primary
                    opacity: wpImportLayer.hot ? 0.12 : 0
                    Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
                }

                Canvas {
                    id: wpImportDash
                    anchors.fill: parent
                    anchors.margins: 12
                    property color lineColor: wpImportLayer.hot ? pal.primary : pal.muted
                    property bool solid: wpImportLayer.hot
                    onLineColorChanged: requestPaint()
                    onSolidChanged: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = lineColor;
                        ctx.lineWidth = solid ? 2.5 : 2;
                        ctx.setLineDash(solid ? [] : [10, 7]);
                        var r = 20, w = width - 2, h = height - 2;
                        ctx.beginPath();
                        ctx.roundedRect(1, 1, w, h, r, r);
                        ctx.stroke();
                    }
                }

                Rectangle {
                    anchors.top: parent.top; anchors.right: parent.right
                    anchors.topMargin: 22; anchors.rightMargin: 22
                    width: 32; height: 32; radius: m3Ib32Ma.pressed ? Math.max(4, (16) * 0.5) : (16)
                    Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                    visible: !wpImportLayer.busy
                    color: wpImportCloseHov.hovered ? pal.surfaceVar : "transparent"
                    Behavior on color { M3ColorAnim { duration: m3.durFast } }
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Material Symbols Rounded"; font.pixelSize: 18
                        color: pal.colorOnSurfVar
                    }
                    HoverHandler { id: wpImportCloseHov; cursorShape: Qt.PointingHandCursor }
                    MouseArea { id: m3Ib32Ma; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: globalState.wpImportOpen = false }
                }

                SettingsWallpaperImport { id: wpImportCol }
            }
        }

        DropArea {
            id: wpImportDropArea
            anchors.fill: parent
            z: 200
            onEntered: (drag) => {
                if (!drag.hasUrls || wpImportProcess.running) { drag.accepted = false; return; }
                drag.accept(Qt.CopyAction);
                globalState.wpImportDragHover = true;
            }
            onExited: globalState.wpImportDragHover = false
            onDropped: (drop) => wpImportHandleDrop(drop)
        }
    }
}
