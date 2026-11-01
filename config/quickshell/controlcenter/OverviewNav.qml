import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Page selector of the overview dashboard
Rectangle {
    id: ncOvNav
    parent: ncPage1Group.parent
    z: 5
    visible: ncPage1Group.navShown && ncDashLayer.visible
    opacity: ncDashLayer.opacity
    readonly property real pad: 5
    readonly property real segH: 38
    readonly property real segGap: 4
    readonly property var keys: globalState.ncDashOrder.filter(function (k) { return !!ncDashEditLayer.info[k]; })
    readonly property int n: keys.length
    readonly property real innerW: width - pad * 2
    readonly property real labelW: {
        var m = 0;
        for (var i = 0; i < ncOvNavRep.count; i++) {
            var it = ncOvNavRep.itemAt(i);
            if (it) m = Math.max(m, it.labelW);
        }
        return m;
    }
    readonly property real selW: n <= 1 ? innerW : Math.min(innerW * 0.46, labelW + 19 + 6 + 28)
    readonly property real otherW: n <= 1 ? 0 : (innerW - selW - segGap * (n - 1)) / (n - 1)
    x: 0; y: 0
    width: parent ? parent.width : 0
    height: segH + pad * 2
    radius: height / 2
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
    Row {
        x: ncOvNav.pad; y: ncOvNav.pad
        spacing: ncOvNav.segGap
        Repeater {
            id: ncOvNavRep
            model: ncOvNav.keys
            Rectangle {
                id: ncOvNavSeg
                required property string modelData
                readonly property var inf: ncDashEditLayer.info[modelData]
                readonly property bool sel: ncPage1Group.navCurrent === modelData
                readonly property real labelW: ncOvNavLabel.implicitWidth
                property real act: sel ? 1 : 0
                Behavior on act { M3SpringAnim { token: "spatialDefault"; epsilon: 0.002 } }
                width: ncOvNav.otherW + (ncOvNav.selW - ncOvNav.otherW) * act
                height: ncOvNav.segH
                radius: height / 2
                color: Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, Math.max(0, Math.min(1, act)))
                Rectangle { anchors.fill: parent; radius: parent.radius; color: pal.colorOnSurface; opacity: (ncOvNavHov.hovered && !ncOvNavSeg.sel) ? 0.08 : 0; Behavior on opacity { NumberAnimation { duration: m3.durFast } } }
                clip: true
                Row {
                    id: ncOvNavContent
                    anchors.centerIn: parent
                    spacing: 6 * ncOvNavSeg.act
                    FadeIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ncOvNavSeg.inf ? ncOvNavSeg.inf.icon : ""
                        font.family: "Material Symbols Rounded"; font.pixelSize: 19
                        color: Qt.tint(pal.primary, Qt.rgba(pal.colorOnPrimary.r, pal.colorOnPrimary.g, pal.colorOnPrimary.b, ncOvNavSeg.act))
                    }
                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: ncOvNavLabel.implicitWidth * ncOvNavSeg.act
                        height: ncOvNavLabel.implicitHeight
                        clip: true
                        visible: width > 0.5
                        Text {
                            id: ncOvNavLabel
                            text: ncOvNavSeg.inf ? ncOvNavSeg.inf.name : ""
                            opacity: ncOvNavSeg.act
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.DemiBold
                            color: pal.colorOnPrimary
                        }
                    }
                }
                HoverHandler { id: ncOvNavHov }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { globalState.playUiClick(); ncPage1Group.centerOn(ncOvNavSeg.modelData); }
                }
            }
        }
    }
}
