import QtQuick
import "../ui"

// Scrolling synced lyrics view
Item {
    id: lsc
    property real fontSize: 13
    property real activeScale: 1.2
    property color activeColor: m3.primary
    property color textColor: pal.colorOnSurface
    property color dimColor: pal.muted
    property int align: Text.AlignLeft
    property string fontFamily: globalState.fontPrimary
    property real centerAt: 0.42
    property real fadeEdge: 0.22
    property bool clickToSeek: true
    property bool showEmpty: true
    readonly property var lines: globalState.mediaLyrics
    readonly property bool synced: globalState.mediaLyricsSynced
    readonly property int cur: synced ? globalState.mediaLyricIndex : -1
    clip: true
    function follow(instant) {
        if (!synced || lscList.dragging || lscList.flicking || lscHold.running) return;
        var i = Math.max(0, cur);
        var it = lscList.itemAtIndex(i);
        if (!it) { lscList.positionViewAtIndex(i, ListView.Center); return; }
        var minY = lscList.originY - lscList.topMargin;
        var maxY = Math.max(minY, lscList.originY + lscList.contentHeight + lscList.bottomMargin - lscList.height);
        var to = Math.max(minY, Math.min(maxY, it.y + it.height / 2 - lscList.height * lsc.centerAt));
        if (instant) { lscAnim.stop(); lscList.contentY = to; }
        else { lscAnim.to = to; lscAnim.restart(); }
    }
    onCurChanged: follow(false)
    onLinesChanged: Qt.callLater(function () { lscHold.stop(); lscList.positionViewAtBeginning(); lsc.follow(true); })
    onHeightChanged: Qt.callLater(function () { lsc.follow(true); })
    NumberAnimation { id: lscAnim; target: lscList; property: "contentY"; duration: 560; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.standardCurve }
    Timer { id: lscHold; interval: 2500; onTriggered: lsc.follow(false) }
    ListView {
        id: lscList
        anchors.fill: parent
        visible: lsc.lines.length > 0
        model: lsc.lines.length
        spacing: Math.round(lsc.fontSize * 0.6)
        boundsBehavior: Flickable.StopAtBounds
        topMargin: lsc.synced ? lsc.height * lsc.centerAt : 4
        bottomMargin: lsc.synced ? lsc.height * (1 - lsc.centerAt) : 4
        onMovementStarted: { lscAnim.stop(); lscHold.restart(); }
        onMovementEnded: lscHold.restart()
        delegate: Item {
            id: lscRow
            required property int index
            readonly property var line: lsc.lines[index] || ({ s: "" })
            readonly property bool isCur: index === lsc.cur
            readonly property bool past: lsc.synced && lsc.cur >= 0 && index < lsc.cur
            readonly property real vy: y - lscList.contentY
            readonly property real edge: Math.max(0, Math.min(1, Math.min(vy + height, lscList.height - vy) / Math.max(1, lscList.height * lsc.fadeEdge)))
            width: lscList.width
            height: lscTxt.implicitHeight * (isCur ? lsc.activeScale : 1)
            Behavior on height { M3NumberAnim { duration: 260 } }
            opacity: edge * (!lsc.synced ? 1 : (isCur ? 1 : (past ? 0.42 : 0.68)))
            Behavior on opacity { NumberAnimation { duration: 220 } }
            Text {
                id: lscTxt
                width: lscRow.width / lsc.activeScale
                x: lsc.align === Text.AlignHCenter ? (lscRow.width - width) / 2 : (lsc.align === Text.AlignRight ? lscRow.width - width : 0)
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: lsc.align
                text: lscRow.line.s !== "" ? lscRow.line.s : "♪"
                wrapMode: Text.WordWrap
                font.family: lsc.fontFamily
                font.pixelSize: Math.max(7, Math.round(lsc.fontSize))
                font.weight: lscRow.isCur ? Font.Black : Font.DemiBold
                color: lscRow.isCur ? lsc.activeColor : (lsc.synced ? lsc.dimColor : lsc.textColor)
                Behavior on color { ColorAnimation { duration: 240 } }
                scale: lscRow.isCur ? lsc.activeScale : 1
                Behavior on scale { M3SpringAnim { token: "spatialDefault"; epsilon: 0.005 } }
                transformOrigin: lsc.align === Text.AlignHCenter ? Item.Center : (lsc.align === Text.AlignRight ? Item.Right : Item.Left)
            }
            MouseArea {
                anchors.fill: parent
                enabled: lsc.clickToSeek && lsc.synced
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: { lscHold.stop(); audioPlayer.seekAbsolute(Math.max(0, lscRow.line.t)); }
            }
        }
    }
    Column {
        anchors.centerIn: parent
        visible: lsc.showEmpty && lsc.lines.length === 0
        spacing: 8
        ELoading {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: globalState.mediaLyricsLoading
            running: visible
            size: Math.max(24, Math.min(44, lsc.fontSize * 3))
        }
        EmptyHint {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !globalState.mediaLyricsLoading
            key: globalState.mediaTitle
            text: globalState.mediaTitle === "" ? tr("no_media_playing") : tr("lyrics_none")
            fontSize: Math.max(9, Math.round(lsc.fontSize * 0.9))
            shapeSize: Math.max(12, lsc.fontSize * 1.4)
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: globalState.mediaLyricsLoading
            text: tr("lyrics_searching")
            font.family: globalState.fontSecondary; font.pixelSize: Math.max(8, Math.round(lsc.fontSize * 0.85))
            color: pal.muted
        }
    }
}
