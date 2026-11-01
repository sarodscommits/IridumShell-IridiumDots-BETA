import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../panels"

// Toast notifications stack
PanelWindow {
    id: toastWindow
    WlrLayershell.namespace: "quickshell:toasts"
    color: "transparent"
    visible: toastModel.count > 0 || toastHideGrace.running
    Timer { id: toastHideGrace; interval: 600; repeat: false }
    Connections {
        target: toastModel
        function onCountChanged() { if (toastModel.count === 0) toastHideGrace.restart(); }
    }
    anchors.top:    true
    anchors.right:  true
    anchors.bottom: true
    implicitWidth: 320
    exclusiveZone: 0
    mask: Region { item: toastListView }

    property int _toastSeq: 0

    function pushToast(appName, summary, body, critical) {
        pushToastEx({ app: appName, summary: summary, body: body, critical: critical });
    }
    function pushToastEx(opts) {
        if (opts.tag) removeToastByTag(opts.tag);
        _toastSeq++;
        toastModel.append({
            toastUid: _toastSeq,
            toastAppName: opts.app || "",
            toastSummary: opts.summary || "",
            toastBody: opts.body || "",
            toastCritical: !!opts.critical,
            toastPersistent: !!opts.persistent,
            toastTag: opts.tag || "",
            toastIcon: opts.icon || "",
            toastTimeout: opts.timeout || 3000
        });
    }
    function removeToastByTag(tag) {
        for (var i = toastModel.count - 1; i >= 0; i--) {
            if (toastModel.get(i).toastTag === tag) toastModel.remove(i);
        }
    }
    function removeToastByUid(uid) {
        for (var i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).toastUid === uid) {
                toastModel.remove(i);
                return;
            }
        }
    }

    ListModel { id: toastModel }

    ListView {
        id: toastListView
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        anchors.topMargin: 60
        width: 300
        height: Math.min(contentHeight, parent.height - anchors.topMargin - anchors.bottomMargin)
        spacing: 10
        model: toastModel
        verticalLayoutDirection: ListView.BottomToTop
        interactive: false
        clip: false

        property color _colorOnSurface: pal.colorOnSurface
        property color _colorOnSurfVar: pal.colorOnSurfVar
        property color _muted:          pal.muted
        property color _primary:        pal.primary
        property color _onPrimary:      pal.colorOnPrimary
        property color _error:          pal.error
        property color _cardBg:         pal.surfaceElevated
        property color _outline:        pal.mutedDeep
        property color _ink:            pal.colorOnSurface
        property color _inkPrimary:     pal.primary
        property color _errCont:        pal.errorCont
        property color _onErrCont:      pal.colorOnErrorCont

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; from: 340; to: 0; duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.springCurveFast }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220 }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; to: 340; duration: 190; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedAccelerate }
                NumberAnimation { property: "opacity"; to: 0; duration: 190 }
            }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.springCurveFast }
        }

        delegate: Rectangle {
            id: toastDelegate
            required property int toastUid
            required property string toastAppName
            required property string toastSummary
            required property string toastBody
            required property bool toastCritical
            required property bool toastPersistent
            required property string toastIcon
            required property int toastTimeout
            width: ListView.view.width
            readonly property int _pad: 10
            readonly property int _iconSize: 32
            readonly property int _closeW: 52
            readonly property int _splitGap: 2
            readonly property color _bg: toastCritical ? toastListView._errCont : toastListView._cardBg
            readonly property color _fg: toastCritical ? toastListView._onErrCont : toastListView._ink
            readonly property int _dismissSize: _closeW + _splitGap
            readonly property int _gap: 10
            implicitHeight: Math.max(_iconSize, toastTextCol.height) + _pad * 2
            radius: 14
            color: "transparent"
            border.width: 0
            border.color: globalState.glassMode ? ga(toastListView._outline, 0.25) : ga(toastListView._outline, 0.4)
            clip: true

            ShellShadowCaster {
                parent: toastShadowRoot
                active: globalState.shellShadowNotifsOn
                grabTarget: toastDelegate
                x: toastShadowWindow.extraW + toastListView.x + toastListView.contentItem.x + toastDelegate.x
                y: toastListView.y + toastListView.contentItem.y + toastDelegate.y
                width: toastDelegate.width
                height: toastDelegate.height
                opacity: toastDelegate.opacity
            }

            Rectangle {
                x: 0; y: 0
                width: Math.max(0, toastListView.width - toastDelegate._closeW - toastDelegate._splitGap)
                height: toastDelegate.height
                topLeftRadius: 18; bottomLeftRadius: 18
                topRightRadius: 4; bottomRightRadius: 4
                color: globalState.glassMode ? ga(toastDelegate._bg, 0.88) : toastDelegate._bg
            }
            Rectangle {
                id: toastCloseSeg
                width: toastDelegate._closeW
                x: toastListView.width - width; y: 0
                height: toastDelegate.height
                z: 5
                color: "transparent"
                Spring { id: toastCloseR; token: "spatialFast"; eps: 0.05; target: toastCloseMa.pressed ? 2 : (toastCloseHov.hovered ? 10 : 4) }
                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: toastCloseR.value; bottomLeftRadius: toastCloseR.value
                    topRightRadius: 18; bottomRightRadius: 18
                    color: globalState.glassMode ? ga(toastDelegate._bg, 0.88) : toastDelegate._bg
                }
                Rectangle {
                    anchors.fill: parent
                    topLeftRadius: toastCloseR.value; bottomLeftRadius: toastCloseR.value
                    topRightRadius: 18; bottomRightRadius: 18
                    color: toastDelegate._fg
                    opacity: toastCloseMa.pressed ? 0.12 : (toastCloseHov.hovered ? 0.08 : 0)
                }
                Text {
                    anchors.centerIn: parent
                    text: "\ue5cd"; font.family: "Material Symbols Rounded"; font.pixelSize: 18
                    color: toastDelegate._fg
                }
                HoverHandler { id: toastCloseHov }
                MouseArea {
                    id: toastCloseMa
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: toastWindow.removeToastByUid(toastDelegate.toastUid)
                }
            }

            Timer {
                interval: toastDelegate.toastTimeout
                running: !toastDelegate.toastPersistent
                repeat: false
                onTriggered: toastWindow.removeToastByUid(toastDelegate.toastUid)
            }

            Item {
                x: toastDelegate._pad
                y: toastDelegate._pad
                width: toastDelegate._iconSize
                height: toastDelegate._iconSize
                Spring { id: toastIconSpin; target: 20; token: "spatialDefault"; eps: 0.05 }
                MShape {
                    anchors.fill: parent
                    inset: 1.0
                    from: m3.accentShape; to: m3.accentShape
                    rot: toastIconSpin.value
                    fill: toastDelegate.toastCritical ? toastListView._error : toastListView._inkPrimary
                }
                FadeIcon {
                    anchors.centerIn: parent
                    text: toastDelegate.toastIcon !== "" ? toastDelegate.toastIcon : ""
                    font.family: "Material Symbols Rounded"; font.pixelSize: 16
                    color: toastDelegate._bg
                }
                Component.onCompleted: { toastIconSpin.snap(-70); toastIconSpin.target = 20; }
            }

            Column {
                id: toastTextCol
                x: toastDelegate._pad + toastDelegate._iconSize + toastDelegate._gap
                y: toastDelegate._pad
                width: toastListView.width - x - toastDelegate._gap - toastDelegate._dismissSize - toastDelegate._pad
                spacing: 2
                Text {
                    width: parent.width
                    text: toastDelegate.toastAppName || " "
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); font.weight: Font.Medium
                    color: toastDelegate._fg
                    opacity: 0.7
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: toastDelegate.toastSummary
                    font.family: globalState.fontPrimary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.DemiBold
                    color: toastDelegate._fg
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    visible: toastDelegate.toastBody !== ""
                    text: toastDelegate.toastBody
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                    color: toastDelegate._fg
                    opacity: 0.85
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                id: toastDismiss
                visible: false
                x: toastListView.width - toastDelegate._pad - toastDelegate._dismissSize
                y: toastDelegate._pad
                width: toastDelegate._dismissSize
                height: toastDelegate._dismissSize
                radius: toastDelegate._dismissSize / 2
                color: toastDismissHov.hovered ? Qt.darker(toastListView._error, 1.5) : "transparent"
                Behavior on color { M3ColorAnim {} }
                Text {
                    anchors.centerIn: parent
                    text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 13
                    color: toastDismissHov.hovered ? toastListView._error : toastListView._muted
                }
                HoverHandler { id: toastDismissHov }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: toastWindow.removeToastByUid(toastDelegate.toastUid)
                }
            }
        }
    }
}
