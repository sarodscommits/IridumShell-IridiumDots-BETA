import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../controlcenter"
import "../ui"

// Overview dashboard page of the Control Center
Flickable {
    id: ncPage1Group
    anchors.fill: parent
    anchors.topMargin: navShown ? ncOvNav.height + 12 : 0
    readonly property bool vert:   parent ? !!parent.vert : true
    readonly property bool pageOn: parent ? !!parent.pageOn : false
    readonly property bool open:   parent ? !!parent.open : false
    readonly property bool live:   open && pageOn
    onPageOnChanged: {
        if (pageOn && open) globalState.reloadWeather();
        if (!pageOn) ncPage1.ncCalWidgetItem.selectedDay = -1;
    }
    onOpenChanged: {
        if (!open) {
            ncPage1.ncCalWidgetItem.selectedDay = -1;
            if (ncDashClipCard.ncClipBody.ncClipText.activeFocus) ncDashClipCard.ncClipBody.ncClipText.focus = false;
        }
    }
    readonly property var eqRep: ncPage4.ncEqRepeater
    property string navPicked: ""
    readonly property string navCurrent: {
        if (navPicked !== "" && globalState.ncDashOrder.indexOf(navPicked) !== -1) return navPicked;
        var order = globalState.ncDashOrder, best = "", bd = 1e9;
        var maxY = Math.max(1, contentHeight - height);
        var f = Math.max(0, Math.min(1, contentY / maxY));
        var ref = contentY + height * f;
        for (var i = 0; i < order.length; i++) {
            var p = ncDashLayer.vPos[order[i]];
            if (!p) continue;
            var d = ref < p.y ? p.y - ref : (ref > p.y + p.h ? ref - p.y - p.h : 0);
            if (d < bd) { bd = d; best = order[i]; }
        }
        return best;
    }
    function centerOn(k) {
        var p = ncDashLayer.vPos[k];
        if (!p || !vert) return;
        var maxY = Math.max(0, contentHeight - height);
        var t = Math.max(0, Math.min(maxY, p.y + p.h / 2 - height / 2));
        cancelFlick();
        ncNavScrollAnim.stop();
        navPicked = k;
        ncNavScrollAnim.to = t;
        ncNavScrollAnim.start();
    }
    NumberAnimation {
        id: ncNavScrollAnim
        target: ncPage1Group
        property: "contentY"
        duration: 520
        easing.type: Easing.BezierSpline
        easing.bezierCurve: [0.05, 0.7, 0.1, 1.0, 1, 1]
    }
    onMovementStarted: { ncNavScrollAnim.stop(); navPicked = ""; }
    onContentYChanged: if (!ncNavScrollAnim.running && navPicked !== "") navPicked = ""
    contentWidth: width
    contentHeight: ncPage1Group.vert ? ncDashLayer.vTotal : height
    readonly property bool navShown: vert && globalState.ncDashOrder.length > 0
    enabled: ncPage1Group.pageOn
    interactive: ncPage1Group.vert && ncPage1Group.pageOn
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    layer.enabled: ncPage1Group.vert && ncPage1Group.pageOn
    layer.smooth: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: ncPage1ViewMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
    Rectangle {
        id: ncPage1ViewMask
        width: ncPage1Group.width; height: ncPage1Group.height
        radius: 28
        color: "#FFFFFF"
        visible: false
        layer.enabled: true
        layer.smooth: true
    }
    ScrollBar.vertical: ScrollBar { policy: (ncPage1Group.vert && ncPage1Group.pageOn) ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }

    OverviewNav { id: ncOvNav }
    Connections {
        target: unifiedFrame
        function onBarVerticalChanged() { ncPage1Group.contentY = 0; }
    }
    Item {
        id: ncDashLayer
        anchors.fill: parent
        opacity: ncPage1Group.pageOn ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { M3NumberAnim {} }

        readonly property real gap: 14
        readonly property real colAW: Math.round(width * 0.46)
        readonly property real colBW: Math.round(width * 0.31)
        readonly property real colCW: width - colAW - colBW - gap * 2
        readonly property real colAX: 0
        readonly property real colBX: colAW + gap
        readonly property real colCX: colBX + colBW + gap
        readonly property real weatherH: Math.round(height * 0.42)
        readonly property real calH:     Math.round(height * 0.58)
        readonly property real fetchH:   Math.round(height * 0.56)

        readonly property bool vert: ncPage1Group.vert
        readonly property real layH: ncPage1Group.height
        readonly property real vWeatherH: 300
        readonly property real vCalH:     470
        readonly property real vMonH:     560
        readonly property real vAudH: Math.max(380, 58 + ncPage4.ncEqPresetPill.implicitHeight + 8
        + ncPage4.ncEqBandsCol.implicitHeight + 18)
        readonly property real vCavaH:    190
        readonly property real vFetchH:   360
        readonly property real vClipH:    300
        readonly property var vPos: {
            var hs = { weather: vWeatherH, cal: vCalH, mon: vMonH, aud: vAudH, clip: vClipH, fetch: vFetchH };
            var order = globalState.ncDashOrder, y = 0, o = {}, n = 0;
            for (var i = 0; i < order.length; i++) {
                var k = order[i];
                if (!(k in hs)) continue;
                o[k] = { y: y, h: hs[k], idx: n++ };
                y += hs[k] + gap;
            }
            o._end = Math.max(0, y - gap);
            o._n = n;
            return o;
        }
        function shown(k) { return globalState.ncDashOrder.indexOf(k) !== -1; }
        function vRect(k) { var p = vPos[k]; return p ? Qt.rect(0, p.y, width, p.h) : Qt.rect(0, 0, width, 0); }
        readonly property real vAddY: vPos._end + (vPos._n > 0 ? gap : 0)
        readonly property real vAddH: globalState.ncEditMode ? (globalState.ncDashHidden.length > 0 ? 112 : 64) : 0
        readonly property real vTotal: vAddH > 0 ? vAddY + vAddH : vPos._end
        readonly property rect rWeather: vert ? vRect("weather")
        : Qt.rect(colAX, 0, colAW, weatherH)
        readonly property rect rMon:     vert ? vRect("mon")
        : Qt.rect(colAX, weatherH + gap, colAW, layH - weatherH - gap)
        readonly property rect rCal:     vert ? vRect("cal")
        : Qt.rect(colBX, 0, colBW, calH)
        readonly property rect rFetch:   vert ? vRect("fetch")
        : Qt.rect(colCX, 0, colCW, fetchH)
        readonly property rect rClip:    vert ? vRect("clip")
        : Qt.rect(colBX, calH + gap, colBW, layH - calH - gap)
        readonly property rect rAud:     vert ? vRect("aud")
        : Qt.rect(colCX, fetchH + gap, colCW, layH - fetchH - gap)
    }

    Rectangle {
        id: ncDashMonitorCard
        opacity: ncDashLayer.opacity
        visible: ncDashLayer.visible && ncDashLayer.shown("mon")
        x: ncDashLayer.rMon.x
        y: ncDashLayer.rMon.y
        Behavior on y { enabled: globalState.ncEditMode; M3SpringAnim { token: "spatialDefault" } }
        width: ncDashLayer.rMon.width
        height: ncDashLayer.rMon.height
        radius: 28
        color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
        RowLayout {
            anchors.left: parent.left; anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 10
            Rectangle {
                width: 30; height: 30; radius: 15
                color: ga(pal.primary, 0.18)
                Text { anchors.centerIn: parent; text: "\ue322"; font.family: "Material Symbols Rounded"; font.pixelSize: 17; color: pal.primary }
            }
            Text { Layout.fillWidth: true; text: tr("ic_page_monitor"); font.family: globalState.fontPrimary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.Bold; color: pal.colorOnSurface; elide: Text.ElideRight }
            Text {
                Layout.maximumWidth: parent.width * 0.5
                text: globalState.fetchUptime !== "" ? "\ue425 " + globalState.fetchUptime : ""
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); color: pal.colorOnSurfVar
                elide: Text.ElideRight
            }
        }
    }


    OverviewAudioCard { id: ncDashAudioCard }

    OverviewClipCard { id: ncDashClipCard }

    OverviewWidgets { id: ncPage1 }

    MonitorPage {
        id: ncPage3
        anchors.fill: ncDashMonitorCard
        live: ncPage1Group.live
        opacity: ncPage1Group.pageOn ? 1 : 0
        visible: opacity > 0.01 && ncDashLayer.shown("mon")
        Behavior on opacity { M3NumberAnim {} }
    }

    OverviewMediaRow { id: ncPage4 }

    OverviewEditLayer { id: ncDashEditLayer }
}
