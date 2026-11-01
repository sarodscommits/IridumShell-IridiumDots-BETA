import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Side menu of the desktop editor
Rectangle {
    id: desktopEditorMainMenu
    transform: Translate { y: desktopWidgetLayer.editMenuOffset }
    opacity: desktopWidgetLayer.editEnterOpacity
    x: desktopWidgetLayer.editMenuOnRight ? previewBox.x + previewBox.width + 24 : previewBox.x - 24 - width
    property bool xAnimReady: false
    Component.onCompleted: Qt.callLater(function() { desktopEditorMainMenu.xAnimReady = true; })
    Behavior on x { enabled: desktopEditorMainMenu.xAnimReady && globalState.desktopEditMode; M3SpringAnim { token: "spatialSlow" } }
    anchors.top: desktopEditorTopBar.top
    width: 300
    height: Math.min(edmHeader.height + 32 + 14 + edmFlick.contentHeight + 12, desktopEditorPopup.height - y - 24)
    radius: 26
    clip: true
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.9) : containerDark(pal.secondaryCont)
    MouseArea { anchors.fill: parent }

    readonly property color cText:    pal.colorOnSurface
    readonly property color cSub:     pal.colorOnSurfVar
    readonly property color cMuted:   pal.mutedDeep
    readonly property color cOn:      pal.primary
    readonly property color cOnTxt:   pal.colorOnPrimary
    readonly property color cOff:     ga(pal.surfaceDeep, 0.55)
    readonly property color cSection: globalState.glassMode ? ga(pal.surface, 0.55) : pal.surface
    readonly property color cSectionHov: ga(pal.surfaceVar, 0.6)

    readonly property var widgetIcons: ({
        musicWidgetEnabled:         "",
        weatherWidgetEnabled:       "",
        clockWidgetEnabledDesktop:  "",
        calWidgetEnabledDesktop:    "",
        clockDetailWidgetEnabled:   "",
        weatherDetailWidgetEnabled: "",
        calDetailWidgetEnabled:     "",
        cpuWidgetEnabled:           "",
        ramWidgetEnabled:           "",
        diskWidgetEnabled:          "",
        sysWidgetEnabled: "\ue322",
        gpuWidgetEnabled: "\ue30d",
        chargeWidgetEnabled: "\ue1a3",
        dateWidgetEnabled: "\ue935",
        bigTimeWidgetEnabled: "\ue8b5",
        mediaPillWidgetEnabled: "\ue405",
        countdownWidgetEnabled: "\ue878",
        weatherPillsWidgetEnabled: "\uf172",
        lyricsCardWidgetEnabled: "lyrics",
        lyricsLineWidgetEnabled: "subtitles",
        lyricsBubbleWidgetEnabled: "bubble_chart"
    })
    readonly property var barModuleList: [
    { key: "control",    icon: "", label: tr("mod_control") },
    { key: "search",     icon: "", label: tr("mod_search") },
    { key: "workspaces", icon: "", label: tr("mod_workspaces") },
    { key: "windows",    icon: "", label: tr("mod_windows") },
    { key: "audio",      icon: "", label: tr("mod_audio") },
    { key: "clock",      icon: "", label: tr("mod_clock") },
    { key: "gaming",     icon: "\uea28", label: tr("mod_gaming") },
    { key: "clipboard",  icon: "", label: tr("mod_clipboard") },
    { key: "privacy",    icon: "", label: tr("mod_privacy") },
    { key: "notifications", icon: "", label: tr("mod_notifications") },
    { key: "wifi",       icon: "", label: tr("wifi") },
    { key: "bluetooth",  icon: "", label: tr("bluetooth") },
    { key: "battery",    icon: "", label: tr("mod_battery") },
    { key: "session",    icon: "", label: tr("mod_session") }
    ]

    function toggleSection(key, item) {
        desktopEditorPopup.openSection = desktopEditorPopup.openSection === key ? "" : key;
        if (desktopEditorPopup.openSection === key) {
            edmScrollTimer.target = item;
            edmScrollTimer.restart();
        }
    }
    Timer {
        id: edmScrollTimer
        property Item target: null
        interval: 340
        onTriggered: {
            if (!target) return;
            var maxY = Math.max(0, edmFlick.contentHeight - edmFlick.height);
            var top = target.y, bottom = target.y + target.height;
            var want = edmFlick.contentY;
            if (bottom > edmFlick.contentY + edmFlick.height) want = bottom - edmFlick.height;
            if (top < want) want = top;
            want = Math.max(0, Math.min(maxY, want));
            if (Math.abs(want - edmFlick.contentY) < 1) return;
            edmScrollAnim.to = want;
            edmScrollAnim.restart();
        }
    }
    NumberAnimation { id: edmScrollAnim; target: edmFlick; property: "contentY"; duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate }

    RowLayout {
        id: edmHeader
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 16
        spacing: 12
        Rectangle {
            Layout.preferredWidth: 42; Layout.preferredHeight: 42
            radius: 14
            color: desktopEditorMainMenu.cOn
            Text {
                anchors.centerIn: parent
                text: ""
                font.family: "Material Symbols Rounded"; font.pixelSize: 22
                color: desktopEditorMainMenu.cOnTxt
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
                Layout.fillWidth: true
                text: tr("desktop_widget_edit_mode")
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(17 * globalState.fontScale); font.weight: Font.Bold
                color: desktopEditorMainMenu.cText
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: tr("desktop_editor_subtitle")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                color: desktopEditorMainMenu.cSub
                elide: Text.ElideRight
            }
        }
        PressIconButton {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            cornerRadius: 17
            icon: ""
            iconSize: 20
            iconColor: desktopEditorMainMenu.cOn
            hoverColor: ga(desktopEditorMainMenu.cOn, 0.22)
            idleColor: "transparent"
            colorDuration: m3.durFast
            onClicked: globalState.toggleDesktopEditMode()
        }
    }

    Flickable {
        id: edmFlick
        anchors.top: edmHeader.bottom; anchors.topMargin: 14
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.leftMargin: 10; anchors.rightMargin: 10; anchors.bottomMargin: 10
        contentWidth: width
        contentHeight: edmCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        ColumnLayout {
            id: edmCol
            width: edmFlick.width
            spacing: 8

            EditorWidgetsSection { id: edmSecWidgets }

            EditorQuickSection { id: edmSecQuick }

            EditorBarSection { id: edmSecBar }

            EditorCavaSection { id: edmSecCava }
        }
    }
}
