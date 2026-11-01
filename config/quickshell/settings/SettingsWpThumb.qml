import QtQuick
import QtQuick.Effects
import "../ui"

// Wallpaper thumbnail used in settings
Item {
    id: swtRoot
    property string source: ""
    property real radius: 10
    property Item maskItem: null
    property int loadWidth: 360
    property color placeholderColor: "#1E1B26"
    property color iconColor: "#49454F"

    Rectangle {
        anchors.fill: parent
        radius: swtRoot.radius
        color: swtRoot.placeholderColor
        Text {
            anchors.centerIn: parent
            visible: swtImg.status !== Image.Ready
            text: "\ue3f4"
            font.family: "Material Symbols Rounded"; font.pixelSize: 24
            color: swtRoot.iconColor
        }
    }
    Image {
        id: swtImg
        anchors.fill: parent
        source: swtRoot.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        sourceSize.width: swtRoot.loadWidth
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { M3NumberAnim {} }
        layer.enabled: swtRoot.maskItem !== null
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: swtRoot.maskItem
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.05
        }
    }
}
