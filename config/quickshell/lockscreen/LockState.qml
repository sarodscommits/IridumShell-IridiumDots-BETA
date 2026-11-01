import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

// Lockscreen auth and layout state
QtObject {
    id: lockState
    property var   passwordChars: []
    property bool  checking:      false
    property bool  failed:        false

    property var _shapeBag:     []
    property int _lastShapeIdx: -1

    function _drawShapeIdx(n) {
        var bag = _shapeBag.slice();
        if (bag.length === 0) {
            for (var i = 0; i < n; i++) bag.push(i);
            for (var j = bag.length - 1; j > 0; j--) {
                var k = Math.floor(Math.random() * (j + 1));
                var tmp = bag[j]; bag[j] = bag[k]; bag[k] = tmp;
            }
            if (n > 1 && bag[bag.length - 1] === _lastShapeIdx) {
                var swapWith = Math.floor(Math.random() * (bag.length - 1));
                var t = bag[bag.length - 1]; bag[bag.length - 1] = bag[swapWith]; bag[swapWith] = t;
            }
        }
        var idx = bag.pop();
        _shapeBag     = bag;
        _lastShapeIdx = idx;
        return idx;
    }

    function addChar(ch) {
        if (checking) return;
        failed = false;
        var arr = passwordChars.slice(); arr.push(ch); passwordChars = arr;
        var n = lockPwArea.pwShapesArea.shapeDefs.length;
        var r = _drawShapeIdx(n);
        pwShapeModel.append({ shapeIdx: r });
    }

    function backspace() {
        if (checking) return;
        failed = false;
        if (passwordChars.length === 0) return;
        passwordChars = passwordChars.slice(0, -1);
        if (pwShapeModel.count > 0) pwShapeModel.remove(pwShapeModel.count - 1);
    }

    function submit() {
        if (checking || passwordChars.length === 0) return;
        checking = true;
        _authGen++;
        var pw = passwordChars.join("");
        if (pamAuthProcess.running) pamAuthProcess.running = false;
        if (suAuthProcess.running)  suAuthProcess.running  = false;
        pamAuthProcess.gen     = _authGen;
        pamAuthProcess.attempt = pw;
        pamAuthProcess.running = true;
    }

    property int _authGen: 0

    function authSuccess() {
        checking = false; failed = true; _triedSu = false;
        failed = false;
        passwordChars = [];
        pwShapeModel.clear();
        globalState.lockScreenActive = false;
        inactivityState.idleSeconds  = 0;
        inactivityTimer.restart();
    }

    property bool _triedSu: false

    function authFail() {
        checking = false; failed = true;
        if (!_triedSu) {
            _triedSu = true;
            var pw = passwordChars.join("");
            if (suAuthProcess.running) suAuthProcess.running = false;
            suAuthProcess.gen     = _authGen;
            suAuthProcess.attempt = pw;
            suAuthProcess.running = true;
        }
        passwordChars = [];
        pwShapeModel.clear();
        lockPwArea.shakeSeq.restart();
        failResetTimer.restart();
    }

    function authFailFinal() {
        checking = false; failed = true; _triedSu = false;
        passwordChars = [];
        pwShapeModel.clear();
        lockPwArea.shakeSeq.restart();
        failResetTimer.restart();
    }
}
