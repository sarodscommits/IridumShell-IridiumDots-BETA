import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../panels"

// Notification pill and expandable list
Rectangle {
    id: lockNotifPill
    z: 20
    opacity: lockContent.blurDragging ? 0 : 1
    Behavior on opacity { M3NumberAnim { duration: m3.durFast } }

    property bool expanded: false
    property var _notifs: {
        var v = notificationsBackend.trackedNotifications.values.slice();
        v.reverse();
        return v;
    }
    property var _groups: globalState.groupNotifications(_notifs)
    readonly property real expandedH: Math.max(320, Math.min(640, _rowY + lockSessionRow.height))

    readonly property real _rowX: lockSessionRow.x
    readonly property real _rowY: lockSessionRow.y

    property color cavaColor: pal.primary
    readonly property var cava4: {
        var b = globalState.cavaBars;
        var groups = [[0, 4], [4, 8], [8, 13], [13, 18]];
        var out = [];
        for (var g = 0; g < 4; g++) {
            var m = 0;
            for (var k = groups[g][0]; k < groups[g][1]; k++) m = Math.max(m, b[k] || 0);
            out.push(Math.min(1, m));
        }
        return out;
    }

    property int  nowHour: new Date().getHours()
    readonly property bool isDay: nowHour >= 6 && nowHour < 19
    readonly property bool isCloudy: {
        var d = globalState.weatherDesc.toLowerCase();
        if (d === "") return false;
        return d.indexOf("clear") < 0 && d.indexOf("sunny") < 0 && d.indexOf("despejado") < 0 && d.indexOf("soleado") < 0;
    }
    readonly property string weatherGlyph: isCloudy ? "" : (isDay ? "" : "")
    readonly property color  weatherColor: isCloudy ? pal.colorOnSurfVar : (isDay ? "#FFC857" : "#D7E2F4")
    readonly property string weatherTempText: globalState.weatherTemp !== "" ? globalState.weatherTemp + "°" : "—"
    Timer {
        interval: 60000; repeat: true
        running: globalState.lockScreenActive
        onTriggered: lockNotifPill.nowHour = new Date().getHours()
    }

    Connections {
        target: globalState
        function onLockScreenActiveChanged() {
            if (!globalState.lockScreenActive) { lockNotifPill.expanded = false; lockClockStylePopup.shown = false; }
        }
    }

    x:      expanded ? _rowX : _rowX + lockSessionRow.lockNotifSlot.x
    y:      expanded ? Math.max(0, _rowY + lockSessionRow.height - expandedH) : _rowY
    width:  expanded ? lockSessionRow.width : lockSessionRow.lockNotifSlot.width
    height: expanded ? expandedH : lockSessionRow.height
    property real _outerR: expanded ? 24 : lockSessionRow.height / 2
    property real _innerR: expanded ? 24 : lockSessionRow.innerRadius
    topLeftRadius:     _innerR
    bottomLeftRadius:  _innerR
    topRightRadius:    _outerR
    bottomRightRadius: _outerR
    clip: true
    color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
    border.width: 1
    border.color: lockNotifPillHov.hovered && !expanded ? ga(pal.primary, 0.45) : "transparent"
    property bool morphing: false
    onExpandedChanged: { morphing = true; lockNotifMorphTimer.restart(); }
    Timer { id: lockNotifMorphTimer; interval: 520; onTriggered: lockNotifPill.morphing = false }
    Behavior on width  { enabled: lockNotifPill.morphing; M3SpringAnim { token: "spatialDefault" } }
    Behavior on height { enabled: lockNotifPill.morphing; M3SpringAnim { token: "spatialDefault" } }
    Behavior on x      { enabled: lockNotifPill.morphing; M3SpringAnim { token: "spatialDefault" } }
    Behavior on y      { enabled: lockNotifPill.morphing; M3SpringAnim { token: "spatialDefault" } }
    Behavior on _outerR { NumberAnimation { duration: 460; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    Behavior on _innerR { NumberAnimation { duration: 460; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    Behavior on color  { M3ColorAnim {} }
    Behavior on border.color { M3ColorAnim {} }

    HoverHandler { id: lockNotifPillHov }

    RowLayout {
        id: lockNotifPillRow
        anchors.centerIn: parent
        spacing: 6
        opacity: lockNotifPill.expanded ? 0 : 1
        visible: opacity > 0.01
        Behavior on opacity { M3NumberAnim { duration: lockNotifPill.expanded ? 120 : 260 } }

        FadeIcon {
            text: lockNotifPill._notifs.length > 0 ? "" : ""
            font.family: "Material Symbols Rounded"; font.pixelSize: 17
            color: lockNotifPill._notifs.length > 0 ? pal.primary : pal.colorOnSurfVar
        }
        Text {
            text: lockNotifPill._notifs.length
            font.family: globalState.fontPrimary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.DemiBold
            color: pal.colorOnSurface
        }
        Item { Layout.preferredWidth: 2 }
        FadeIcon {
            text: lockNotifPill.weatherGlyph
            font.family: "Material Symbols Rounded"; font.pixelSize: 17
            color: lockNotifPill.weatherColor
        }
        Text {
            text: lockNotifPill.weatherTempText
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Medium
            color: pal.colorOnSurface
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: !lockNotifPill.expanded && !lockContent.editMode
        visible: enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: { lockNotifPill.expanded = true; hiddenInput.forceActiveFocus(); }
    }

    LockNotificationList { id: lockNotifPanel }
}
