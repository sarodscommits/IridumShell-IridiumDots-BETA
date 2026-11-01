import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Coverflow cards of the wallpaper picker
Repeater {
    id: wpCardRepeater
    model: globalState.wallpaperPickerAlive ? wpPickerRoot.itemCount : 0

    property color surfaceHigh: pal.surfaceHigh
    property color surfaceElevated: pal.surfaceElevated
    property color primaryVar: pal.primary
    property color mutedDeepVar: pal.mutedDeep

    Item {
        id: wpCardDelegate
        required property int index
        readonly property var wpData: globalState.wallpaperList[index]
        readonly property int rel: wpPickerRoot.relIndex(index)
        readonly property bool isCenter: rel === 0
        readonly property bool isNext:   rel === 1
        readonly property bool isStack:  rel < 0 && rel >= -wpPickerRoot.maxStackDepth
        readonly property int  stackDepth: isStack ? -rel : 0
        readonly property bool inView: isCenter || isNext || isStack
        readonly property bool nearView: wpPickerRoot.itemCount > 0
        && Math.abs(rel) <= (wpPickerRoot.maxStackDepth + 1)

        readonly property real cw: wpPickerRoot.cardW
        readonly property real ch: wpPickerRoot.cardH

        readonly property real targetX: {
            if (isCenter) return (wallpaperPickerWindow.width - cw) / 2;
            if (isNext)   return wallpaperPickerWindow.width - cw * 0.25;
            if (isStack)  return wpPickerRoot.stackTargetX(stackDepth);
            return rel > 0 ? wallpaperPickerWindow.width + cw : -cw * 2;
        }
        readonly property real targetScale: {
            if (isCenter) return 1.0;
            if (isNext)   return 1.15;
            if (isStack)  return wpPickerRoot.stackScale(stackDepth);
            return 0.55;
        }
        readonly property real targetShade: {
            if (isCenter) return 0.0;
            if (isNext)   return 0.25;
            if (isStack)  return Math.min(0.75, 0.35 + stackDepth * 0.1);
            return 0.0;
        }
        readonly property int targetZ: {
            if (isCenter) return 1000;
            if (isNext)   return 500;
            if (isStack)  return 400 - stackDepth;
            return 0;
        }

        x: targetX
        y: (wallpaperPickerWindow.height - ch) / 2
        z: targetZ
        width: cw; height: ch
        scale: targetScale
        opacity: inView ? 1.0 : 0.0
        visible: nearView
        transformOrigin: Item.Center

        Behavior on x       { M3SpringAnim { token: "spatialDefault" } }
        Behavior on scale   { M3SpringAnim { token: "spatialDefault"; epsilon: 0.002 } }
        Behavior on opacity { M3NumberAnim {} }

        readonly property bool wpRoundingEnabled: true

        Rectangle {
            id: wpCardMask
            anchors.fill: parent
            radius: 18
            color: "#FFFFFF"
            visible: false
            layer.enabled: wpCardDelegate.wpRoundingEnabled
        }

        Rectangle {
            id: wpCardBg
            anchors.fill: parent
            radius: 18
            clip: !wpCardDelegate.wpRoundingEnabled
            color: globalState.glassMode ? ga(wpCardRepeater.surfaceHigh, 0.65) : wpCardRepeater.surfaceHigh
            readonly property bool isAppliedWp: wpCardDelegate.wpData !== undefined && wpCardDelegate.wpData
            && wpCardDelegate.wpData.path === globalState.currentWallpaper

            layer.enabled: wpCardDelegate.wpRoundingEnabled
            layer.smooth: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: wpCardMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 0.05
            }

            Image {
                id: wpCardImgCrop
                anchors.fill: parent
                source: (globalState.wallpaperPickerOpen && wpCardDelegate.wpData && wpCardDelegate.nearView)
                ? "file://" + (wpCardDelegate.wpData.thumb !== ""
                ? wpCardDelegate.wpData.thumb : wpCardDelegate.wpData.path)
                : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true; cache: false
                sourceSize: Qt.size(Math.round(wpCardDelegate.cw), Math.round(wpCardDelegate.ch))
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { M3NumberAnim {} }
            }

            Image {
                id: wpCardImg
                anchors.fill: parent
                source: (globalState.wallpaperPickerOpen && wpCardDelegate.wpData && Math.abs(wpCardDelegate.rel) <= 1)
                ? "file://" + (wpCardDelegate.wpData.thumb !== ""
                ? wpCardDelegate.wpData.thumb : wpCardDelegate.wpData.path)
                : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true; cache: false
                sourceSize: Qt.size(Math.round(wpCardDelegate.cw), Math.round(wpCardDelegate.ch))
                opacity: (status === Image.Ready && wpCardDelegate.isCenter) ? 1 : 0
                Behavior on opacity { M3NumberAnim {} }
            }

            Rectangle {
                anchors.fill: parent; anchors.margins: 2; radius: 16
                color: globalState.glassMode ? ga(wpCardRepeater.surfaceElevated, 0.6) : wpCardRepeater.surfaceElevated
                opacity: wpCardImgCrop.status !== Image.Ready ? 1 : 0
                Behavior on opacity { M3NumberAnim {} }
                Text {
                    anchors.centerIn: parent; text: "\ue894"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 32
                    color: wpCardRepeater.mutedDeepVar; opacity: 0.6
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.left: parent.left
                anchors.margins: 8
                height: 24; radius: 12
                width: wpProfBadgeRow.implicitWidth + 16
                visible: wpCardDelegate.wpData ? profileStore.has(wpCardDelegate.wpData.path) : false
                color: Qt.rgba(0,0,0,0.55)
                Row {
                    id: wpProfBadgeRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\ue40a"
                        font.family: "Material Symbols Rounded"; font.pixelSize: 13
                        color: wpCardRepeater.primaryVar
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tr("profile_badge")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                        color: "#FFFFFF"
                    }
                }
            }

            Rectangle {
                anchors.top: parent.top; anchors.right: parent.right
                anchors.margins: 8; width: 24; height: 24; radius: 12
                visible: wpCardDelegate.wpData ? wpCardDelegate.wpData.animated : false
                color: Qt.rgba(0,0,0,0.55)
                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 1
                    text: "\u25B6"
                    font.pixelSize: 10
                    color: "#FFFFFF"
                }
            }

            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 46
                visible: wpCardDelegate.isCenter
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.72) }
                }
                Text {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.bottomMargin: 8; anchors.leftMargin: 10; anchors.rightMargin: 10
                    text: wpCardDelegate.wpData ? wpCardDelegate.wpData.name : ""
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale)
                    color: "#FFFFFF"; elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                onClicked: {
                    if (wpCardDelegate.isCenter) {
                        if (wpCardDelegate.wpData) applyWallpaperSmooth(wpCardDelegate.wpData.path);
                        globalState.wallpaperPickerOpen = false;
                    } else {
                        wpPickerRoot.currentIndex = wpCardDelegate.index;
                    }
                }
            }
        }
        Rectangle {
            id: wpCardShade
            anchors.fill: parent
            radius: 18
            color: "#000000"
            opacity: wpCardDelegate.targetShade
            Behavior on opacity { M3NumberAnim {} }
        }
        Rectangle {
            id: wpCardBorder
            anchors.fill: parent
            radius: 18
            color: "transparent"
            border.color: wpCardBg.isAppliedWp ? wpCardRepeater.primaryVar
            : wpCardDelegate.isCenter ? Qt.rgba(1,1,1,0.22) : Qt.rgba(1,1,1,0.08)
            border.width: wpCardBg.isAppliedWp ? 3 : (wpCardDelegate.isCenter ? 1 : 0)
            Behavior on border.color { M3ColorAnim {} }
        }
    }
}
