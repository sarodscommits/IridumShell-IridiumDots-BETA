import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../rightpanel"

// Media page cards: controls, equalizer and visualizer
ColumnLayout {
    id: mediaPanelUi
    readonly property var cava: mediaCavaCard.cavaCanvas
    readonly property var eqRep: mediaEqCard.eqRepeater
    readonly property var drag: mediaControlsCard.mediaPanelDrag
    anchors.fill: parent
    spacing: 14

    MediaControlsCard { id: mediaControlsCard }

    MediaEqCard { id: mediaEqCard }

    MediaCavaCard { id: mediaCavaCard }
}
