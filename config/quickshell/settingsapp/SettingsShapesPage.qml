import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Settings: shapes page
Item {
    id: sdShapesPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "shapes"
    property string prev: "Circle"
    property string cur: m3.accentShape
    property bool auto: false
    function pick(n) {
        if (n === cur) { sdHeroR.target += 90; return; }
        prev = cur; cur = n;
        sdHeroM.snap(0); sdHeroM.target = 1; sdHeroR.target += 45;
    }
    Spring { id: sdHeroM; target: 1; token: "spatialDefault" }
    Spring { id: sdHeroR; target: 0; token: "spatialDefault"; eps: 0.01 }
    Timer {
        interval: 1400; repeat: true; running: sdShapesPage.auto && sdShapesPage.visible
        onTriggered: { var i = m3shp.names.indexOf(sdShapesPage.cur); sdShapesPage.pick(m3shp.names[(i + 1) % m3shp.names.length]); }
    }
    EPage {
        anchors.fill: parent
        anchors.leftMargin: 24; anchors.rightMargin: 12; anchors.bottomMargin: 16

        ESection {
            title: tr("sd_shape_morph")
            subtitle: tr("sd_shape_morph_d")
            icon: ""
            headerTrailing: EButton {
                variant: "tonal"; size: "s"
                toggleable: true; checked: sdShapesPage.auto
                icon: sdShapesPage.auto ? "" : ""
                text: tr("sd_autoplay")
                onClicked: sdShapesPage.auto = !sdShapesPage.auto
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 24
                Rectangle {
                    Layout.preferredWidth: 220; Layout.preferredHeight: 220
                    radius: m3.corner(36)
                    color: m3.glassy(m3.surfaceContainerHighest, 0.6)
                    MShape {
                        anchors.fill: parent; anchors.margins: 18
                        from: sdShapesPage.prev; to: sdShapesPage.cur
                        t: sdHeroM.value; rot: sdHeroR.value
                        fill: m3.primary; fill2: m3.tertiary
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    EText { role: "headlineMedium"; emph: true; text: sdShapesPage.cur; Layout.fillWidth: true; elide: Text.ElideRight }
                    EText { role: "bodyMedium"; color: m3.inkSurfaceVariant; text: tr("sd_accent_d"); Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 8
                        EButton {
                            size: "s"
                            icon: ""
                            text: sdShapesPage.cur === m3.accentShape ? tr("sd_accent_current") : tr("sd_accent_use")
                            enabled: sdShapesPage.cur !== m3.accentShape
                            onClicked: setM3("m3AccentShape", sdShapesPage.cur)
                        }
                        EButton { size: "s"; variant: "text"; icon: ""; text: tr("sd_reset"); onClicked: { resetM3(["m3AccentShape"]); sdShapesPage.pick("Cookie9Sided"); } }
                    }
                    Row {
                        spacing: 16
                        ELoading { size: 44 }
                        ELoading { size: 44; contained: true }
                        Item {
                            width: 44; height: 44
                            MShape { anchors.fill: parent; inset: 1.0; from: m3.accentShape; to: m3.accentShape; fill: m3.secondaryContainer }
                            Text { anchors.centerIn: parent; text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 20; color: m3.inkSecondaryContainer }
                        }
                    }
                }
            }
        }

        ESection {
            title: tr("sd_shape_library")
            subtitle: tr("sd_shape_library_d")
            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: m3shp.names
                    delegate: Item {
                        id: sdShapeCell
                        required property string modelData
                        readonly property bool sel: sdShapesPage.cur === modelData
                        readonly property bool acc: m3.accentShape === modelData
                        width: 88; height: 96
                        Spring { id: sdCellS; target: sdShapeCell.sel ? 1 : 0; token: "spatialFast"; eps: 0.002 }
                        Spring { id: sdCellH; target: sdCellMa.containsMouse ? 1 : 0; token: "effectsFast" }
                        Rectangle {
                            anchors.fill: parent
                            radius: 12 + 16 * Math.max(0, Math.min(1, sdCellS.value))
                            color: sdShapeCell.sel ? m3.secondaryContainer : m3.alpha(m3.inkSurface, 0.06 * sdCellH.value)
                        }
                        MShape {
                            x: 18; y: 8; width: 52; height: 52
                            from: sdShapeCell.modelData; to: sdShapeCell.modelData
                            rot: 20 * sdCellH.value
                            fill: sdShapeCell.acc ? m3.primary : (sdShapeCell.sel ? m3.inkSecondaryContainer : m3.inkSurfaceVariant)
                        }
                        EText {
                            anchors.horizontalCenter: parent.horizontalCenter; y: 68
                            width: parent.width - 6; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                            role: "labelSmall"; text: sdShapeCell.modelData
                            color: sdShapeCell.sel ? m3.inkSecondaryContainer : m3.inkSurfaceVariant
                        }
                        MouseArea { id: sdCellMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sdShapesPage.pick(sdShapeCell.modelData) }
                    }
                }
            }
        }

        ESection {
            title: tr("sd_corners")
            subtitle: tr("sd_corners_d")
            ESettingRow {
                icon: ""; label: tr("sd_corners"); desc: "×" + m3.cornerScale.toFixed(1)
                ESlider {
                    Layout.preferredWidth: 260
                    height: 36; trackH: 16; handleHOverride: 32
                    steps: 8
                    value: (globalState.m3CornerScale - 0.6) / 0.8
                    bubbleText: "×" + (0.6 + value * 0.8).toFixed(1)
                    onMoved: (v) => { globalState.m3CornerScale = Math.round((0.6 + v * 0.8) * 10) / 10; }
                    onReleased: savePrefs()
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 16
                ECard {
                    kind: "filled"; Layout.fillWidth: true
                    EText { role: "titleMedium"; emph: true; text: tr("sd_card") }
                    EText { role: "bodySmall"; color: m3.inkSurfaceVariant; text: tr("sd_card_d"); Layout.fillWidth: true; wrapMode: Text.WordWrap }
                }
                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    EListItem { width: parent.width; first: true; icon: ""; title: "Wi-Fi"; subtitle: globalState.netWifi || "—"; selected: true }
                    EListItem { width: parent.width; last: true; icon: ""; title: "Bluetooth"; subtitle: tr("sd_list_d") }
                }
            }
        }
    }
}
