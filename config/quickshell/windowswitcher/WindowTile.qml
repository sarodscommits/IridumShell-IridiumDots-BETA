import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: tile
    required property var win
    required property var modelData
    required property var page
    readonly property var c: modelData.c
    readonly property bool sel: !win.wsMode && win.selected === modelData.i
    readonly property bool hot: tileHov.hovered
    readonly property string icon: win.gs.windowIconFor(c.cls)
    x: modelData.x; y: modelData.y
    width: modelData.w; height: modelData.h
    z: sel ? 2 : 1
    scale: sel ? 1.025 : 1
    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

    Rectangle { id: tileMask; anchors.fill: parent; radius: win.tileRadius; color: "#FFFFFF"; visible: false; layer.enabled: true }

    Rectangle {
        id: tileBg
        anchors.fill: parent
        radius: win.tileRadius
        color: win.gs.glassMode ? win.ga(win.colors.surfaceHigh, 0.65) : win.colors.surfaceHigh
        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: tileMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.05
        }


        Rectangle {
            anchors.fill: parent; anchors.margins: 2; radius: win.tileRadius - 2
            color: win.gs.glassMode ? win.ga(win.colors.surfaceElevated, 0.6) : win.colors.surfaceElevated
            opacity: cap.hasContent ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }
        Image {
            anchors.centerIn: parent
            width: Math.min(96, parent.height * 0.4); height: width
            sourceSize: Qt.size(128, 128)
            visible: tile.icon !== "" && !cap.hasContent
            source: tile.icon !== "" ? "file://" + tile.icon : ""
            fillMode: Image.PreserveAspectFit
        }

        ScreencopyView {
            id: cap
            paintCursor: false
            captureSource: tile.page.near ? win.toplevelFor(tile.c) : null
            live: win.open && (tile.page.rel === 0 || win.warm)
            visible: hasContent
            readonly property real sw: sourceSize.width > 0 ? sourceSize.width : 16
            readonly property real sh: sourceSize.height > 0 ? sourceSize.height : 9
            readonly property real k: Math.max(tile.width / sw, tile.height / sh)
            width: sw * k; height: sh * k
            anchors.centerIn: parent
        }

        Rectangle {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            height: 46
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
            }
            Row {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 10; anchors.rightMargin: 10; anchors.bottomMargin: 8
                spacing: 8
                Image {
                    visible: tile.icon !== ""
                    width: 20; height: 20
                    sourceSize: Qt.size(64, 64)
                    source: tile.icon !== "" ? "file://" + tile.icon : ""
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    width: parent.width - (tile.icon !== "" ? 28 : 0)
                    anchors.verticalCenter: parent.verticalCenter
                    text: tile.c.title !== "" ? tile.c.title : tile.c.cls
                    elide: Text.ElideRight
                    font.family: win.gs.fontSecondary; font.pixelSize: Math.round(13 * win.gs.fontScale)
                    color: "#FFFFFF"
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: win.tileRadius
        color: "#000000"
        opacity: tile.sel || tile.hot ? 0 : 0.22
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        anchors.fill: parent
        radius: win.tileRadius
        color: "transparent"
        border.width: tile.sel ? 3 : 1
        border.color: tile.sel ? win.colors.primary : Qt.rgba(1, 1, 1, tile.hot ? 0.22 : 0.08)
        Behavior on border.color { ColorAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    HoverHandler {
        id: tileHov
        onHoveredChanged: if (hovered) win.selected = tile.modelData.i
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: win.activate(tile.modelData.i)
    }

    Rectangle {
        anchors.top: parent.top; anchors.right: parent.right
        anchors.margins: 8
        width: 24; height: 24; radius: 12
        visible: tile.hot || tile.sel
        color: closeHov.hovered ? Qt.rgba(1, 0, 0, 0.45) : Qt.rgba(0, 0, 0, 0.55)
        Behavior on color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Text {
            anchors.centerIn: parent
            text: "\ue5cd"
            font.family: "Material Symbols Rounded"; font.pixelSize: 14
            color: "#FFFFFF"
        }
        HoverHandler { id: closeHov }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: win.closeWindow(tile.modelData.i)
        }
    }
}
