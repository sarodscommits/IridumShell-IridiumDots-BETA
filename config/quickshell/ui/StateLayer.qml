import QtQuick

// M3 state layer: 8% on hover, 12% on press
Rectangle {
    id: sl
    property bool hovered: false
    property bool pressed: false
    property real hoverOpacity: 0.08
    property real pressOpacity: 0.12
    Spring { id: slS; token: "effectsFast"; target: sl.pressed ? sl.pressOpacity : (sl.hovered ? sl.hoverOpacity : 0) }
    opacity: Math.max(0, slS.value)
}
