import QtQuick

Item {
    // M3E connected button group (single select)
    id: segRoot
    property var options: []
    property var current
    signal picked(var value)

    property int columns: 0
    property real segHeight: 30
    property real gap: 2
    property real rowGap: 6
    property real innerRadius: 4
    property real outerRadius: -1
    property real selRadius: -1          // unused, kept for compat
    property real selGrowY: 0            // unused, kept for compat
    property real selGrowX: 0
    property bool stacked: false
    property int fontSize: Math.round(12 * globalState.fontScale)
    property int iconSize: stacked ? 26 : 16
    property string fontFamily: globalState.fontSecondary

    property color trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
    property color hoverColor: Qt.lighter(trackColor, 1.35)   // unused, kept for compat
    property color selectedColor: m3.primary
    property color textColor: m3.inkSurfaceVariant
    property color selectedTextColor: m3.inkPrimary
    property color iconColor: textColor

    readonly property int _n: options ? options.length : 0
    readonly property int _cols: _n === 0 ? 1 : (columns > 0 ? Math.min(columns, _n) : _n)
    readonly property int _rows: _n === 0 ? 0 : Math.ceil(_n / _cols)
    readonly property real _oR: outerRadius >= 0 ? outerRadius : segHeight / 2

    implicitWidth: _cols * 84 + (_cols - 1) * gap
    implicitHeight: _rows * segHeight + Math.max(0, _rows - 1) * rowGap + 2 * selGrowY

    readonly property alias bump: segBump
    BumpCtl {
        id: segBump
    }

    Repeater {
        model: segRoot._n
        delegate: SegmentedPillCell { pill: segRoot }
    }
}
