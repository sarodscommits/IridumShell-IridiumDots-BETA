import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../ui"
import "../ui/SvgPaths.js" as SvgPaths

// Hourly / daily weather forecast row
Item {
    id: wfRoot

    required property color colorPrimary
    required property color colorOnSurfVar
    required property color colorTextSecondary
    required property color cardBg

    property var days: []

    property bool vertical: false

    property bool shapedCards: false

    property string todayLabel:    "Today"
    property string tomorrowLabel: "Tomorrow"
    property var    weekdayLabels: ["S","M","T","W","T","F","S"]

    function dayLabel(idx, dateStr) {
        if (idx === 0) return wfRoot.todayLabel;
        if (idx === 1) return wfRoot.tomorrowLabel;
        try {
            var d = new Date(dateStr);
            return wfRoot.weekdayLabels[d.getDay()];
        } catch (e) {
            return "";
        }
    }

    Row {
        visible: wfRoot.shapedCards
        anchors.fill: parent
        spacing: 10

        Repeater {
            model: wfRoot.days
            delegate: Item {
                required property var modelData
                required property int index
                width: (wfRoot.width - 20) / 3
                height: parent.height

                readonly property var shapeDef: [
                { path: "M15,73 L15,25 Q15,15 24.97,15.71 A70,70 0 0,1 84.29,75.04 Q85,85 75,85 L27,85 Q15,85 15,73 Z", rot: 0,  boost: 1.14 },
                { path: "M35,15 L65,15 A35,35 0 0,1 65,85 L35,85 A35,35 0 0,1 35,15 Z",                                  rot: 45, boost: 1.0  },
                { path: SvgPaths.arch,                    rot: 0,  boost: 1.14 }
                ][index % 3]

                readonly property real shapeSize: Math.min(width, height)

                Shape {
                    anchors.centerIn: parent
                    width: 100; height: 100
                    rotation: shapeDef.rot
                    scale: (shapeSize / 100) * shapeDef.boost
                    antialiasing: true
                    layer.enabled: true; layer.samples: 4; layer.smooth: true
                    ShapePath {
                        strokeWidth: -1
                        strokeColor: "transparent"
                        fillColor: wfRoot.cardBg
                        joinStyle: ShapePath.RoundJoin
                        capStyle: ShapePath.RoundCap
                        PathSvg { path: shapeDef.path }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 4
                    spacing: 3
                    width: parent.width - 26

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: wfRoot.dayLabel(index, modelData.date)
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Medium
                        color: wfRoot.colorOnSurfVar
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.desc !== "" ? weatherText(modelData.desc) : "—"
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                        color: wfRoot.colorTextSecondary
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5
                        Text {
                            text: modelData.max !== "" ? modelData.max + "°" : "—"
                            font.family: globalState.fontPrimary; font.pixelSize: Math.round(16 * globalState.fontScale); font.weight: Font.DemiBold
                            color: wfRoot.colorPrimary
                        }
                        Text {
                            text: modelData.min !== "" ? modelData.min + "°" : "—"
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(16 * globalState.fontScale)
                            color: wfRoot.colorTextSecondary
                        }
                    }
                }
            }
        }
    }

    Row {
        visible: !wfRoot.vertical && !wfRoot.shapedCards
        anchors.fill: parent
        spacing: 10

        Repeater {
            model: wfRoot.days
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: (wfRoot.width - 20) / 3
                height: parent.height
                radius: 16
                color: wfRoot.cardBg

                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    width: parent.width - 12

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: wfRoot.dayLabel(index, modelData.date)
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.Medium
                        color: wfRoot.colorOnSurfVar
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.desc !== "" ? weatherText(modelData.desc) : "—"
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                        color: wfRoot.colorTextSecondary
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6
                        Text {
                            text: modelData.max !== "" ? modelData.max + "°" : "—"
                            font.family: globalState.fontPrimary; font.pixelSize: Math.round(19 * globalState.fontScale); font.weight: Font.DemiBold
                            color: wfRoot.colorPrimary
                        }
                        Text {
                            text: modelData.min !== "" ? modelData.min + "°" : "—"
                            font.family: globalState.fontPrimary; font.pixelSize: Math.round(19 * globalState.fontScale)
                            color: wfRoot.colorTextSecondary
                        }
                    }
                }
            }
        }
    }

    Column {
        visible: wfRoot.vertical && !wfRoot.shapedCards
        anchors.fill: parent
        spacing: 8

        Repeater {
            model: wfRoot.days
            delegate: Rectangle {
                required property var modelData
                required property int index
                width: parent.width
                height: 50
                radius: 16
                color: wfRoot.cardBg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        Layout.preferredWidth: 70
                        text: wfRoot.dayLabel(index, modelData.date)
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.Medium
                        color: wfRoot.colorOnSurfVar
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.desc !== "" ? weatherText(modelData.desc) : "—"
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                        color: wfRoot.colorTextSecondary
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                    Text {
                        text: modelData.max !== "" ? modelData.max + "°" : "—"
                        font.family: globalState.fontPrimary; font.pixelSize: Math.round(19 * globalState.fontScale); font.weight: Font.DemiBold
                        color: wfRoot.colorPrimary
                    }
                    Text {
                        text: modelData.min !== "" ? modelData.min + "°" : "—"
                        font.family: globalState.fontPrimary; font.pixelSize: Math.round(19 * globalState.fontScale)
                        color: wfRoot.colorTextSecondary
                    }
                }
            }
        }
    }
}
