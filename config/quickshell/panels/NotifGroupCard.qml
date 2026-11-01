import QtQuick
import Quickshell.Services.Notifications
import "../ui"

// Notification group card (stacked, expandable)
Item {
    id: ngc
    property var    items: []
    property string appName: ""
    property bool   expanded: false
    property bool   clearing: false
    property int    clearDelay: 0
    property color  cardColor:     "#2F282C"
    property color  hoverColor:    "#3A3337"
    property color  textColor:     "#E6E1E5"
    property color  subColor:      "#CAC4D0"
    property color  mutedColor:    "#938F99"
    property color  accentColor:   "#D0BCFF"
    property color  accentTextColor: "#381E72"
    property color  errorColor:    "#F2B8B5"
    property real   maxRadius: 28
    property real   edgeRadius: 30
    property bool   isFirst: false
    property bool   isLast: false
    property Item   clipFlick: null
    readonly property real _topInContent: y + (parent ? parent.y : 0)
    readonly property real cutTop: clipFlick ? Math.max(0, Math.min(height, clipFlick.contentY - _topInContent)) : 0
    readonly property real cutBot: clipFlick ? Math.max(0, Math.min(height, _topInContent + height - clipFlick.contentY - clipFlick.height)) : 0
    readonly property real visH: Math.max(0, height - cutTop - cutBot)
    function _r(base, cut) { return Math.min(cut > 0 ? maxRadius : base, visH / 2); }
    signal toggleExpand()
    signal dismissNotif(var notif)
    signal dismissGroup(var list)

    readonly property int  count: items ? items.length : 0
    readonly property bool grouped: count > 1
    readonly property bool open: grouped && expanded
    readonly property var  shown: open ? items : (count > 0 ? [items[0]] : [])
    readonly property bool critical: {
        for (var i = 0; i < count; i++)
        if (items[i] && items[i].urgency === NotificationUrgency.Critical) return true;
        return false;
    }
    readonly property int  pad: 12
    readonly property int  iconSize: 34
    readonly property int  gap: 10
    readonly property int  sideW: 64
    readonly property int  splitGap: 2
    readonly property real leftW: Math.max(0, width - sideW - splitGap)
    readonly property real cornerR: Math.min(height / 2, maxRadius)
    property real topR: Math.min(height / 2, isFirst ? Math.max(edgeRadius, maxRadius) : maxRadius)
    property real botR: Math.min(height / 2, isLast ? Math.max(edgeRadius, maxRadius) : maxRadius)
    Behavior on topR { NumberAnimation { duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    Behavior on botR { NumberAnimation { duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }

    property bool _removing: false
    property bool _clearNow: false
    readonly property bool _out: _removing || _clearNow
    onClearingChanged: if (!clearing) _clearNow = false
    Timer {
        interval: Math.max(1, ngc.clearDelay)
        running: ngc.clearing && !ngc._clearNow
        onTriggered: ngc._clearNow = true
    }
    Timer {
        id: ngcRemoveTimer
        interval: 330
        onTriggered: {
            ngc.dismissGroup(ngc.items ? ngc.items.slice() : []);
        }
    }
    function startRemove() {
        if (_removing) return;
        _removing = true;
        ngcRemoveTimer.start();
    }

    implicitHeight: Math.max(iconSize, ngcBody.height) + pad * 2
    height: implicitHeight
    Behavior on implicitHeight { M3SpringAnim { token: "spatialDefault" } }
    clip: true
    opacity: _out ? 0 : 1
    Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
    transform: Translate {
        x: ngc._out ? -ngc.width : 0
        Behavior on x { M3SpringAnim { token: "spatialFast" } }
    }

    Rectangle {
        y: ngc.cutTop
        width: ngc.leftW; height: ngc.visH
        visible: height > 0.5
        topLeftRadius:     ngc._r(ngc.topR, ngc.cutTop)
        bottomLeftRadius:  ngc._r(ngc.botR, ngc.cutBot)
        topRightRadius:    ngc._r(4, ngc.cutTop)
        bottomRightRadius: ngc._r(4, ngc.cutBot)
        color: ngc.cardColor
    }
    MouseArea {
        width: ngc.leftW; height: ngc.height
        enabled: ngc.grouped
        cursorShape: ngc.grouped ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: ngc.toggleExpand()
    }

    Item {
        x: ngc.width - width
        width: ngc.sideW; height: ngc.height
        Rectangle {
            y: ngc.cutTop
            width: parent.width; height: ngc.visH
            visible: height > 0.5
            topLeftRadius:     ngc._r(ngcSideMa.pressed ? 2 : (ngcSideHov.hovered ? 12 : 4), ngc.cutTop)
            bottomLeftRadius:  ngc._r(ngcSideMa.pressed ? 2 : (ngcSideHov.hovered ? 12 : 4), ngc.cutBot)
            Behavior on topLeftRadius { M3SpringAnim { token: "spatialFast" } }
            Behavior on bottomLeftRadius { M3SpringAnim { token: "spatialFast" } }
            topRightRadius:    ngc._r(ngc.topR, ngc.cutTop)
            bottomRightRadius: ngc._r(ngc.botR, ngc.cutBot)
            color: ngcSideHov.hovered
            ? (globalState.colorMode === "light"
            ? Qt.tint(ngc.cardColor, Qt.rgba(ngc.errorColor.r, ngc.errorColor.g, ngc.errorColor.b, 0.2))
            : Qt.darker(ngc.errorColor, 1.6))
            : ngc.cardColor
            Behavior on color { M3ColorAnim {} }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -2
            y: Math.min((parent.height - height) / 2, ngc.pad + ngc.iconSize / 2 - height / 2)
            text: ""
            font.family: "Material Symbols Rounded"; font.pixelSize: 18
            color: ngcSideHov.hovered ? ngc.errorColor : ngc.mutedColor
            scale: ngcSideHov.hovered ? 1.12 : 1
            Behavior on scale { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
        }
        HoverHandler { id: ngcSideHov }
        MouseArea {
            id: ngcSideMa
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: ngc.startRemove()
        }
    }

    Item {
        x: ngc.pad; y: ngc.pad
        width: ngc.iconSize; height: ngc.iconSize
        Spring { id: ngcIconRot; target: ngc.open ? 40 : 0; token: "spatialDefault"; eps: 0.05 }
        MShape {
            anchors.fill: parent
            inset: 1.0
            from: ngc.critical ? "Sunny" : m3.accentShape; to: from
            rot: ngcIconRot.value
            fill: ngc.critical ? ngc.errorColor : ngc.accentColor
        }
        Text {
            anchors.centerIn: parent
            text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 17
            color: ngc.accentTextColor
        }
    }

    Column {
        id: ngcBody
        x: ngc.pad + ngc.iconSize + ngc.gap
        y: ngc.pad
        width: Math.max(0, ngc.leftW - x - ngc.pad)
        spacing: 2

        NotifGroupHeader { card: ngc }

        Repeater {
            model: ngc.shown
            delegate: NotifRow { card: ngc }
        }
    }
}
