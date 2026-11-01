import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"
import "WidgetTypes.js" as WT

// Desktop popups: widget context menu, desktop editor and resize overlay
PanelWindow {
    id: desktopPopupsWindow
    property alias desktopEditorPopup: desktopEditorPopup
    property alias desktopResizeOverlay: desktopResizeOverlay
    property alias desktopWidgetMenu: desktopWidgetMenu
    WlrLayershell.namespace: "quickshell:toasts"
    readonly property bool popupsNeeded: desktopWidgetMenu.targetItem !== null
    || globalState.desktopEditMode
    || globalState.desktopEditPrep
    || desktopResizeOverlay.active
    readonly property bool fullSized: width > 100 && height > 100
    function tryCommitEdit() {
        if (globalState.desktopEditPrep && fullSized) Qt.callLater(globalState.commitDesktopEditEnter);
    }
    onFullSizedChanged: tryCommitEdit()
    Connections {
        target: globalState
        function onDesktopEditPrepChanged() {
            if (globalState.desktopEditPrep) { desktopPopupsWindow.tryCommitEdit(); editPrepFallback.restart(); }
            else editPrepFallback.stop();
        }
    }
    Timer { id: editPrepFallback; interval: 250; onTriggered: globalState.commitDesktopEditEnter() }
    anchors.top:    true
    anchors.left:   true
    anchors.bottom: true
    anchors.right:  true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: true

    DesktopWidgetMenu { id: desktopWidgetMenu }

    Item {
        id: desktopEditorPopup
        anchors.fill: parent
        z: 997
        visible: globalState.desktopEditMode

        property string selectedType: ""
        property string _pendingType: ""
        property string openSection: "widgets"
        onVisibleChanged: if (!visible) { selectedType = ""; _pendingType = ""; }
        function openWidgetConfig(type) {
            _pendingType = type;
            widgetConfigOpenTimer.restart();
        }
        Timer {
            id: widgetConfigOpenTimer
            interval: 280
            onTriggered: {
                if (globalState.desktopEditMode && desktopEditorPopup._pendingType !== "")
                desktopEditorPopup.selectedType = desktopEditorPopup._pendingType;
                desktopEditorPopup._pendingType = "";
            }
        }
        Connections {
            target: globalState
            function onDesktopEditModeChanged() { if (!globalState.desktopEditMode) desktopEditorPopup.selectedType = ""; }
        }

        property var widgetList: WT.pickerOrder.map(function (t) { return { type: t, enabledProp: WT.prop(t, "Enabled") }; })

        Loader {
            anchors.fill: parent
            active: desktopEditorPopup.visible
            source: Qt.resolvedUrl("DesktopEditorContent.qml")
        }
    }

    mask: Region {
        item: desktopWidgetMenu.targetItem !== null ? desktopWidgetMenu : null
        Region { item: desktopEditorPopup.visible ? desktopEditorPopup : null }
        Region { item: desktopResizeOverlay.active ? desktopResizeOverlay : null }
    }

    DesktopResizeOverlay { id: desktopResizeOverlay }
}
