import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Lockscreen options card (layout, blur, cava)
Rectangle {
    id: lockOptionsCard
    z: 25
    anchors.top: parent.top
    anchors.right: parent.right
    width: 280
    height: lockOptCol.implicitHeight + 28
    radius: 20
    color: lockContent.blurDragging ? "transparent" : lockEdColors.cPopup
    Behavior on color { M3ColorAnim { duration: m3.durFast } }
    opacity: lockContent.editMode && (!lockContent.editorDragging || lockContent.blurDragging) ? 1 : 0
    visible: opacity > 0.01
    scale: lockContent.editMode ? 1 : 0.92
    transformOrigin: Item.TopRight
    Behavior on opacity { M3NumberAnim {} }
    Behavior on scale   { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
    MouseArea { anchors.fill: parent; onClicked: hiddenInput.forceActiveFocus() }

    ColumnLayout {
        id: lockOptCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 14
        spacing: 10

        Text {
            opacity: lockContent.blurDragging ? 0 : 1; Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
            text: tr("lock_options")
            font.family: globalState.fontPrimary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.Bold
            color: lockEdColors.cOnSurface
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            opacity: lockContent.blurDragging ? 0 : 1; Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
            Text { text: tr("lock_layout"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); color: lockEdColors.cOnSurfVar }
            SegmentedPill {
                Layout.fillWidth: true
                options: [{ value: "vertical",   label: tr("lock_layout_vertical"),   icon: "\ue8f2" },
                { value: "horizontal", label: tr("lock_layout_horizontal"), icon: "\ue8ec" }]
                current: globalState.lockLayout
                onPicked: (v) => { globalState.lockLayout = v; savePrefs(); hiddenInput.forceActiveFocus(); }
                trackColor: lockEdColors.cOff
                hoverColor: lockEdColors.cHoverBg
                selectedColor: lockEdColors.cPrimary
                textColor: lockEdColors.cOnSurface
                selectedTextColor: lockEdColors.cOnPrimary
                iconColor: lockEdColors.cPrimary
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Behavior on opacity { M3NumberAnim { duration: m3.durFast } }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: "\ue3a4"
                    font.family: "Material Symbols Rounded"; font.pixelSize: 16
                    color: lockEdColors.cPrimary
                }
                Text {
                    Layout.fillWidth: true
                    text: tr("lock_blur_level")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                    color: lockEdColors.cOnSurfVar
                    elide: Text.ElideRight
                }
                Text {
                    text: Math.round(globalState.lockBlurLevel * 100) + "%"
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                    color: lockEdColors.cMuted
                }
            }
            FractionSlider {
                id: lockBlurTrack
                Layout.fillWidth: true
                property real displayPct: globalState.lockBlurLevel
                value: displayPct
                trackH: 14
                handleHOverride: 20
                height: 22
                activeColor: lockEdColors.cFill
                inactiveColor: lockEdColors.cTrack
                steps: 20
                showBubble: false
                onCanceled: lockContent.draggingSlider = ""
                onFracPressed: { lockContent.draggingSlider = "blur"; }
                onFracMoved: (f) => { globalState.lockBlurLevel = Math.round(Math.round(f * lockBlurTrack.steps) * 0.05 * 100) / 100; }
                onFracReleased: { lockContent.draggingSlider = ""; savePrefs(); hiddenInput.forceActiveFocus(); }
            }
        }

        Repeater {
            model: [
            { prop: "lockCavaEnabled", label: tr("desktop_cava"), glyph: "" }
            ]
            RowLayout {
                id: lockOptSwitchRow2
                opacity: lockContent.blurDragging ? 0 : 1; Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
                required property var modelData
                readonly property bool on: globalState[modelData.prop]
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: lockOptSwitchRow2.modelData.glyph
                    font.family: "Material Symbols Rounded"; font.pixelSize: 16
                    color: lockEdColors.cPrimary
                }
                Text {
                    Layout.fillWidth: true
                    text: lockOptSwitchRow2.modelData.label
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                    color: lockEdColors.cOnSurfVar
                    elide: Text.ElideRight
                }
                ESwitch {
                    checked: lockOptSwitchRow2.on
                    scaleF: 0.75
                    onToggled: {
                        globalState[lockOptSwitchRow2.modelData.prop] = !globalState[lockOptSwitchRow2.modelData.prop];
                        savePrefs();
                        hiddenInput.forceActiveFocus();
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            opacity: lockContent.blurDragging ? 0 : (globalState.lockCavaEnabled ? 1 : 0.4)
            enabled: globalState.lockCavaEnabled
            Behavior on opacity { M3NumberAnim { duration: m3.durFast } }

            Text { text: tr("cava_edge"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); color: lockEdColors.cOnSurfVar }
            SegmentedPill {
                Layout.fillWidth: true
                fontSize: Math.round(11 * globalState.fontScale)
                options: [{ value: "top", label: tr("edge_top") }, { value: "bottom", label: tr("edge_bottom") },
                { value: "left", label: tr("edge_left") }, { value: "right", label: tr("edge_right") }]
                current: globalState.lockCavaEdge
                onPicked: (v) => { globalState.lockCavaEdge = v; savePrefs(); hiddenInput.forceActiveFocus(); }
                trackColor: lockEdColors.cOff
                hoverColor: lockEdColors.cHoverBg
                selectedColor: lockEdColors.cPrimary
                textColor: lockEdColors.cOnSurface
                selectedTextColor: lockEdColors.cOnPrimary
                iconColor: lockEdColors.cPrimary
            }

            Text { text: tr("cava_style"); font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); color: lockEdColors.cOnSurfVar }
            SegmentedPill {
                Layout.fillWidth: true
                options: [{ value: "bars", label: tr("cava_style_bars") }, { value: "wave", label: tr("cava_style_wave") }]
                current: globalState.lockCavaStyle
                onPicked: (v) => { globalState.lockCavaStyle = v; savePrefs(); hiddenInput.forceActiveFocus(); }
                trackColor: lockEdColors.cOff
                hoverColor: lockEdColors.cHoverBg
                selectedColor: lockEdColors.cPrimary
                textColor: lockEdColors.cOnSurface
                selectedTextColor: lockEdColors.cOnPrimary
                iconColor: lockEdColors.cPrimary
            }
        }
    }
}
