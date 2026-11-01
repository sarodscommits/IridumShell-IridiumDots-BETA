import QtQuick
import QtQuick.Layouts
import "../ui"

// Weather stat bar (humidity, wind, feels-like)
Item {
    id: statRoot

    required property color colorPrimary
    required property color colorOnSurfVar
    required property color trackColor

    property string label:     ""
    property string valueText: ""
    property real   pct:       0

    property bool waveEffect: false
    property real wavePhase:  0

    implicitHeight: 49

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: statRoot.label
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                color: statRoot.colorOnSurfVar
                opacity: 0.85
            }
            Text {
                text: statRoot.valueText
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                color: statRoot.colorOnSurfVar
            }
        }

        Item {
            Layout.fillWidth: true
            height: 18

            Canvas {
                id: statWaveCanvas
                anchors.fill: parent
                antialiasing: true
                property real pct:        Math.max(0, Math.min(1, statRoot.pct))
                property real phase:      statRoot.wavePhase
                property bool wave:       statRoot.waveEffect
                property color fillColor: statRoot.colorPrimary
                property color trackCol:  statRoot.trackColor
                onPctChanged:       requestPaint()
                onPhaseChanged:     requestPaint()
                onWaveChanged:      requestPaint()
                onFillColorChanged: requestPaint()
                onTrackColChanged:  requestPaint()
                onWidthChanged:     requestPaint()
                onHeightChanged:    requestPaint()
                Component.onCompleted: requestPaint()

                Behavior on pct { M3SpringAnim { token: "spatialSlow"; epsilon: 0.002 } }

                function strokeLine(ctx, color, w) {
                    ctx.strokeStyle = color.toString();
                    ctx.lineWidth = w;
                    ctx.lineCap = "round";
                    ctx.stroke();
                }
                function drawTrack(ctx, cy, r, lineW, filled) {
                    var trackStart = Math.max(filled + 10, r);
                    var trackEnd = width - r;
                    if (trackEnd <= trackStart) return;
                    ctx.beginPath();
                    ctx.moveTo(trackStart, cy);
                    ctx.lineTo(trackEnd, cy);
                    strokeLine(ctx, trackCol, lineW);
                }
                function drawFill(ctx, cy, r, lineW, filled) {
                    var teeth = 11;
                    var amp = (wave && pct > 0.03 && pct < 0.985) ? Math.min(5.5, cy - r) : 0;
                    var fillStart = r, fillEnd = Math.min(filled, width - r);
                    if (fillEnd <= fillStart) {
                        ctx.beginPath();
                        ctx.arc(r, cy, r, 0, Math.PI * 2);
                        ctx.fillStyle = fillColor.toString();
                        ctx.fill();
                        return;
                    }
                    ctx.beginPath();
                    for (var x = fillStart; x <= fillEnd; x += 1) {
                        var c = Math.cos(teeth / 2 * ((x / width) * Math.PI * 2 - phase));
                        var y = cy - amp * (c * c);
                        if (x === fillStart) ctx.moveTo(x, y); else ctx.lineTo(x, y);
                    }
                    strokeLine(ctx, fillColor, lineW);
                }
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (width <= 0 || height <= 0) return;
                    var cy = height / 2;
                    var lineW = Math.max(3, height - 12);
                    var filled = width * pct;
                    drawTrack(ctx, cy, lineW / 2, lineW, filled);
                    if (pct > 0) drawFill(ctx, cy, lineW / 2, lineW, filled);
                }
            }
        }
    }
}
