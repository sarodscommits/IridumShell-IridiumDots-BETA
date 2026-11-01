import QtQuick
import Quickshell

// Sound backend: playerctl playback and wpctl volume/mute
QtObject {
    id: audioPlayer

    // ── Playback control (playerctl) ─────────────────────────────
    function playPause() { Quickshell.execDetached(["playerctl", "play-pause"]); }
    function previous()  { Quickshell.execDetached(["playerctl", "previous"]); }
    function next()       { Quickshell.execDetached(["playerctl", "next"]); }
    function seekBack()    { Quickshell.execDetached(["playerctl", "position", "5-"]); }
    function seekForward() { Quickshell.execDetached(["playerctl", "position", "5+"]); }
    function seekAbsolute(seconds) {
        Quickshell.execDetached(["playerctl", "position", Math.round(seconds).toString()]);
    }

    // ── Output volume / mute (uses the cached hardware sink) ──
    function _hwSinkScript(cmd) {
        return "S=$(cat \"$HOME/.cache/qs-eq-hw-sink\" 2>/dev/null); " +
               "[ -z \"$S\" ] && S=\"@DEFAULT_AUDIO_SINK@\"; " + cmd;
    }
    function setOutputMuted(muted) {
        Quickshell.execDetached(["bash", "-c", _hwSinkScript("wpctl set-mute \"$S\" " + (muted ? "1" : "0"))]);
    }
    function setOutputVolume(pct) {
        Quickshell.execDetached(["bash", "-c", _hwSinkScript("wpctl set-volume \"$S\" " + Math.round(pct) + "%")]);
    }

    // ── Microphone volume / mute ──────────────────────────────────────
    function setMicMuted(muted) {
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", muted ? "1" : "0"]);
    }
    function setMicVolume(pct) {
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", Math.round(pct) + "%"]);
    }
}
