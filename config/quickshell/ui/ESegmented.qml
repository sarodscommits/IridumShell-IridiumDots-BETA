import QtQuick

// Single-select connected button group
Row {
    id: eseg
    property var options: []              // strings · [icon, label] · {label, icon, value}
    property var current: 0               // index, or selected value if options have one
    property string size: "xs"
    property string variant: "filled"
    property real itemWidth: -1
    signal picked(var value)
    spacing: 2
    function _val(o, i) { return (o && typeof o === "object" && o.value !== undefined) ? o.value : i }
    Repeater {
        model: eseg.options
        delegate: EButton {
            required property var modelData
            required property int index
            readonly property bool isObj: typeof modelData === "object" && modelData !== null && (modelData.label !== undefined || modelData.value !== undefined || modelData.icon !== undefined)
            size: eseg.size
            variant: eseg.variant
            fixedWidth: eseg.itemWidth
            text: typeof modelData === "string" ? modelData : (isObj ? (modelData.label || "") : modelData[1])
            icon: typeof modelData === "string" ? "" : (isObj ? (modelData.icon || "") : modelData[0])
            toggleable: true
            checked: eseg._val(modelData, index) === eseg.current
            connectedLeft: index > 0
            connectedRight: index < eseg.options.length - 1
            innerRadius: (eseg.size === "xs" || eseg.size === "xxs") ? 4 : 8
            onClicked: eseg.picked(eseg._val(modelData, index))
        }
    }
}
