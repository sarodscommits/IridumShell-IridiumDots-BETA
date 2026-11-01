import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../ui/SvgPaths.js" as SvgPaths

// Password entry with shape-dots feedback
Item {
    id: lockPwArea
    property alias lockEditBtn: lockEditBtn
    property alias pwBarOuter: pwBarOuter
    property alias pwShapesArea: pwShapesArea
    property alias shakeSeq: shakeSeq
    x: lockContent.modulesCX - width / 2
    opacity: lockContent.blurDragging ? 0 : 1
    Behavior on opacity { M3NumberAnim { duration: m3.durFast } }
    y: lockSessionRow.y + lockSessionRow.height + lockContent.modGap
    implicitWidth:  Math.max(320, Math.min(560, lockContent.width * 0.42))
    implicitHeight: pwBarOuter.implicitHeight

    property real shakeOffset: 0

    readonly property bool absorbByEdit: lockContent.editMode
    readonly property bool absorbByPw:   !absorbByEdit && lockContent.typing
    property real gap:         (absorbByPw || absorbByEdit) ? 0 : 2
    property real innerRadius: (absorbByPw || absorbByEdit) ? pwBarOuter.height / 2 : 4
    property real editW:       absorbByPw ? 0 : absorbByEdit ? implicitWidth : (implicitWidth - 4) / 5
    Behavior on gap         { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
    Behavior on innerRadius { M3SpringAnim { token: "spatialDefault" } }
    Behavior on editW       { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }

    Rectangle {
        id: lockEditBtn
        anchors.bottom: parent.bottom
        x: pwBarOuter.x + pwBarOuter.width + lockPwArea.gap
        width: lockPwArea.editW
        height: pwBarOuter.height
        topLeftRadius:     lockPwArea.innerRadius
        bottomLeftRadius:  lockPwArea.innerRadius
        topRightRadius:    height / 2
        bottomRightRadius: height / 2
        clip: true
        opacity: lockPwArea.absorbByPw || lockContent.editorDragging ? 0 : 1
        visible: width > 0.5
        Behavior on opacity { M3NumberAnim {} }
        color: {
            var c = lockContent.editMode ? lockEdColors.cPrimary
            : (lockEditBtnHov.hovered ? pal.surfaceVar : containerDark(pal.secondaryCont));
            return (globalState.glassMode && !lockContent.editMode) ? ga(c, 0.6) : c;
        }
        Behavior on color { M3ColorAnim {} }
        FadeIcon {
            anchors.centerIn: parent
            text: lockContent.editMode ? "\ue5ca" : "\ue3c9"
            font.family: "Material Symbols Rounded"; font.pixelSize: 22
            color: lockContent.editMode ? lockEdColors.cOnPrimary : lockEdColors.cOnSurfVar
            scale: lockEditBtnHov.hovered ? 1.12 : 1
            Behavior on scale { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
        }
        HoverHandler { id: lockEditBtnHov }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            enabled: !lockPwArea.absorbByPw
            onClicked: {
                lockContent.editMode = !lockContent.editMode;
                lockNotifPill.expanded = false;
                lockClockStylePopup.shown = false;
                hiddenInput.forceActiveFocus();
            }
        }
    }

    SequentialAnimation {
        id: shakeSeq
        PropertyAnimation { target: lockPwArea; property: "shakeOffset"; to: -14; duration: 60 }
        PropertyAnimation { target: lockPwArea; property: "shakeOffset"; to:  14; duration: 60 }
        PropertyAnimation { target: lockPwArea; property: "shakeOffset"; to: -10; duration: 50 }
        PropertyAnimation { target: lockPwArea; property: "shakeOffset"; to:  10; duration: 50 }
        PropertyAnimation { target: lockPwArea; property: "shakeOffset"; to:  -6; duration: 40 }
        PropertyAnimation { target: lockPwArea; property: "shakeOffset"; to:   6; duration: 40 }
        PropertyAnimation { target: lockPwArea; property: "shakeOffset"; to:   0; duration: 30 }
    }

    Rectangle {
        id: pwBarOuter
        anchors.bottom: parent.bottom
        x: lockPwArea.shakeOffset
        width: Math.max(0, lockPwArea.implicitWidth - lockPwArea.editW - lockPwArea.gap)
        clip: true
        visible: width > 0.5
        opacity: lockPwArea.absorbByEdit ? 0 : 1
        Behavior on opacity { M3NumberAnim {} }
        implicitHeight: pwBarCol.implicitHeight + 20
        topLeftRadius:     height / 2
        bottomLeftRadius:  height / 2
        topRightRadius:    lockPwArea.innerRadius
        bottomRightRadius: lockPwArea.innerRadius
        color: {
            var c = lockState.failed ? pal.errorCont : containerDark(pal.secondaryCont);
            return globalState.glassMode ? ga(c, 0.6) : c;
        }
        border.color: lockState.checking ? pal.primary
        : lockState.failed   ? pal.error
        :                      "transparent"
        border.width: (lockState.checking || lockState.failed) ? 1.5 : 0
        Behavior on color        { M3ColorAnim {} }
        Behavior on border.color { M3ColorAnim {} }

        ColumnLayout {
            id: pwBarCol
            anchors.fill: parent; anchors.margins: 10; spacing: 6

            RowLayout {
                Layout.fillWidth: true; spacing: 6
                Text {
                    text: "\ue899"; font.family: "Material Symbols Rounded"; font.pixelSize: 13
                    color: lockState.failed ? pal.error : pal.muted
                    Behavior on color { M3ColorAnim {} }
                }
                Text {
                    text: lockState.failed   ? "Incorrect password" :
                    lockState.checking ? "Verifying\u2026"    : "Password"
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale); font.weight: Font.Medium
                    color: lockState.failed ? pal.error : pal.muted
                    Behavior on color { M3ColorAnim {} }
                }
                Item { Layout.fillWidth: true }
                ELoading {
                    size: 16
                    visible: lockState.checking
                    running: lockState.checking
                    color: pal.primary
                }
            }

            Item {
                id: pwShapesArea
                Layout.fillWidth: true
                height: 30
                clip: true

                readonly property var shapeDefs: [
                { name: "Circle",         rot: 0,  scaleAmt: 1.0,  path: "M50,5 A45,45 0 1,0 50,95 A45,45 0 1,0 50,5 Z" },
                { name: "Square",         rot: 0,  scaleAmt: 1.0,  path: "M32,10 L68,10 Q90,10 90,32 L90,68 Q90,90 68,90 L32,90 Q10,90 10,68 L10,32 Q10,10 32,10 Z" },
                { name: "Arch",           rot: 0,  scaleAmt: 1.0,  path: SvgPaths.arch },
                { name: "Fan",            rot: 0,  scaleAmt: 1.0,  path: "M15,73 L15,25 Q15,15 24.97,15.71 A70,70 0 0,1 84.29,75.04 Q85,85 75,85 L27,85 Q15,85 15,73 Z" },
                { name: "Pill",           rot: 45, scaleAmt: 1.0,  path: "M35,15 L65,15 A35,35 0 0,1 65,85 L35,85 A35,35 0 0,1 35,15 Z" },
                { name: "Triangle",       rot: 0,  scaleAmt: 1.18, path: "M59.15,25.84 L82.42,66.16 Q91.57,82.00 73.28,82.00 L26.72,82.00 Q8.43,82.00 17.58,66.16 L40.85,25.84 Q50.00,10.00 59.15,25.84 Z" },
                { name: "Diamond",        rot: 0,  scaleAmt: 1.18, path: "M62.88,16.88 L83.12,37.12 Q96.00,50.00 83.12,62.88 L62.88,83.12 Q50.00,96.00 37.12,83.12 L16.88,62.88 Q4.00,50.00 16.88,37.12 L37.12,16.88 Q50.00,4.00 62.88,16.88 Z" },
                { name: "Pentagon",       rot: 0,  scaleAmt: 1.0,  path: SvgPaths.pentagon },
                { name: "Gem",            rot: 90, scaleAmt: 1.3,  path: "M55.60,9.60 L72.40,20.40 Q78.00,24.00 78.00,34.40 L78.00,65.60 Q78.00,76.00 72.40,79.60 L55.60,90.40 Q50.00,94.00 44.40,90.40 L27.60,79.60 Q22.00,76.00 22.00,65.60 L22.00,34.40 Q22.00,24.00 27.60,20.40 L44.40,9.60 Q50.00,6.00 55.60,9.60 Z" },
                { name: "Flower",         rot: 0,  scaleAmt: 1.2,  path: SvgPaths.flower },
                { name: "4-Sided Cookie", rot: 0,  scaleAmt: 1.0,  path: "M55.73,12.07 L63.36,22.84 Q69.09,30.91 77.16,36.64 L87.93,44.27 Q96.00,50.00 87.93,55.73 L77.16,63.36 Q69.09,69.09 63.36,77.16 L55.73,87.93 Q50.00,96.00 44.27,87.93 L36.64,77.16 Q30.91,69.09 22.84,63.36 L12.07,55.73 Q4.00,50.00 12.07,44.27 L22.84,36.64 Q30.91,30.91 36.64,22.84 L44.27,12.07 Q50.00,4.00 55.73,12.07 Z" },
                { name: "Arrow",          rot: 0,  scaleAmt: 1.18, path: "M59.15,25.84 L82.42,66.16 Q91.57,82.00 73.28,82.00 Q50,74 26.72,82.00 Q8.43,82.00 17.58,66.16 L40.85,25.84 Q50.00,10.00 59.15,25.84 Z" }
                ]

                function shapeForIndex(idx) {
                    var n = shapeDefs.length;
                    return shapeDefs[((idx % n) + n) % n];
                }

                Text {
                    anchors.centerIn: parent
                    visible: lockState.passwordChars.length === 0
                    text: "Type your password\u2026"
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                    color: pal.colorOnSurfVar
                }

                Row {
                    id: pwShapesRow
                    x: Math.min((parent.width - width) / 2, parent.width - width)
                    y: (parent.height - height) / 2
                    spacing: 2
                    visible: lockState.passwordChars.length > 0

                    Behavior on x {
                        M3SpringAnim { token: "spatialFast" }
                    }

                    Repeater {
                        id: pwShapesRepeater
                        model: pwShapeModel

                        property color _primary: pal.primary

                        Item {
                            id: pwSlot
                            width: 22; height: 22

                            readonly property bool isActive: index === lockState.passwordChars.length - 1
                            readonly property var  shapeDef: pwShapesArea.shapeDefs[((shapeIdx % pwShapesArea.shapeDefs.length) + pwShapesArea.shapeDefs.length) % pwShapesArea.shapeDefs.length]

                            readonly property real shapeSize: isActive ? 30 : 21
                            readonly property real targetScale: (shapeSize / 100) * shapeDef.scaleAmt

                            property real appearScale: 0
                            NumberAnimation {
                                id: appearAnim
                                target: pwSlot
                                property: "appearScale"
                                from: 0; to: 1
                                duration: 260
                                easing.type: Easing.BezierSpline; easing.bezierCurve: m3.springCurveFast

                            }
                            Component.onCompleted: appearAnim.start()

                            Shape {
                                id: pwShape
                                anchors.centerIn: parent
                                width: 100; height: 100
                                rotation: pwSlot.shapeDef.rot
                                scale: pwSlot.targetScale * pwSlot.appearScale
                                antialiasing: true
                                layer.enabled: true
                                layer.samples: 4
                                layer.smooth: true

                                ShapePath {
                                    strokeWidth: -1
                                    strokeColor: "transparent"
                                    fillColor: pwShapesRepeater._primary
                                    joinStyle: ShapePath.RoundJoin
                                    capStyle: ShapePath.RoundCap
                                    PathSvg { path: pwSlot.shapeDef.path }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "\u232b Backspace   \u21b5 Enter"
                font.family: globalState.fontSecondary; font.pixelSize: Math.round(9 * globalState.fontScale); color: pal.mutedDeep
                opacity: lockState.passwordChars.length > 0 ? 1.0 : 0.0
                Behavior on opacity { M3NumberAnim {} }
            }
        }
    }
}
