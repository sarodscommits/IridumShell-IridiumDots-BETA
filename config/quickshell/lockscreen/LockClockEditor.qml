import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Clock style / size / font editor
Rectangle {
    id: lockClockEditor
    z: 22
    anchors.top: parent.top
    anchors.left: parent.left
    width: 320
    height: lockClockEditorCol.implicitHeight + 28
    radius: 20
    color: lockContent.editorDragging ? "transparent" : lockEdColors.cPopup
    Behavior on color { M3ColorAnim { duration: m3.durFast } }
    opacity: lockContent.editMode ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { M3NumberAnim {} }
    MouseArea { anchors.fill: parent; onClicked: hiddenInput.forceActiveFocus() }

    Column {
        id: lockClockEditorCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 14
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: lockContent.editorDragging ? 0 : 1
            Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
            text: {
                var s = globalState.lockClockStyle;
                return tr(s === "gear" ? "lock_clock_gear" : s === "circle" ? "lock_clock_circle"
                : s === "digitalV" ? "lock_clock_vertical" : "lock_clock_horizontal");
            }
            font.family: globalState.fontPrimary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.DemiBold
            color: lockEdColors.cPrimary
        }

        Repeater {
            model: [
            { key: "size", label: tr("lock_clock_size"),      glyph: "", min: 0.5, max: 1.5, prop: "lockClockScale" },
            { key: "font", label: tr("lock_clock_font_size"), glyph: "", min: 0.6, max: 1.6, prop: "lockClockFontScale" }
            ]
            Column {
                id: lockEdSlider
                required property var modelData
                width: lockClockEditorCol.width
                spacing: 4
                opacity: !lockContent.editorDragging || lockContent.draggingSlider === modelData.key ? 1 : 0
                Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
                readonly property real value: globalState[modelData.prop]
                readonly property real frac: (value - modelData.min) / (modelData.max - modelData.min)

                Row {
                    width: parent.width
                    spacing: 8
                    Text {
                        text: lockEdSlider.modelData.glyph
                        font.family: "Material Symbols Rounded"; font.pixelSize: 16
                        color: lockEdColors.cPrimary
                    }
                    Text {
                        width: parent.width - 60
                        text: lockEdSlider.modelData.label
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                        color: lockEdColors.cOnSurfVar
                        elide: Text.ElideRight
                    }
                    Text {
                        text: Math.round(lockEdSlider.value * 100) + "%"
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                        color: lockEdColors.cMuted
                    }
                }
                FractionSlider {
                    id: lockEdTrack
                    width: parent.width
                    property real displayPct: lockEdSlider.frac
                    value: displayPct
                    trackH: 14
                    handleHOverride: 20
                    height: 22
                    activeColor: lockEdColors.cFill
                    inactiveColor: lockEdColors.cTrack
                    steps: Math.round((lockEdSlider.modelData.max - lockEdSlider.modelData.min) / 0.05)
                    showBubble: false
                    onCanceled: lockContent.draggingSlider = ""
                    onFracPressed: { lockContent.draggingSlider = lockEdSlider.modelData.key; }
                    onFracMoved: (f) => { var md = lockEdSlider.modelData; var v = md.min + Math.round(f * lockEdTrack.steps) * 0.05; globalState[md.prop] = Math.round(Math.max(md.min, Math.min(md.max, v)) * 100) / 100; }
                    onFracReleased: { lockContent.draggingSlider = ""; savePrefs(); hiddenInput.forceActiveFocus(); }
                }
            }
        }

        Column {
            width: lockClockEditorCol.width
            spacing: 6
            opacity: lockContent.editorDragging ? 0 : 1
            Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
            Row {
                spacing: 8
                Text {
                    text: ""
                    font.family: "Material Symbols Rounded"; font.pixelSize: 16
                    color: lockEdColors.cPrimary
                }
                Text {
                    text: tr("lock_clock_font")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                    color: lockEdColors.cOnSurfVar
                }
            }
            SegmentedPill {
                width: parent.width
                columns: 3
                segHeight: 28
                fontSize: 12
                options: [{ value: "primary", label: tr("lock_font_follow_primary"), font: globalState.fontPrimary }].concat(
                globalState.fontCatalog.map(function(f) {
                    var r = globalState.fontResolved[f.key];
                    return { value: f.key, label: f.label, font: r.family, enabled: r.available };
                }))
                current: globalState.lockClockFontKey
                onPicked: (v) => { globalState.lockClockFontKey = v; savePrefs(); hiddenInput.forceActiveFocus(); }
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
