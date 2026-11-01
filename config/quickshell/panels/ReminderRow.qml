import QtQuick
import QtQuick.Layouts
import "../ui"

// Calendar editor reminder row
Item {
    id: row
    required property var modelData
    required property int index
    property Item editor
    property int iconSize: 14
    property bool showDate: false
    signal removeClicked()
    width: ListView.view ? ListView.view.width : 0

    Rectangle {
        x: 0; y: 0
        width: Math.max(0, parent.width - row.editor._rmCloseW - row.editor._rmGap)
        height: parent.height
        topLeftRadius: height / 2; bottomLeftRadius: height / 2
        topRightRadius: 8; bottomRightRadius: 8
        color: row.editor.cardColor(false)

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 10
            spacing: 8

            Text {
                text: {
                    for (var i = 0; i < row.editor.eventTypes.length; i++)
                    if (row.editor.eventTypes[i].key === row.modelData.type) return row.editor.eventTypes[i].icon;
                    return "";
                }
                font.family: "Material Symbols Rounded"; font.pixelSize: row.iconSize
                color: row.editor.colorPrimary
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    text: row.modelData.title
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                    color: row.editor.colorOnSurface
                    elide: Text.ElideRight
                }
                Text {
                    visible: row.showDate
                    Layout.fillWidth: true
                    text: row.showDate ? row.modelData.dateLabel : ""
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                    color: row.editor.colorTextSecondary
                    elide: Text.ElideRight
                }
            }
        }
    }
    Item {
        width: row.editor._rmCloseW
        x: parent.width - width; y: 0
        height: parent.height
        property color segColor: rmHov.hovered
        ? Qt.darker(row.editor.colorError, 1.6)
        : row.editor.cardColor(false)
        Behavior on segColor { M3ColorAnim {} }
        PillCloseShape { anchors.fill: parent; segColor: parent.segColor }
        Text {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -2
            text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 16
            color: rmHov.hovered ? row.editor.colorError : row.editor.colorTextSecondary
            scale: rmHov.hovered ? 1.12 : 1
            Behavior on scale { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
        }
        HoverHandler { id: rmHov }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.removeClicked()
        }
    }
}
