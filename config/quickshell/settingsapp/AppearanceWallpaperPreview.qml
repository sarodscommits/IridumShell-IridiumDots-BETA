import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../settings"

// Current wallpaper preview row
RowLayout {
    id: appearanceWallpaperPreview
    Layout.fillWidth: true
    spacing: 20

        Item {
            id: wpPreview
            Layout.fillWidth: true
            Layout.preferredWidth: 3
            Layout.alignment: Qt.AlignTop
            Layout.preferredHeight: Math.round(width * 9 / 16)

            Rectangle {
                id: wpPreviewMask
                width: wpPreview.width; height: wpPreview.height
                radius: 20
                visible: false
                layer.enabled: true
            }
            SettingsWpThumb {
                anchors.fill: parent
                radius: 20
                maskItem: wpPreviewMask
                loadWidth: 640
                source: {
                    var e = wpSidePanel.entry;
                    if (e) return "file://" + (e.thumb !== "" ? e.thumb : e.path);
                    if (globalState.currentWallpaperStill !== "") return "file://" + globalState.currentWallpaperStill;
                    return "";
                }
                placeholderColor: globalState.glassMode ? ga(pal.surfaceHigh, 0.6) : pal.surfaceHigh
                iconColor: pal.mutedDeep
            }
            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 40
                bottomLeftRadius: 20; bottomRightRadius: 20
                visible: wpSidePanel.entry !== null
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(0,0,0,0.7) }
                }
                RowLayout {
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 10; anchors.rightMargin: 10; anchors.bottomMargin: 7
                    spacing: 6
                    Text {
                        visible: wpSidePanel.entry ? wpSidePanel.entry.animated : false
                        text: ""
                        font.family: "Material Symbols Rounded"; font.pixelSize: 14
                        color: "#FFFFFF"
                    }
                    Text {
                        Layout.fillWidth: true
                        text: wpSidePanel.entry ? wpSidePanel.entry.name : ""
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                        color: "#FFFFFF"
                        elide: Text.ElideMiddle
                    }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: 20
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1,1,1,0.10)
            }
        }

    ColumnLayout {
        id: wpSidePanel
        Layout.fillWidth: true
        Layout.preferredWidth: 2
        Layout.alignment: Qt.AlignTop
        spacing: 8

        readonly property var entry: globalState.currentWallpaperEntry
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 2
            spacing: 6
            Text {
                text: ""
                font.family: "Material Symbols Rounded"; font.pixelSize: 14
                color: pal.primary
            }
            Text {
                Layout.fillWidth: true
                text: tr("wp_shell_palette")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
                elide: Text.ElideRight
            }
            Text {
                id: wpShellHexLabel
                property string hex: ""
                text: hex
                font.family: "monospace"; font.pixelSize: Math.round(10 * globalState.fontScale)
                color: pal.muted
            }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: [pal.primary, pal.accent, pal.tertiary, pal.primaryCont, pal.secondaryCont,
                        pal.surface, pal.surfaceHigh, pal.surfaceVar, pal.colorOnSurface, pal.error]
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 22
                    radius: 6
                    color: modelData
                    border.width: 1
                    border.color: Qt.rgba(1,1,1, shellSwHov.hovered ? 0.5 : 0.10)
                    HoverHandler {
                        id: shellSwHov
                        onHoveredChanged: wpShellHexLabel.hex = hovered ? String(modelData).toUpperCase() : ""
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 6
            Text {
                text: ""
                font.family: "Material Symbols Rounded"; font.pixelSize: 14
                color: pal.primary
            }
            Text {
                Layout.fillWidth: true
                text: tr("wp_term_palette")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
                elide: Text.ElideRight
            }
            Text {
                id: wpTermHexLabel
                property string hex: ""
                text: hex
                font.family: "monospace"; font.pixelSize: Math.round(10 * globalState.fontScale)
                color: pal.muted
            }
        }
        Rectangle {
            id: wpTermCard
            readonly property var tc: globalState.termColors
            readonly property bool hasColors: tc && tc.color0 !== undefined
            Layout.fillWidth: true
            implicitHeight: wpTermCol.implicitHeight + 16
            radius: 16
            color: hasColors && tc.background ? tc.background : (globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep)
            border.width: 1
            border.color: Qt.rgba(1,1,1,0.08)

            ColumnLayout {
                id: wpTermCol
                anchors.left: parent.left; anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 4

                Text {
                    Layout.fillWidth: true
                    visible: !wpTermCard.hasColors
                    text: tr("wp_term_unavailable")
                    wrapMode: Text.WordWrap
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                    color: pal.muted
                }
                Repeater {
                    model: wpTermCard.hasColors ? 2 : 0
                    delegate: RowLayout {
                        id: wpTermRow
                        required property int index
                        Layout.fillWidth: true
                        spacing: 4
                        Repeater {
                            model: 8
                            delegate: Rectangle {
                                required property int index
                                readonly property string hex: wpTermCard.tc["color" + (wpTermRow.index * 8 + index)] || "#000000"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 18
                                radius: 5
                                color: hex
                                border.width: 1
                                border.color: Qt.rgba(1,1,1, termSwHov.hovered ? 0.5 : 0.08)
                                HoverHandler {
                                    id: termSwHov
                                    onHoveredChanged: wpTermHexLabel.hex = hovered ? ("color" + (wpTermRow.index * 8 + parent.index) + "  " + parent.hex.toUpperCase()) : ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
