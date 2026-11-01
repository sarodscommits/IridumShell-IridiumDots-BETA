import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"

// Settings: appearance page
Item {
    id: settingsAppearancePage
    property alias appearanceFlick: appearanceFlick
    anchors.fill: parent
    visible: settingsPopup.activeSection === "wallpaper"

    Item {
        id: appearanceScrollView
        anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
        anchors.leftMargin: 24; anchors.topMargin: 4; anchors.bottomMargin: 16
        width: parent.width - 36
        clip: true

        Flickable {
            id: appearanceFlick
            anchors.fill: parent
            contentWidth: width
            contentHeight: appearanceColumnLayout.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            ColumnLayout {
                id: appearanceColumnLayout
                width: appearanceFlick.width - 14
                spacing: 8

                Rectangle {
                    id: wpHeroCard
                    Layout.fillWidth: true
                    implicitHeight: wpHeroCol.implicitHeight + 40
                    radius: 32
                    color: globalState.glassMode ? ga(pal.surfacePop, 0.78) : pal.surfacePop

                    ColumnLayout {
                        id: wpHeroCol
                        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                        anchors.margins: 20
                        spacing: 16


                        AppearanceWallpaperPreview { id: appearanceWallpaperPreview }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: wpFpsRowCol.implicitHeight + 24
                            radius: 16
                            color: globalState.glassMode ? ga(pal.surfaceHigh, 0.7) : pal.surfaceHigh
                            ColumnLayout {
                                id: wpFpsRowCol
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 16; anchors.rightMargin: 16
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10
                                    Text {
                                        text: "\ue3f4"
                                        font.family: "Material Symbols Rounded"; font.pixelSize: 16
                                        color: pal.primary
                                    }
                                    Text {
                                        text: tr("wallpaper_fps_limit")
                                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                                        color: pal.colorOnSurfVar
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: globalState.wallpaperFpsLimit + " fps"
                                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                                        color: pal.muted
                                    }
                                }
                                FractionSlider {
                                    id: wallpaperFpsTrack
                                    Layout.fillWidth: true
                                    property real displayPct: (globalState.wallpaperFpsLimit - 10) / 50
                                    property int dotCount: 18
                                    value: displayPct
                                    trackH: 14
                                    handleHOverride: 20
                                    height: 22
                                    activeColor: pal.toggleOn
                                    inactiveColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                                    steps: Math.max(0, (18) - 1)
                                    showBubble: false
                                    onFracMoved: (frac) => { var idx=Math.round(frac*(dotCount-1)); var v=Math.round(10 + (idx/(dotCount-1))*50); setWallpaperFpsLimit(v); }
                                }
                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 48
                            radius: wpChangeMa.pressed ? 16 : 24
                            Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
                            color: globalState.settingsWpBrowse
                            ? (wpChangeHov.hovered ? pal.surfaceElevated : pal.surfaceHigh)
                            : (wpChangeHov.hovered ? Qt.lighter(pal.primary, 1.08) : pal.primary)
                            Behavior on color { M3ColorAnim {} }
                            scale: wpChangeMa.pressed ? 0.97 : 1
                            Behavior on scale { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8
                                FadeIcon {
                                    text: globalState.settingsWpBrowse ? "" : ""
                                    font.family: "Material Symbols Rounded"; font.pixelSize: 17
                                    color: globalState.settingsWpBrowse ? pal.colorOnSurface : pal.colorOnPrimary
                                }
                                Text {
                                    text: globalState.settingsWpBrowse ? tr("wp_close_browser") : tr("wp_change")
                                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                                    color: globalState.settingsWpBrowse ? pal.colorOnSurface : pal.colorOnPrimary
                                }
                            }
                            HoverHandler { id: wpChangeHov; cursorShape: Qt.PointingHandCursor }
                            MouseArea {
                                id: wpChangeMa
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: globalState.settingsWpBrowse = !globalState.settingsWpBrowse
                            }
                        }

                        ColumnLayout {
                            id: wpBrowser
                            Layout.fillWidth: true
                            visible: globalState.settingsWpBrowse
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: ""
                                    font.family: "Material Symbols Rounded"; font.pixelSize: 16
                                    color: pal.primary
                                }
                                Text {
                                    text: tr("wp_browser_title")
                                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                                    color: pal.colorOnSurfVar
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: globalState.wallpaperList.length > 0 ? "· " + globalState.wallpaperList.length : ""
                                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                                    color: pal.muted
                                }
                                Text {
                                    text: tr("wp_browser_hint")
                                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                                    color: pal.mutedDeep
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: 260
                                }
                                Rectangle {
                                    Layout.preferredHeight: 30
                                    Layout.preferredWidth: wpAddRow.implicitWidth + 24
                                    radius: 15
                                    color: wpAddHov.hovered ? Qt.lighter(pal.primary, 1.08) : pal.primary
                                    Behavior on color { M3ColorAnim { duration: m3.durFast } }
                                    scale: wpAddMa.pressed ? 0.95 : 1
                                    Behavior on scale { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
                                    RowLayout {
                                        id: wpAddRow
                                        anchors.centerIn: parent
                                        spacing: 5
                                        Text { text: "\ue145"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.colorOnPrimary }
                                        Text {
                                            text: tr("wpi_add_btn")
                                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                                            color: pal.colorOnPrimary
                                        }
                                    }
                                    HoverHandler { id: wpAddHov; cursorShape: Qt.PointingHandCursor }
                                    MouseArea { id: wpAddMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wpImportShow() }
                                }
                            }

                            MorphLoader {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 12; Layout.bottomMargin: 12
                                size: 36
                                fillColor: pal.primary
                                visible: !globalState.wallpaperLoaded
                                running: visible && wpBrowser.visible
                            }
                            Text {
                                Layout.fillWidth: true
                                Layout.topMargin: 10; Layout.bottomMargin: 10
                                visible: globalState.wallpaperLoaded && globalState.wallpaperList.length === 0
                                text: tr("wp_none")
                                horizontalAlignment: Text.AlignHCenter
                                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                                color: pal.muted
                            }

                            Item {
                                id: wpGrid
                                Layout.fillWidth: true
                                implicitHeight: wpFlow.implicitHeight
                                readonly property real gap: 12
                                readonly property int cols: Math.max(2, Math.floor((width + gap) / (190 + gap)))
                                readonly property real cellW: Math.max(1, (width - (cols - 1) * gap) / cols)
                                readonly property real cellH: Math.round(cellW * 9 / 16)

                                Rectangle {
                                    id: wpGridMask
                                    width: wpGrid.cellW; height: wpGrid.cellH
                                    radius: 10
                                    visible: false
                                    layer.enabled: true
                                }

                                Flow {
                                    id: wpFlow
                                    width: parent.width
                                    spacing: wpGrid.gap

                                    AppearanceWallpaperGrid { id: appearanceWallpaperGrid }
                                }
                            }
                        }
                    }
                }

            }
        }
    }
}
