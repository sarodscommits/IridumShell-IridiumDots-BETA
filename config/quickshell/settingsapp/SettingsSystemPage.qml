import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import ".."
import "../ui"

// Settings: system page (grid of primary cards)
Item {
    id: settingsSystemPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "system"
    readonly property bool wide: width >= 760
    // Columns of the resolution/refresh pills, from a stable ancestor width (not the layout being resolved)
    readonly property int pillCols: Math.max(3, Math.min(7, Math.floor((width - 150) / 100)))

    SystemDisplayLogic { id: sysDisplay }
    SystemPerfLogic { id: sysPerf }
    property alias displayLogic: sysDisplay

    function refreshAll() {
        sysDisplay.refresh();
        sysPerf.refresh();
        if (!fetchProcess.running) fetchProcess.running = true;
    }
    onVisibleChanged: if (visible) refreshAll()
    Component.onCompleted: if (visible) refreshAll()

    ScrollView {
        id: systemScrollView
        anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
        anchors.leftMargin: 24; anchors.topMargin: 24; anchors.bottomMargin: 24
        width: parent.width - 36
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: systemScrollView.availableWidth
            spacing: 16

            SystemHeroCard {}

            GridLayout {
                Layout.fillWidth: true
                columns: settingsSystemPage.wide ? 2 : 1
                columnSpacing: 16
                rowSpacing: 16

                SystemDisplayCard {
                    Layout.columnSpan: settingsSystemPage.wide ? 2 : 1
                    logic: sysDisplay
                    cols: settingsSystemPage.pillCols
                }
                SystemPerfCard { logic: sysPerf }
                SystemHardwareCard {}
                SystemSoftwareCard {}
                SystemSessionCard {}
            }
        }
    }
}
