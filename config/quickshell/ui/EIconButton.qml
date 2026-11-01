import QtQuick
import "ButtonColors.js" as ButtonColors

// M3E icon button
Item {
    id: eib
    property string icon: ""
    property string variant: "standard"    // standard · filled · tonal · outlined · error
    property string size: "s"              // xxs · xs · s · m · l · xl
    property string widthMode: "default"   // narrow · default · wide
    property bool toggleable: false
    property bool checked: false
    property bool square: false
    property color tint: "transparent"
    property real iconRotation: 0
    property bool busy: false
    readonly property alias pressed: eibMa.pressed
    readonly property alias hovered: eibMa.containsMouse
    signal clicked()
    signal rightClicked()
    readonly property var spec: ({ xxs: [24, 16, 8, 6], xs: [32, 20, 12, 8], s: [40, 24, 12, 8], m: [56, 24, 16, 12], l: [96, 32, 28, 16], xl: [136, 40, 28, 16] })[size]
    readonly property real h: spec[0]
    readonly property real wf: widthMode === "narrow" ? 0.8 : (widthMode === "wide" ? 1.35 : 1)
    Spring { id: eibW; token: "spatialFast"; eps: 0.05; target: eib.h * eib.wf }
    implicitWidth: eibW.value
    implicitHeight: h
    opacity: enabled ? 1 : 0.38
    readonly property bool sq: toggleable && checked ? !square : square
    Spring { id: eibR; token: "spatialFast"; eps: 0.05; target: eibMa.pressed ? eib.spec[3] : (eib.sq ? eib.spec[2] : eib.h / 2) }
    readonly property var cols: ButtonColors.colors(m3, variant, toggleable, checked, tint, "standard")
    readonly property real rad: Math.max(0, Math.min(Math.min(width, height) / 2, eibR.value))
    Rectangle {
        anchors.fill: parent; radius: eib.rad; color: eib.cols[0]
        border.width: eib.cols[2] ? 1 : 0; border.color: eib.cols[2] ? eib.cols[2] : "transparent"
        Behavior on color { M3ColorAnim { duration: m3.durFast } }
    }
    StateLayer { anchors.fill: parent; radius: eib.rad; color: eib.cols[1]; hovered: eibMa.containsMouse; pressed: eibMa.pressed }
    EIcon { anchors.centerIn: parent; visible: !eib.busy; name: eib.icon; size: eib.spec[1]; color: eib.cols[1]; filled: eib.checked || eib.variant === "filled"; rotation: eib.iconRotation }
    ELoading { anchors.centerIn: parent; visible: eib.busy; running: eib.busy; size: eib.spec[1]; color: eib.cols[1] }
    MouseArea {
        id: eibMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (m) => { if (m.button === Qt.RightButton) eib.rightClicked(); else eib.clicked() }
    }
}
