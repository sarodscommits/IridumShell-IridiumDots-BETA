import QtQuick
import "../ui"

// Card background that morphs into a rounded rectangle
Canvas {
    id: msc
    property Item host: null
    property bool peek: false
    property bool expanded: false
    property string shape: "pentagon"
    readonly property bool open: peek || expanded
    readonly property string _palSig: "" + pal.secondaryCont
    on_PalSigChanged: requestPaint()
    anchors.centerIn: parent

    width:  open ? host.width : 240
    height: expanded ? host.height : (open ? 224 : 240)
    rotation: open ? 360 : 0
    Behavior on width    { M3SpringAnim { token: "spatialSlow" } }
    Behavior on height   { M3SpringAnim { token: "spatialSlow" } }
    Behavior on rotation { M3SpringAnim { token: "spatialSlow" } }

    property real shapeT: open ? 1 : 0
    Behavior on shapeT { M3SpringAnim { token: "spatialSlow"; epsilon: 0.002 } }
    onShapeTChanged: requestPaint()
    onWidthChanged:  requestPaint()
    onHeightChanged: requestPaint()

    Connections {
        target: globalState
        function onGlassModeChanged() { msc.requestPaint() }
    }
    Connections {
        target: pal
        function onSurfaceElevatedChanged() { msc.requestPaint() }
    }

    Component.onCompleted: requestPaint()

    function restShape(minWH) {
        if (shape === "pentagon") {
            var apothem = minWH * 0.35, prc = apothem * 0.32;
            return { v: pentaVertices((apothem + prc) / Math.cos(Math.PI / 5)), rc: prc };
        }
        var trc = minWH * 0.0765, top = minWH * 0.4167, hw = minWH * 0.5917;
        return { v: [{ x: -trc, y: -top }, { x: trc, y: -top }, { x: hw, y: top }, { x: -hw, y: top }], rc: trc };
    }
    function morphVertices(t, halfW, halfH, rectRc) {
        var rest = restShape(Math.min(width, height));
        var rectV = shape === "pentagon" ? rectVertices5(halfW, halfH) : rectVertices(halfW, halfH);
        var verts = [];
        for (var k = 0; k < rest.v.length; k++)
        verts.push({ x: rest.v[k].x * (1 - t) + rectV[k].x * t, y: rest.v[k].y * (1 - t) + rectV[k].y * t });
        return { verts: verts, rc: rest.rc * (1 - t) + rectRc * t };
    }

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        var cx = width / 2, cy = height / 2;
        var rectRc = 32;
        var m = morphVertices(shapeT, width * 0.5 + rectRc, height * 0.5 + rectRc, rectRc);
        var steps = 720;
        ctx.beginPath();
        for (var i = 0; i <= steps; i++) {
            var a = (i / steps) * Math.PI * 2;
            var r = roundedPolygonRadius(a, m.verts, m.rc);
            var px = cx + Math.cos(a) * r, py = cy + Math.sin(a) * r;
            if (i === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
        }
        ctx.closePath();
        ctx.fillStyle = globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont);
        ctx.fill();
    }
}
