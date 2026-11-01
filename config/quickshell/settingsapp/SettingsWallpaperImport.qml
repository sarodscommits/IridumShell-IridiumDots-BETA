import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Wallpaper import panel of the settings window
ColumnLayout {
    id: wpImportCol
    anchors.left: parent.left; anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: 44; anchors.rightMargin: 44
    spacing: 14

    Item {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 76; Layout.preferredHeight: 76
        Rectangle {
            anchors.fill: parent
            radius: 24
            visible: !wpImportLayer.busy
            color: wpImportLayer.hot ? pal.primary : pal.primaryCont
            Behavior on color { M3ColorAnim { duration: m3.durFast } }
            FadeIcon {
                anchors.centerIn: parent
                text: wpImportLayer.hot ? "" : ""
                font.family: "Material Symbols Rounded"; font.pixelSize: 38
                color: wpImportLayer.hot ? pal.colorOnPrimary : pal.primary
            }
        }
        MorphLoader {
            anchors.centerIn: parent
            size: 56
            fillColor: pal.primary
            visible: wpImportLayer.busy
            running: visible
        }
    }

    Text {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: globalState.wpImportState === "picking" ? tr("wpi_picking")
            : globalState.wpImportState === "copying" ? tr("wpi_copying")
            : wpImportLayer.hot ? tr("wpi_drop_release")
            : tr("wpi_drop_title")
        font.family: globalState.fontPrimary
        font.pixelSize: Math.round(19 * globalState.fontScale)
        font.weight: Font.DemiBold
        color: pal.colorOnSurface
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 40; Layout.rightMargin: 40
        spacing: 10
        visible: !wpImportLayer.busy && !wpImportLayer.hot
        Rectangle { Layout.fillWidth: true; height: 1; color: pal.mutedDeep }
        Text {
            text: tr("wpi_or")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
            color: pal.muted
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: pal.mutedDeep }
    }

    Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredHeight: 42
        Layout.preferredWidth: wpImportBrowseRow.implicitWidth + 40
        radius: 21
        visible: !wpImportLayer.hot
        enabled: !wpImportLayer.busy
        opacity: enabled ? 1 : 0.45
        color: wpImportBrowseHov.hovered && enabled ? Qt.lighter(pal.primary, 1.08) : pal.primary
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
        scale: wpImportBrowseMa.pressed ? 0.96 : 1
        Behavior on scale { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
        RowLayout {
            id: wpImportBrowseRow
            anchors.centerIn: parent
            spacing: 8
            Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: pal.colorOnPrimary }
            Text {
                text: tr("wpi_browse")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnPrimary
            }
        }
        HoverHandler { id: wpImportBrowseHov; cursorShape: Qt.PointingHandCursor }
        MouseArea {
            id: wpImportBrowseMa
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: wpImportPick()
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: wpImportMsgRow.implicitHeight + 18
        radius: 14
        visible: globalState.wpImportState === "done" && globalState.wpImportMsg !== "" && !wpImportLayer.hot
        readonly property color kindColor: globalState.wpImportMsgKind === "ok" ? pal.positive
                                         : globalState.wpImportMsgKind === "warn" ? pal.accent : pal.error
        color: Qt.rgba(kindColor.r, kindColor.g, kindColor.b, 0.14)
        RowLayout {
            id: wpImportMsgRow
            anchors.left: parent.left; anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14; anchors.rightMargin: 14
            spacing: 10
            FadeIcon {
                text: globalState.wpImportMsgKind === "ok" ? "" : globalState.wpImportMsgKind === "warn" ? "" : ""
                font.family: "Material Symbols Rounded"; font.pixelSize: 18
                color: parent.parent.kindColor
            }
            Text {
                Layout.fillWidth: true
                text: globalState.wpImportMsg
                wrapMode: Text.WordWrap
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                color: pal.colorOnSurface
            }
        }
    }

    Item { Layout.fillWidth: true; Layout.preferredHeight: 8 }

    Text {
        text: tr("wpi_formats")
        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
        color: pal.colorOnSurfVar
    }

    Repeater {
        model: [
            { icon: "", label: tr("wpi_images"), exts: ["JPG", "JPEG", "PNG", "WEBP"] },
            { icon: "", label: tr("wpi_videos"), exts: ["MP4", "WEBM", "MKV"] }
        ]
        delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 8
            Text { text: modelData.icon; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary; Layout.preferredWidth: 20 }
            Text {
                text: modelData.label
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                color: pal.colorOnSurfVar
                Layout.preferredWidth: 120
                elide: Text.ElideRight
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: modelData.exts
                    delegate: Rectangle {
                        required property string modelData
                        width: wpImportChipTxt.implicitWidth + 16
                        height: 22; radius: 11
                        color: pal.surfaceVar
                        Text {
                            id: wpImportChipTxt
                            anchors.centerIn: parent
                            text: modelData
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
                            color: pal.colorOnSurfVar
                        }
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.topMargin: 2
        text: tr("wpi_dest")
        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
        color: pal.muted
        wrapMode: Text.WordWrap
    }
}
