import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Face of the desktop calendar widget
Item {
    id: desktopCalendarFace
    anchors.fill: parent
    readonly property var faceCanvas: calWidgetFaceCanvas
    Item {
        id: calWidgetVisual
        anchors.centerIn: parent
        width: parent.width / globalState.calWidgetScaleDesktop; height: parent.height / globalState.calWidgetScaleDesktop
        scale: globalState.calWidgetScaleDesktop

        Canvas {
            readonly property string _palSig: "" + pal.secondaryCont
            on_PalSigChanged: requestPaint()
            id: calWidgetFaceCanvas
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var cx = width / 2, cy = height / 2;

                var apothemTarget = Math.min(width, height) * 0.35;
                var pentaRc = apothemTarget * 0.32;
                var pentaR  = (apothemTarget + pentaRc) / Math.cos(Math.PI / 5);
                var verts = pentaVertices(pentaR);

                var steps = 720, pts = [], bx0 = 1e9, bx1 = -1e9, by0 = 1e9, by1 = -1e9;
                for (var i = 0; i <= steps; i++) {
                    var a = (i / steps) * Math.PI * 2;
                    var r = roundedPolygonRadius(a, verts, pentaRc);
                    var qx = Math.cos(a) * r, qy = Math.sin(a) * r;
                    pts.push([qx, qy]);
                    bx0 = Math.min(bx0, qx); bx1 = Math.max(bx1, qx); by0 = Math.min(by0, qy); by1 = Math.max(by1, qy);
                }
                var fk = Math.min(width / (bx1 - bx0), height / (by1 - by0));
                var ox = width / 2 - (bx0 + bx1) / 2 * fk, oy = height / 2 - (by0 + by1) / 2 * fk;
                ctx.beginPath();
                for (var k = 0; k < pts.length; k++) {
                    var px = ox + pts[k][0] * fk, py = oy + pts[k][1] * fk;
                    if (k === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
                }
                ctx.closePath();
                ctx.fillStyle = (globalState.glassMode ? ga(containerDark(pal.secondaryCont), currentFrameOpacity()) : containerDark(pal.secondaryCont)).toString();
                ctx.fill();
            }
            Connections {
                target: globalState
                function onGlassModeChanged() { calWidgetFaceCanvas.requestPaint(); }
                function onGlassQuickshellOpacityChanged() { calWidgetFaceCanvas.requestPaint(); }
                function onGlassQuickshellEnabledChanged() { calWidgetFaceCanvas.requestPaint(); }
            }
            Connections {
                target: pal
                function onSurfaceElevatedChanged() { calWidgetFaceCanvas.requestPaint(); }
            }
            Component.onCompleted: requestPaint()
        }

        Column {
            anchors.centerIn: parent
            spacing: -6
            Text {
                visible: globalState.calShowDayMonth
                anchors.horizontalCenter: parent.horizontalCenter
                text: calWidgetRootDesktop.cdDay < 10 ? "0" + calWidgetRootDesktop.cdDay : "" + calWidgetRootDesktop.cdDay
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(40 * globalState.fontScale); font.weight: Font.Bold
                color: pal.primary
            }
            Text {
                visible: globalState.calShowDayMonth
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.locale(localeCode()).standaloneDayName(calWidgetRootDesktop.cdWeekday, Locale.ShortFormat) + " " +
                Qt.locale(localeCode()).standaloneMonthName(calWidgetRootDesktop.cdMonth, Locale.ShortFormat)
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(15 * globalState.fontScale); font.weight: Font.Bold
                color: pal.colorOnSurface
            }
            Text {
                visible: globalState.calShowYear
                anchors.horizontalCenter: parent.horizontalCenter
                text: "" + calWidgetRootDesktop.cdYear
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                color: pal.colorOnSurfVar
            }
        }
    }
}
