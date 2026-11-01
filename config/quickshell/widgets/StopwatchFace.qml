import QtQuick
import QtQuick.Layouts
import "../ui"

// Stopwatch face with laps
Item {
    id: swFace

    required property color colorPrimary
    required property color colorPrimaryCont
    required property color colorOnPrimaryCont
    required property color colorOnSurfVar
    required property color colorSurface

    property bool running:     false
    property real elapsedMs:   0
    property var  laps:        []

    signal startPauseClicked()
    signal lapClicked()
    signal resetClicked()

    function fmt(ms) {
        var totalCs = Math.floor(ms / 10);
        var cs = totalCs % 100;
        var totalS = Math.floor(totalCs / 100);
        var s = totalS % 60;
        var totalM = Math.floor(totalS / 60);
        var m = totalM % 60;
        var h = Math.floor(totalM / 60);
        var pad = function(n, w) { var str = String(n); while (str.length < w) str = "0" + str; return str; };
        if (h > 0) return h + ":" + pad(m, 2) + ":" + pad(s, 2);
        return pad(m, 2) + ":" + pad(s, 2) + "." + pad(cs, 2);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Math.max(6, swFace.height * 0.03)

        Item { Layout.fillHeight: true; Layout.preferredHeight: 1 }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: swFace.fmt(swFace.elapsedMs)
            font.family: globalState.fontPrimary; font.weight: Font.DemiBold
            font.pixelSize: Math.max(26, Math.min(swFace.width, swFace.height) * 0.22)
            color: swFace.colorPrimary
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Math.max(10, swFace.width * 0.03)

            Rectangle {
                id: swResetBtn
                width: 40; height: 40; radius: m3Ib2Ma.pressed ? Math.max(4, (20) * 0.5) : (20)
                Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                property bool enabledNow: !swFace.running && swFace.elapsedMs > 0
                color: swResetHov.hovered && enabledNow ? swFace.colorPrimaryCont : swFace.colorSurface
                opacity: enabledNow ? 1 : 0.35
                Behavior on color { M3ColorAnim { duration: m3.durFast } }
                Text {
                    anchors.centerIn: parent
                    text: "\ue5d5"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 18
                    color: swFace.colorOnSurfVar
                }
                HoverHandler { id: swResetHov; enabled: swResetBtn.enabledNow }
                MouseArea { id: m3Ib2Ma;
                    anchors.fill: parent
                    enabled: swResetBtn.enabledNow
                    cursorShape: Qt.PointingHandCursor
                    onClicked: swFace.resetClicked()
                }
            }

            Rectangle {
                id: swStartBtn
                width: 64; height: 64; radius: 32
                color: swFace.colorPrimary
                FadeIcon {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: swFace.running ? 0 : 1
                    text: swFace.running ? "\ue034" : "\ue037"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 26
                    color: swFace.colorOnPrimaryCont
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: swFace.startPauseClicked()
                }
            }

            Rectangle {
                id: swLapBtn
                width: 40; height: 40; radius: m3Ib3Ma.pressed ? Math.max(4, (20) * 0.5) : (20)
                Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                color: swLapHov.hovered && swFace.running ? swFace.colorPrimaryCont : swFace.colorSurface
                opacity: swFace.running ? 1 : 0.35
                Behavior on color { M3ColorAnim { duration: m3.durFast } }
                Text {
                    anchors.centerIn: parent
                    text: "\ue153"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 17
                    color: swFace.colorOnSurfVar
                }
                HoverHandler { id: swLapHov; enabled: swFace.running }
                MouseArea { id: m3Ib3Ma;
                    anchors.fill: parent
                    enabled: swFace.running
                    cursorShape: Qt.PointingHandCursor
                    onClicked: swFace.lapClicked()
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: swFace.laps.length > 0
            Layout.preferredHeight: swFace.laps.length > 0 ? -1 : 0
            Layout.topMargin: swFace.laps.length > 0 ? 4 : 0
            visible: swFace.laps.length > 0
            clip: true
            model: swFace.laps.slice().reverse()
            spacing: 2
            delegate: RowLayout {
                width: ListView.view.width
                Text {
                    text: "#" + modelData.n
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                    color: swFace.colorOnSurfVar
                    opacity: 0.7
                    Layout.preferredWidth: 28
                }
                Text {
                    text: swFace.fmt(modelData.splitMs)
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                    color: swFace.colorOnSurfVar
                    Layout.fillWidth: true
                }
                Text {
                    text: swFace.fmt(modelData.totalMs)
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                    color: swFace.colorOnSurfVar
                    opacity: 0.7
                }
            }
        }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 1 }
    }
}
