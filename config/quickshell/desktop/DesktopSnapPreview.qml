import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui/SvgPaths.js" as SvgPaths

// Grid snap preview shown while dragging desktop widgets
Item {
    id: desktopSnapPreview
    z: -1
    visible: desktopWidgetLayer.draggingWidget !== null
    opacity: 0.28
    property Item dw: desktopWidgetLayer.draggingWidget
    property var target: dw ? desktopWidgetLayer.gridTargetFor(dw) : null
    x: target ? target.col * desktopWidgetLayer.gridCell : 0
    y: target ? target.row * desktopWidgetLayer.gridCell : 0
    width: dw ? dw.width : 0
    height: dw ? dw.height : 0
    transform: [
    Scale {
        origin.x: 0; origin.y: 0
        xScale: desktopWidgetLayer.animScale
        yScale: desktopWidgetLayer.animScale
    },
    Translate {
        x: (desktopWidgetLayer.widgetBoxX + desktopSnapPreview.x * desktopWidgetLayer.animScale - desktopSnapPreview.x)
        y: (desktopWidgetLayer.widgetBoxY + desktopSnapPreview.y * desktopWidgetLayer.animScale - desktopSnapPreview.y)
    }
    ]

    Rectangle {
        visible: desktopSnapPreview.dw === musicWidgetRoot
        anchors.fill: parent
        radius: 32
        color: containerDark(pal.secondaryCont)
    }

    Canvas {
        readonly property string _palSig: "" + pal.secondaryCont
        on_PalSigChanged: requestPaint()
        visible: desktopSnapPreview.dw === clockWidgetRootDesktop
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var cx = width / 2, cy = height / 2;
            var gearR = Math.min(width, height) / 2 / 1.02;
            var teeth = 12, rBase = gearR * 0.88, amp = gearR * 0.14;
            var steps = 720;
            ctx.beginPath();
            for (var i = 0; i <= steps; i++) {
                var a = (i / steps) * Math.PI * 2;
                var c = Math.cos(teeth / 2 * a);
                var r = rBase + amp * c * c;
                var px = cx + Math.cos(a) * r;
                var py = cy + Math.sin(a) * r;
                if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
            }
            ctx.closePath();
            ctx.fillStyle = containerDark(pal.secondaryCont).toString();
            ctx.fill();
        }
        onVisibleChanged: if (visible) requestPaint()
        Component.onCompleted: requestPaint()
    }

    Canvas {
        readonly property string _palSig: "" + pal.secondaryCont
        on_PalSigChanged: requestPaint()
        visible: desktopSnapPreview.dw === calWidgetRootDesktop
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var cx = width / 2, cy = height / 2;
            var apothemTarget = Math.min(width, height) * 0.35;
            var pentaRc = apothemTarget * 0.32;
            var pentaR = (apothemTarget + pentaRc) / Math.cos(Math.PI / 5);
            var verts = pentaVertices(pentaR);
            var steps = 720;
            ctx.beginPath();
            for (var i = 0; i <= steps; i++) {
                var a = (i / steps) * Math.PI * 2;
                var r = roundedPolygonRadius(a, verts, pentaRc);
                var px = cx + Math.cos(a) * r;
                var py = cy + Math.sin(a) * r;
                if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
            }
            ctx.closePath();
            ctx.fillStyle = containerDark(pal.secondaryCont).toString();
            ctx.fill();
        }
        onVisibleChanged: if (visible) requestPaint()
        Component.onCompleted: requestPaint()
    }

    Item {
        visible: desktopSnapPreview.dw === weatherWidgetRoot
        anchors.centerIn: parent
        width: 244; height: 244
        scale: 220 / 244
        Rectangle {
            anchors.centerIn: parent
            width: 100; height: 70
            radius: height / 2
            rotation: -45
            scale: 2.0
            color: containerDark(pal.secondaryCont)
        }
    }

    Rectangle {
        visible: desktopSnapPreview.dw === clockDetailWidgetRoot ||
        desktopSnapPreview.dw === weatherDetailWidgetRoot ||
        desktopSnapPreview.dw === calDetailWidgetRoot
        anchors.fill: parent
        radius: 32
        color: containerDark(pal.secondaryCont)
    }

    Rectangle {
        visible: desktopSnapPreview.dw === sysWidgetRoot ||
        desktopSnapPreview.dw === gpuWidgetRoot ||
        desktopSnapPreview.dw === chargeWidgetRoot ||
        desktopSnapPreview.dw === dateWidgetRoot ||
        desktopSnapPreview.dw === bigTimeWidgetRoot ||
        desktopSnapPreview.dw === mediaPillWidgetRoot ||
        desktopSnapPreview.dw === countdownWidgetRoot ||
        desktopSnapPreview.dw === weatherPillsWidgetRoot ||
        desktopSnapPreview.dw === lyricsCardWidgetRoot ||
        desktopSnapPreview.dw === lyricsLineWidgetRoot ||
        desktopSnapPreview.dw === lyricsBubbleWidgetRoot
        anchors.fill: parent
        radius: Math.min(width, height) / 2.4
        color: containerDark(pal.secondaryCont)
    }

    Shape {
        visible: desktopSnapPreview.dw === cpuWidgetRoot ||
        desktopSnapPreview.dw === ramWidgetRoot ||
        desktopSnapPreview.dw === diskWidgetRoot
        x: 0; y: 0; width: 100; height: 100
        transformOrigin: Item.TopLeft
        scale: parent.width / 100
        antialiasing: true
        ShapePath {
            fillColor: containerDark(pal.secondaryCont)
            strokeColor: "transparent"
            PathSvg {
                path: desktopSnapPreview.dw === cpuWidgetRoot
                ? SvgPaths.pentagon
                : desktopSnapPreview.dw === ramWidgetRoot
                ? SvgPaths.arch
                : SvgPaths.flower
            }
        }
    }
}
