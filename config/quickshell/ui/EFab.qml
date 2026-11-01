import QtQuick

// M3E FAB, optionally extended
Item {
    id: efb
    property string icon: "add"
    property string text: ""
    property bool extended: text !== ""
    property string size: "fab"            // small · fab · medium · large
    property string tone: "primary"        // primary · secondary · tertiary · surface
    signal clicked()
    readonly property var spec: ({ small: [40, 12, 20, 8], fab: [56, 16, 24, 12], medium: [80, 20, 28, 16], large: [96, 28, 36, 20] })[size]
    readonly property var cols: tone === "secondary" ? [m3.secondaryContainer, m3.inkSecondaryContainer]
                              : tone === "tertiary" ? [m3.tertiaryContainer, m3.inkTertiaryContainer]
                              : tone === "surface" ? [m3.surfaceContainerHigh, m3.primary]
                              : [m3.primaryContainer, m3.inkPrimaryContainer]
    Spring { id: efbR; token: "spatialFast"; eps: 0.05; target: efbMa.pressed ? efb.spec[3] : efb.spec[1] }
    Spring { id: efbE; token: "spatialDefault"; eps: 0.002; target: efb.extended ? 1 : 0 }
    readonly property real ev: Math.max(0, efbE.value)
    implicitHeight: spec[0]
    implicitWidth: efbRow.implicitWidth + 2 * ((spec[0] - spec[2]) / 2 * (1 - Math.min(1, ev)) + 20 * ev)
    Rectangle { y: 3; width: parent.width; height: parent.height; radius: efbR.value; color: m3.alpha(m3.shadow, m3.dark ? 0.45 : 0.16) }
    Rectangle { anchors.fill: parent; radius: efbR.value; color: efb.cols[0]; Behavior on color { ColorAnimation { duration: 160 } } }
    StateLayer { anchors.fill: parent; radius: efbR.value; color: efb.cols[1]; hovered: efbMa.containsMouse; pressed: efbMa.pressed }
    Row {
        id: efbRow
        anchors.centerIn: parent
        spacing: 12 * efb.ev
        EIcon { name: efb.icon; size: efb.spec[2]; color: efb.cols[1]; anchors.verticalCenter: parent.verticalCenter }
        Item {
            width: efbLbl.implicitWidth * efb.ev; height: efbLbl.implicitHeight; clip: true
            anchors.verticalCenter: parent.verticalCenter
            EText { id: efbLbl; text: efb.text; role: "titleSmall"; color: efb.cols[1]; opacity: efb.ev }
        }
    }
    MouseArea { id: efbMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: efb.clicked() }
}
