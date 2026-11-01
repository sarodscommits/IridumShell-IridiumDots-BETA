import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../settings"
import "../ui"

// Morphing menu surface of the performance/screenshot tiles
Rectangle {
    id: pmShape
    property alias pmMenuCol: pmMenuCol
    readonly property color fromColor: pmHost.srcTile ? pmHost.srcTile.color : pal.primary
    readonly property color toColor: globalState.glassMode ? ga(pal.surfaceHigh, 0.97) : pal.surfaceHigh
    readonly property real fromRadius: pmHost.srcTile ? pmHost.srcTile.radius : 24
    x: pmHost.lerp(pmHost.sx, pmHost.tx, pmHost.p)
    y: pmHost.lerp(pmHost.sy, pmHost.ty, pmHost.p)
    width: Math.max(1, pmHost.lerp(pmHost.sw, pmHost.tw, pmHost.p))
    height: Math.max(1, pmHost.lerp(pmHost.sh, pmHost.th, pmHost.p))
    radius: Math.min(height / 2, pmHost.lerp(fromRadius, 26, pmHost.pc))
    color: pmHost.mix(fromColor, toColor, Math.min(1, pmHost.pc * 1.4))
    border.width: 1
    border.color: ga(pal.colorOnSurface, 0.08 * pmHost.pc)
    clip: true

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onWheel: (w) => { w.accepted = true; } }

    ColumnLayout {
        anchors.centerIn: parent
        width: pmHost.sw - 6
        spacing: 2
        opacity: Math.max(0, 1 - pmHost.pc * 3) * (globalState.glassMode ? 0.88 : 1.0)
        visible: opacity > 0.01
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: pmHost.srcTile ? pmHost.srcTile.morphIcon : ""
            font.family: "Material Symbols Rounded"; font.pixelSize: 24
            color: pal.colorOnPrimary
        }
        Text {
            Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
            text: pmHost.srcTile ? pmHost.srcTile.morphName : ""
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnPrimary
        }
    }

    Column {
        id: pmMenuCol
        width: pmHost.tw - 12
        x: (pmShape.width - width) / 2
        y: (pmShape.height - pmHost.th) / 2 + 6
        spacing: 4
        opacity: Math.max(0, Math.min(1, (pmHost.pc - 0.45) / 0.45))
        scale: 0.94 + 0.06 * opacity
        enabled: pmHost.isOpen
        Text {
            leftPadding: 10; topPadding: 4; bottomPadding: 2
            text: pmHost.srcTile && pmHost.srcTile.menuTitle ? pmHost.srcTile.menuTitle : tr("nce_perf")
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurfVar
        }
        Repeater {
            model: pmHost.srcTile && pmHost.kind !== "rec" ? pmHost.srcTile.opts : []
            Rectangle {
                id: pmOpt
                required property var modelData
                readonly property bool sel: pmHost.srcTile ? pmHost.srcTile.isSel(modelData.v) : false
                width: pmMenuCol.width
                height: 48
                radius: 16
                color: sel ? pal.primary : (pmOptHov.hovered ? ga(pal.primary, 0.14) : "transparent")
                Behavior on color { M3ColorAnim { duration: m3.durFast } }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 12
                    spacing: 12
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: pmOpt.modelData.icon
                        font.family: "Material Symbols Rounded"; font.pixelSize: 22
                        color: pmOpt.sel ? pal.colorOnPrimary : pal.primary
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0
                        Text {
                            text: pmOpt.modelData.name
                            font.family: globalState.fontPrimary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.DemiBold
                            color: pmOpt.sel ? pal.colorOnPrimary : pal.colorOnSurface
                        }
                        Text {
                            text: pmOpt.modelData.desc
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                            color: pmOpt.sel ? pal.colorOnPrimary : pal.colorOnSurfVar
                            opacity: 0.85
                        }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right; anchors.rightMargin: 12
                    visible: pmOpt.sel
                    text: ""
                    font.family: "Material Symbols Rounded"; font.pixelSize: 20
                    color: pal.colorOnPrimary
                }
                HoverHandler { id: pmOptHov }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var t = pmHost.srcTile, v = pmOpt.modelData.v;
                        pmHost.close();
                        if (t) t.choose(v);
                    }
                }
            }
        }

        Column {
            visible: pmHost.kind === "rec"
            width: pmMenuCol.width
            spacing: 4
            Text {
                leftPadding: 10; topPadding: 2
                text: tr("rec_area")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
                color: pal.muted
            }
            PmChipRow {
                width: parent.width
                options: [{ v: false, icon: "\ue5d0", label: tr("rec_full") },
                { v: true,  icon: "\ue3c2", label: tr("rec_region") }]
                current: globalState.recRegion
                onPicked: (v) => setRecRegion(v)
            }
            Text {
                leftPadding: 10; topPadding: 6
                text: tr("rec_quality")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
                color: pal.muted
            }
            PmChipRow {
                width: parent.width
                options: [{ v: "native", label: tr("rec_native") },
                { v: "2160",   label: "4K" },
                { v: "1440",   label: "1440p" },
                { v: "1080",   label: "1080p" },
                { v: "720",    label: "720p" }]
                current: globalState.recResolution
                onPicked: (v) => setRecResolution(v)
            }
            Text {
                leftPadding: 10; topPadding: 6
                text: tr("rec_fps")
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
                color: pal.muted
            }
            PmChipRow {
                width: parent.width
                options: [24, 30, 60, 120, 144].map(function (f) { return { v: f, label: f + "" }; })
                current: globalState.recFps
                onPicked: (v) => setRecFps(v)
            }
            Item { width: 1; height: 6 }
            Rectangle {
                id: pmRecStart
                width: parent.width
                height: 46
                radius: pmRecStartHov.pressed ? 14 : 23
                Behavior on radius { M3SpringAnim { token: "spatialDefault" } }
                color: pmRecStartHov.hovered ? Qt.lighter(pal.primary, 1.08) : pal.primary
                Behavior on color { M3ColorAnim { duration: m3.durFast } }
                Row {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\ue061"
                        font.family: "Material Symbols Rounded"; font.pixelSize: 20
                        color: pal.colorOnPrimary
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: globalState.recRegion ? tr("rec_start") + " · " + tr("rec_region") : tr("rec_start")
                        font.family: globalState.fontPrimary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.DemiBold
                        color: pal.colorOnPrimary
                    }
                }
                MouseArea {
                    id: pmRecStartHov
                    property bool hovered: containsMouse
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        globalState.playUiClick();
                        pmHost.close();
                        globalState.recStart("");
                    }
                }
            }
        }
    }
}
