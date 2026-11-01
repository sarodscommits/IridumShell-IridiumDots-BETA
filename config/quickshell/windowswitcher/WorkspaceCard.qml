import QtQuick
import QtQuick.Effects

// Thumbnail of a workspace in the switcher's bottom strip.
Item {
    id: wsCard
    required property var win
    required property var modelData
    required property int index
    readonly property bool isCur: modelData === win.gs.activeWorkspace
    readonly property bool sel: win.wsMode && win.wsSel === index
    readonly property string shot: win.gs.wsShots[modelData] || ""
    height: parent.height
    width: Math.round(win.wsCardH * 16 / 9) + 4
    anchors.verticalCenter: parent.verticalCenter

    Rectangle { id: wsMask; width: wsCardBody.width; height: wsCardBody.height; radius: 14; color: "#FFFFFF"; visible: false; layer.enabled: true }

    Rectangle {
        id: wsCardBody
        anchors.centerIn: parent
        width: parent.width - 4
        height: win.wsCardH
        radius: 14
        color: win.gs.glassMode ? win.ga(win.colors.surfaceHigh, 0.65) : win.colors.surfaceHigh
        scale: wsCard.sel || wsHov.hovered ? 1.06 : 1
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: wsMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.05
        }

        Image {
            anchors.fill: parent
            source: wsCard.shot
            cache: false
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
        }
        Text {
            anchors.centerIn: parent
            visible: wsCard.shot === ""
            text: wsCard.modelData
            font.family: win.gs.fontSecondary; font.pixelSize: 34; font.weight: Font.Bold
            color: win.colors.mutedDeep; opacity: 0.8
        }
        // number label
        Rectangle {
            anchors.left: parent.left; anchors.bottom: parent.bottom
            anchors.margins: 8
            width: Math.max(24, lbl.implicitWidth + 14); height: 24; radius: 12
            color: wsCard.isCur ? win.colors.primary : Qt.rgba(0, 0, 0, 0.55)
            Behavior on color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Text {
                id: lbl
                anchors.centerIn: parent
                text: wsCard.modelData
                font.family: win.gs.fontSecondary; font.pixelSize: 12; font.weight: Font.Bold
                color: wsCard.isCur ? win.colors.colorOnPrimary : "#FFFFFF"
            }
        }
    }

    Rectangle {
        anchors.centerIn: wsCardBody
        width: wsCardBody.width; height: wsCardBody.height
        scale: wsCardBody.scale
        radius: 14
        color: "transparent"
        border.width: (wsCard.sel || wsCard.isCur) ? 3 : 1
        border.color: (wsCard.sel || wsCard.isCur) ? win.colors.primary
                    : Qt.rgba(1, 1, 1, wsHov.hovered ? 0.22 : 0.08)
        Behavior on border.color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    HoverHandler { id: wsHov }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: win.switchWorkspace(wsCard.modelData)
    }
}
