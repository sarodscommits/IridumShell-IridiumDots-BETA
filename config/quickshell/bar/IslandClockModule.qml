import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

// Clock module of the island
Item {
    id: islandClockModule
    visible: globalState.barModules.clock
    implicitWidth: unifiedFrame.barVertical ? Math.max(28, vClockCol.implicitWidth) : islandClockCol.implicitWidth
    implicitHeight: unifiedFrame.barVertical ? vClockCol.implicitHeight + 4 : 28
    Layout.alignment: Qt.AlignCenter

    property string timeText: "--:--"
    property string dateText: ""
    property string vHour: "--"
    property string vMin: "--"
    property string vAmPm: ""
    function refresh() {
        var d = new Date();
        var h = d.getHours();
        var m = d.getMinutes();
        var mm = (m < 10 ? "0" : "") + m;
        islandClockModule.vMin = mm;
        if (globalState.clockFormat24h) {
            islandClockModule.vHour = (h < 10 ? "0" : "") + h;
            islandClockModule.vAmPm = "";
        } else {
            var vh12 = h % 12;
            if (vh12 === 0) vh12 = 12;
            islandClockModule.vHour = (vh12 < 10 ? "0" : "") + vh12;
            islandClockModule.vAmPm = h >= 12 ? "PM" : "AM";
        }
        if (globalState.clockFormat24h) {
            var hh = (h < 10 ? "0" : "") + h;
            islandClockModule.timeText = hh + ":" + mm;
        } else {
            var ampm = h >= 12 ? "PM" : "AM";
            var h12  = h % 12;
            if (h12 === 0) h12 = 12;
            islandClockModule.timeText = h12 + ":" + mm + " " + ampm;
        }
        islandClockModule.dateText = d.toLocaleDateString(Qt.locale(localeCode()), "d MMM");
    }
    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: islandClockModule.visible
        onTriggered: islandClockModule.refresh()
    }
    Connections {
        target: globalState
        function onClockFormat24hChanged() { islandClockModule.refresh(); }
    }

    Column {
        id: vClockCol
        visible: unifiedFrame.barVertical
        anchors.centerIn: parent
        spacing: -3
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: islandClockModule.vHour
            font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.Bold
            color: pal.colorOnSurface
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: islandClockModule.vMin
            font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.Medium
            color: pal.primary
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: islandClockModule.vAmPm !== ""
            text: islandClockModule.vAmPm
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(8 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurfVar
        }
    }
    Column {
        id: islandClockCol
        visible: !unifiedFrame.barVertical
        anchors.centerIn: parent
        spacing: -1
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: islandClockModule.timeText
            font.family: globalState.fontPrimary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.DemiBold
            color: pal.colorOnSurface
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: islandClockModule.dateText
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(8 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurfVar
        }
    }
}
