import QtQuick
import QtQuick.Effects
import QtQml.Models
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import ".."
import "../lockscreen"
import "../panels"
import "../ui"

// Lock screen window
PanelWindow {
    id: lockScreen
    WlrLayershell.namespace: "iridium-lockscreen"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true
    visible: true
    color:   "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore

    property bool revealReady: false
    Timer { id: lockRevealFallback; interval: 350; running: true; onTriggered: lockScreen.revealReady = true }

    Item {
        id: lockFadeRoot
        anchors.fill: parent
        opacity: (globalState.lockScreenActive && lockScreen.revealReady) ? 1 : 0
        Behavior on opacity { M3NumberAnim { duration: m3.durSlow } }

        Image {
            id: lockWallpaperSrc
            anchors.fill: parent
            opacity: 0
            onStatusChanged: if (status === Image.Ready || status === Image.Error) lockScreen.revealReady = true
            source: {
                var still = globalState.currentWallpaperStill !== "" ? globalState.currentWallpaperStill : globalState.currentWallpaper;
                return still !== "" ? "file://" + still : "";
            }
            sourceSize: Qt.size(Math.max(1, lockScreen.width), Math.max(1, lockScreen.height))
            fillMode: Image.PreserveAspectCrop
            smooth: true; asynchronous: true
            cache: false
        }
        MultiEffect {
            anchors.fill: parent
            source: lockWallpaperSrc
            autoPaddingEnabled: false
            blurEnabled: true
            blur: globalState.lockBlurLevel
            Behavior on blur { NumberAnimation { duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasizedDecelerate } }
            blurMax: 128
            blurMultiplier: 1.5
        }

        Rectangle {
            anchors.fill: parent
            color: "#4D000000"
        }

        LockCavaVis { id: lockCavaVis }

        MouseArea {
            anchors.fill: parent
            z: 0
            onClicked: hiddenInput.forceActiveFocus()
        }

        HyprlandFocusGrab {
            id: lockFocusGrab
            windows: [lockScreen]
            active:  globalState.lockScreenActive
        }

        Process {
            id: pamAuthProcess
            property string attempt: ""
            property int gen: 0
            command: ["bash", "-c",
            "printf '%s' " + JSON.stringify(pamAuthProcess.attempt) +
            " | pamtester login " + JSON.stringify(globalState.lockUsername) +
            " authenticate 2>/dev/null && echo OK || echo FAIL"
            ]
            running: false
            stdout: SplitParser {
                onRead: (line) => {
                    if (pamAuthProcess.gen !== lockState._authGen) return;
                    var t = line.trim();
                    if      (t === "OK")   lockState.authSuccess();
                    else if (t === "FAIL") lockState.authFail();
                }
            }
        }

        Process {
            id: suAuthProcess
            property string attempt: ""
            property int gen: 0
            command: ["bash", "-c",
            "echo " + JSON.stringify(suAuthProcess.attempt) +
            " | su -c 'true' - " + JSON.stringify(globalState.lockUsername) +
            " 2>/dev/null && echo OK || echo FAIL"
            ]
            running: false
            stdout: SplitParser {
                onRead: (line) => {
                    if (suAuthProcess.gen !== lockState._authGen) return;
                    var t = line.trim();
                    if      (t === "OK")   lockState.authSuccess();
                    else if (t === "FAIL") lockState.authFailFinal();
                }
            }
        }

        LockState { id: lockState }

        ListModel { id: pwShapeModel }

        Timer { id: failResetTimer; interval: 2000; repeat: false; onTriggered: lockState.failed = false }

        TextInput {
            id: hiddenInput
            visible: false
            opacity: 0
            width: 1; height: 1
            focus: globalState.lockScreenActive
            activeFocusOnTab: false
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhHiddenText

            Keys.onPressed: (event) => {
                if (!globalState.lockScreenActive) { event.accepted = false; return; }
                if (lockContent.editMode) {
                    if (event.key === Qt.Key_Escape) lockContent.editMode = false;
                    event.accepted = true; return;
                }
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    lockState.submit(); event.accepted = true; return;
                }
                if (event.key === Qt.Key_Backspace) {
                    lockState.backspace(); event.accepted = true; return;
                }
                if (event.key === Qt.Key_Escape) {
                    event.accepted = true; return;
                }
                var txt = event.text;
                if (txt && txt.length === 1 && txt.charCodeAt(0) >= 32) {
                    lockState.addChar(txt);
                    event.accepted = true;
                }
            }
            onTextChanged: {
                if (text.length > 0) {
                    var last = text[text.length - 1];
                    if (last && last.charCodeAt(0) >= 32 && !lockContent.editMode) lockState.addChar(last);
                    Qt.callLater(function() { hiddenInput.text = ""; });
                }
            }
        }

        Connections {
            target: globalState
            function onLockScreenActiveChanged() {
                if (globalState.lockScreenActive) {
                    hiddenInput.forceActiveFocus();
                    globalState.lockMotiIdx = Math.floor(Math.random() * 10);
                } else {
                    globalState.powerMenuOpen = false;
                }
            }
        }

        Item {
            anchors.fill: parent
            z: 1

            MouseArea {
                anchors.fill: parent
                onClicked: { lockNotifPill.expanded = false; lockClockStylePopup.shown = false; hiddenInput.forceActiveFocus(); }
            }

            Item {
                id: lockContent
                anchors.fill: parent
                scale: 0.97 + 0.03 * lockFadeRoot.opacity
                property bool editMode: false
                property string draggingSlider: ""
                readonly property bool editorDragging: draggingSlider !== ""
                readonly property bool typing: lockState.passwordChars.length > 0
                readonly property bool blurDragging: draggingSlider === "blur"
                readonly property bool horizontalLayout: globalState.lockLayout === "horizontal"
                readonly property real modGap: 14
                readonly property real audioShift: lockAudioModule.height - lockAudioModule.collapsedH
                readonly property real stackH: lockSessionRow.height + modGap + lockPwArea.height + modGap + lockAudioModule.collapsedH
                readonly property bool layoutAnim: editMode && !editorDragging
                readonly property real hGap:   56 + lockBigClockCanvas.width * 0.12
                readonly property real hGroupX: (width - (lockBigClockCanvas.width + hGap + lockPwArea.width)) / 2
                property real layoutT: horizontalLayout ? 1 : 0
                Behavior on layoutT { NumberAnimation { duration: 620; easing.type: Easing.BezierSpline; easing.bezierCurve: m3.emphasized } }
                readonly property real _cw: lockBigClockCanvas.width
                readonly property real _cVx: width / 2
                readonly property real _cVy: (height - _cw) / 2 - audioShift + _cw / 2
                readonly property real _mVx: width / 2
                readonly property real _mVy: (height - _cw) / 2 - audioShift + _cw + lockSessionRow.topGap + stackH / 2
                readonly property real _cHx: hGroupX + _cw / 2
                readonly property real _cHy: height / 2
                readonly property real _mHx: hGroupX + _cw + hGap + lockPwArea.width / 2
                readonly property real _mHy: (height - stackH) / 2 - audioShift + stackH / 2
                readonly property real _pVx: (_cVx + _mVx) / 2
                readonly property real _pVy: (_cVy + _mVy) / 2
                readonly property real _pHx: (_cHx + _mHx) / 2
                readonly property real _pHy: (_cHy + _mHy) / 2
                readonly property real _px: _pVx + (_pHx - _pVx) * layoutT
                readonly property real _py: _pVy + (_pHy - _pVy) * layoutT
                readonly property real _aV: Math.atan2(_cVy - _pVy, _cVx - _pVx)
                readonly property real _aH: Math.atan2(_cHy - _pHy, _cHx - _pHx)
                readonly property real _dA: {
                    var d = _aH - _aV;
                    while (d > Math.PI) d -= 2 * Math.PI;
                    while (d <= -Math.PI) d += 2 * Math.PI;
                    return d;
                }
                readonly property real _rV: Math.hypot(_cVx - _pVx, _cVy - _pVy)
                readonly property real _rH: Math.hypot(_cHx - _pHx, _cHy - _pHy)
                readonly property real _ang: _aV + _dA * layoutT
                readonly property real _rad: _rV + (_rH - _rV) * layoutT
                readonly property real clockCX:   _px + Math.cos(_ang) * _rad
                readonly property real clockCY:   _py + Math.sin(_ang) * _rad
                readonly property real modulesCX: _px - Math.cos(_ang) * _rad
                readonly property real modulesCY: _py - Math.sin(_ang) * _rad
                onEditModeChanged: {
                    if (!editMode) draggingSlider = "";
                    else { lockNotifPill.expanded = false; lockAudioModule.expanded = false; }
                }
                Connections {
                    target: globalState
                    function onLockScreenActiveChanged() { if (!globalState.lockScreenActive) lockContent.editMode = false; }
                }
                anchors.margins: 48
                opacity: globalState.glassMode ? 0.92 : 1.0
                Behavior on opacity { M3NumberAnim {} }

                Repeater {
                    model: [lockBigClockCanvas, lockNotifPill, lockSessionRow.lockPowerBar, lockAudioModule, lockPwArea.pwBarOuter,
                    lockPwArea.lockEditBtn, lockClockStylePopup, lockClockEditor, lockOptionsCard]
                    delegate: LockShadow {
                        required property var modelData
                        target: modelData
                        space: lockContent
                        active: globalState.shellShadowLockOn
                    }
                }
                Repeater {
                    model: [lockBigClockCanvas, lockNotifPill, lockSessionRow.lockPowerBar, lockAudioModule, lockPwArea.pwBarOuter,
                    lockPwArea.lockEditBtn, lockClockStylePopup, lockClockEditor, lockOptionsCard]
                    delegate: LockFrost {
                        required property var modelData
                        target: modelData
                        wallpaper: lockWallpaperSrc
                        space: lockContent
                        active: globalState.glassMode
                    }
                }

                LockNotificationPill { id: lockNotifPill }

                LockBigClock { id: lockBigClockCanvas }

                LockClockStylePopup { id: lockClockStylePopup }

                LockSessionRow { id: lockSessionRow }

                LockAudioModule { id: lockAudioModule }

                QtObject {
                    id: lockEdColors
                    property color cPrimary:    pal.primary
                    property color cOnPrimary:  pal.colorOnPrimary
                    property color cOnSurface:  pal.colorOnSurface
                    property color cOnSurfVar:  pal.colorOnSurfVar
                    property color cMuted:      pal.muted
                    property color cDarkest: {
                        var cs = [pal.surface, pal.surfaceDeep, pal.surfaceElevated, pal.surfaceHigh, pal.surfacePop];
                        var best = cs[0], bl = 2;
                        for (var i = 0; i < cs.length; i++) {
                            var l = 0.2126 * cs[i].r + 0.7152 * cs[i].g + 0.0722 * cs[i].b;
                            if (l < bl) { bl = l; best = cs[i]; }
                        }
                        return best;
                    }
                    property color cPopup:      cCard
                    property color cCard:       globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.85) : containerDark(pal.secondaryCont)
                    property color cOff:        ga(pal.surfaceDeep, 0.5)
                    property color cTrack:      globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep
                    property color cFill:       pal.toggleOn
                    property color cThumb:      pal.accent
                    property color cThumbBorder: pal.surfaceHigh
                    property color cActiveBg:   Qt.rgba(pal.primary.r, pal.primary.g, pal.primary.b, 0.18)
                    property color cHoverBg:    Qt.rgba(pal.colorOnSurfVar.r, pal.colorOnSurfVar.g, pal.colorOnSurfVar.b, 0.10)
                    readonly property var styles: ["gear", "circle", "digitalV", "digitalH"]
                    function cycleStyle(dir) {
                        var i = styles.indexOf(globalState.lockClockStyle);
                        if (i < 0) i = 0;
                        globalState.lockClockStyle = styles[(i + dir + styles.length) % styles.length];
                        savePrefs();
                    }
                }

                Repeater {
                    model: [ { dir: -1, glyph: "" }, { dir: 1, glyph: "" } ]
                    Rectangle {
                        required property var modelData
                        z: 6
                        anchors.verticalCenter: lockBigClockCanvas.verticalCenter
                        x: modelData.dir < 0 ? lockBigClockCanvas.x - width - 28
                        : lockBigClockCanvas.x + lockBigClockCanvas.width + 28
                        width: 52; height: 52; radius: 26
                        opacity: lockContent.editMode && !lockContent.editorDragging ? 1 : 0
                        visible: opacity > 0.01
                        scale: lockContent.editMode ? 1 : 0.6
                        Behavior on opacity { M3NumberAnim {} }
                        Behavior on scale   { M3SpringAnim { token: "spatialFast"; epsilon: 0.002 } }
                        color: lockEdArrowHov.hovered ? lockEdColors.cPrimary : lockEdColors.cCard
                        Behavior on color { M3ColorAnim {} }
                        Text {
                            anchors.centerIn: parent
                            text: modelData.glyph
                            font.family: "Material Symbols Rounded"; font.pixelSize: 30
                            color: lockEdArrowHov.hovered ? lockEdColors.cOnPrimary : lockEdColors.cOnSurface
                        }
                        HoverHandler { id: lockEdArrowHov }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { lockEdColors.cycleStyle(modelData.dir); hiddenInput.forceActiveFocus(); }
                        }
                    }
                }

                LockClockEditor { id: lockClockEditor }

                LockOptionsCard { id: lockOptionsCard }

                LockPasswordArea { id: lockPwArea }
            }
        }
    }

    Component.onCompleted: hiddenInput.forceActiveFocus()
}
