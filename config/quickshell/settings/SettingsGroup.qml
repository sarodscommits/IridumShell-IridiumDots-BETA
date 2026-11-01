import QtQuick
import QtQuick.Layouts
import "../ui"

// Collapsible settings group with a shaped icon header
ColumnLayout {
    id: sgRoot
    property string title: ""
    property string icon: ""
    property string summary: ""
    property bool expanded: false
    property color accent: "#D0BCFF"
    property color textColor: "#CAC4D0"
    property color lineColor: "#49454F"
    property color hoverColor: "#3A3337"
    property color cardColor: "#201A1E"
    property color cardOpenColor: "#241E22"
    property color innerColor: "#2F282C"
    property color iconContColor: "#4A4458"
    property color titleColor: "#E6E1E5"
    property color subColor: "#CAC4D0"
    property bool innerBlock: true
    property string titleFont: ""
    property string bodyFont: ""
    property real fontScale: 1
    property int titleSize: 11
    property real bodySpacing: 8
    signal toggled()
    default property alias content: sgHolder.data
    property var _rows: []
    function _relayout() {
        var first = -1, last = -1;
        for (var i = 0; i < _rows.length; i++) if (_rows[i].shown) { if (first < 0) first = i; last = i; }
        for (var k = 0; k < _rows.length; k++) {
            _rows[k].topR = (k === first) ? m3.corner(20) : 4;
            _rows[k].botR = (k === last) ? m3.corner(20) : 4;
        }
    }
    function _build() {
        var kids = [];
        for (var i = 0; i < sgHolder.children.length; i++) kids.push(sgHolder.children[i]);
        var prev = null;
        for (var j = 0; j < kids.length; j++) {
            var c = kids[j];
            if (!sgRoot.innerBlock) { c.parent = sgBody; continue; }
            var isText = (c.textFormat !== undefined) && c.children.length === 0;
            if (isText && prev) { c.parent = prev.col; continue; }
            var w = sgRowComp.createObject(sgBody, { hostItem: c });
            c.parent = w.col;
            w.shownChanged.connect(sgRoot._relayout);
            sgRoot._rows.push(w);
            prev = w;
        }
        _relayout();
    }
    Component.onCompleted: Qt.callLater(_build)

    Component {
        id: sgRowComp
        Rectangle {
            id: sgRow
            property Item hostItem: null
            readonly property bool shown: hostItem ? hostItem.visible : false
            property alias col: sgRowCol
            property real topR: 20
            property real botR: 20
            Layout.fillWidth: true
            Layout.preferredHeight: shown ? Math.max(56, sgRowCol.implicitHeight + 24) : 0
            implicitHeight: Layout.preferredHeight
            opacity: shown ? 1 : 0
            topLeftRadius: topR; topRightRadius: topR
            bottomLeftRadius: botR; bottomRightRadius: botR
            color: sgRoot.innerColor
            ColumnLayout {
                id: sgRowCol
                anchors.left: parent.left; anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 16; anchors.rightMargin: 16
                spacing: 4
            }
        }
    }
    property alias headerTrailing: sgTrail.data
    spacing: 0

    Rectangle {
        id: sgCard
        Layout.fillWidth: true
        Layout.preferredHeight: sgHeader.height + sgClip.height
        radius: m3.corner(28)
        color: sgRoot.expanded ? sgRoot.cardOpenColor : (sgHov.hovered ? Qt.tint(sgRoot.cardColor, Qt.rgba(sgRoot.titleColor.r, sgRoot.titleColor.g, sgRoot.titleColor.b, 0.08)) : sgRoot.cardColor)
        Behavior on color { M3ColorAnim {} }
        clip: true

        Item { id: sgHolder; width: 0; height: 0; opacity: 0 }

        Item {
            id: sgHeader
            width: parent.width
            height: 64

            HoverHandler { id: sgHov; cursorShape: Qt.PointingHandCursor }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sgRoot.toggled()
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16; anchors.rightMargin: 12
                spacing: 16
                Item {
                    visible: sgRoot.icon !== ""
                    Layout.preferredWidth: 40; Layout.preferredHeight: 40
                    Spring { id: sgMorph; token: "spatialDefault"; eps: 0.002; target: sgRoot.expanded ? 1 : 0 }
                    MShape {
                        anchors.fill: parent
                        inset: 1.0
                        from: "Circle"; to: m3.accentShape
                        t: sgMorph.value
                        rot: sgMorph.value * 40
                        fill: sgRoot.expanded ? sgRoot.accent : sgRoot.iconContColor
                    }
                    FadeIcon {
                        anchors.centerIn: parent
                        text: sgRoot.icon
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: Math.round(18 * sgRoot.fontScale)
                        color: sgRoot.expanded ? sgRoot.cardOpenColor : sgRoot.titleColor
                        Behavior on color { M3ColorAnim {} }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2
                    Text {
                        Layout.fillWidth: true
                        text: sgRoot.title
                        font.family: sgRoot.titleFont
                        font.pixelSize: Math.round((sgRoot.titleSize + 3) * sgRoot.fontScale)
                        font.weight: Font.DemiBold
                        color: sgRoot.titleColor
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: sgRoot.summary !== ""
                        text: sgRoot.summary
                        font.family: sgRoot.bodyFont !== "" ? sgRoot.bodyFont : sgRoot.titleFont
                        font.pixelSize: Math.round(11 * sgRoot.fontScale)
                        color: sgRoot.subColor
                        elide: Text.ElideRight
                    }
                }
                RowLayout {
                    id: sgTrail
                    spacing: 8
                    visible: children.length > 0
                }
                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 20
                    color: sgHov.hovered ? Qt.rgba(sgRoot.titleColor.r, sgRoot.titleColor.g, sgRoot.titleColor.b, 0.08) : "transparent"
                    Behavior on color { M3ColorAnim {} }
                    Text {
                        anchors.centerIn: parent
                        text: "\ue5cf"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 22
                        color: sgRoot.expanded ? sgRoot.accent : sgRoot.subColor
                        rotation: sgRoot.expanded ? 180 : 0
                        Behavior on rotation { M3SpringAnim { token: "spatialDefault" } }
                        Behavior on color { M3ColorAnim {} }
                    }
                }
            }
        }

        Item {
            id: sgClip
            y: sgHeader.height
            width: parent.width
            height: sgRoot.expanded ? sgInner.height + 16 : 0
            Behavior on height { M3SpringAnim { token: "spatialDefault" } }
            clip: true
            visible: sgRoot.expanded || height > 0.5

            Item {
                id: sgInner
                x: 16
                width: parent.width - 32
                height: sgBody.implicitHeight

                ColumnLayout {
                    id: sgBody
                    width: parent.width
                    spacing: sgRoot.innerBlock ? 2 : sgRoot.bodySpacing
                    enabled: sgRoot.expanded
                    opacity: sgRoot.expanded ? 1 : 0
                    Behavior on opacity { M3NumberAnim {} }
                }
            }
        }
    }
}
