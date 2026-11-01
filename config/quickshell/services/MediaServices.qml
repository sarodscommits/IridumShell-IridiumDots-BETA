import QtQuick
import Quickshell
import Quickshell.Io
import ".."

// MPRIS player state (playerctl) and the built-in audio player
HyprlandServices {
    property alias audioPlayer: audioPlayer
    property alias mediaFollowProcess: mediaFollowProcess
    property alias mediaProcess: mediaProcess

    function setVolumePercent(v) {
        globalState.rawVolumeValue = v;
        globalState.volumeText = v + "%";
        audioPlayer.setOutputVolume(v * globalState.hwVolumeBoostMultiplier);
    }
    function setMicPercent(v) {
        globalState.rawMicVolume = v;
        audioPlayer.setMicVolume(v);
    }

    Process {
        id: mediaProcess
        command: ["bash", "-c",
        "# Try playerctl first, fall back to dbus-send\n" +
        "P=''; [ -n \"$1\" ] && P=\"--player=$1\"\n" +
        "if command -v playerctl >/dev/null 2>&1; then\n" +
        "  status=$(playerctl --no-messages $P status 2>/dev/null)\n" +
        "  [ -z \"$status\" ] && { echo 'Stopped|||0|0'; exit 0; }\n" +
        "  case \"$status\" in Stopped|No*) echo 'Stopped|||0|0'; exit 0;; esac\n" +
        "  title=$(playerctl --no-messages $P metadata title 2>/dev/null | tr '|' '-')\n" +
        "  artist=$(playerctl --no-messages $P metadata artist 2>/dev/null | tr '|' '-')\n" +
        "  arturl=$(playerctl --no-messages $P metadata mpris:artUrl 2>/dev/null | tr '|' '-')\n" +
        "  case \"$arturl\" in /*) arturl=\"file://$arturl\";; esac\n" +
        "  durUs=$(playerctl --no-messages $P metadata mpris:length 2>/dev/null)\n" +
        "  pos=$(playerctl --no-messages $P position 2>/dev/null | awk '{printf \"%d\", $1}')\n" +
        "  echo \"${status}|${title:-}|${artist:-}|${durUs:-0}|${pos:-0}|${arturl:-}\"\n" +
        "else\n" +
        "  # dbus fallback: find first active MPRIS player\n" +
        "  player=$(dbus-send --print-reply --dest=org.freedesktop.DBus /org/freedesktop/DBus \\\n" +
        "    org.freedesktop.DBus.ListNames 2>/dev/null | \\\n" +
        "    grep -o '\"org.mpris.MediaPlayer2.[^\"]*\"' | head -1 | tr -d '\"')\n" +
        "  [ -z \"$player\" ] && { echo 'Stopped|||0|0'; exit 0; }\n" +
        "  status=$(dbus-send --print-reply --dest=\"$player\" /org/mpris/MediaPlayer2 \\\n" +
        "    org.freedesktop.DBus.Properties.Get \\\n" +
        "    string:org.mpris.MediaPlayer2.Player string:PlaybackStatus 2>/dev/null | \\\n" +
        "    grep -o '\"[^\"]*\"' | tail -1 | tr -d '\"')\n" +
        "  [ -z \"$status\" ] && { echo 'Stopped|||0|0'; exit 0; }\n" +
        "  meta=$(dbus-send --print-reply --dest=\"$player\" /org/mpris/MediaPlayer2 \\\n" +
        "    org.freedesktop.DBus.Properties.Get \\\n" +
        "    string:org.mpris.MediaPlayer2.Player string:Metadata 2>/dev/null)\n" +
        "  title=$(echo \"$meta\" | grep -A1 'xesam:title' | grep variant | grep -o '\"[^\"]*\"' | tail -1 | tr -d '\"' | tr '|' '-')\n" +
        "  artist=$(echo \"$meta\" | grep -A2 'xesam:artist' | grep string | grep -o '\"[^\"]*\"' | tail -1 | tr -d '\"' | tr '|' '-')\n" +
        "  arturl=$(echo \"$meta\" | grep -A1 'mpris:artUrl' | grep string | grep -o '\"[^\"]*\"' | tail -1 | tr -d '\"' | tr '|' '-')\n" +
        "  case \"$arturl\" in /*) arturl=\"file://$arturl\";; esac\n" +
        "  durUs=$(echo \"$meta\" | grep -A1 'mpris:length' | grep uint64 | grep -o '[0-9]*' | head -1)\n" +
        "  pos=$(dbus-send --print-reply --dest=\"$player\" /org/mpris/MediaPlayer2 \\\n" +
        "    org.freedesktop.DBus.Properties.Get \\\n" +
        "    string:org.mpris.MediaPlayer2.Player string:Position 2>/dev/null | \\\n" +
        "    grep -o '[0-9]*' | tail -1)\n" +
        "  posS=$(( ${pos:-0} / 1000000 ))\n" +
        "  echo \"${status}|${title:-}|${artist:-}|${durUs:-0}|${posS}|${arturl:-}\"\n" +
        "fi",
        "qs-media", mediaFollowProcess.playerName
        ]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                var trimmed = line.trim();
                if (!trimmed) return;
                var parts = trimmed.split("|");
                if (parts.length < 5) return;
                mediaProcess.applyMedia(parts[0], parts[1], parts[2], parseInt(parts[3]), parseInt(parts[4]),
                parts.length > 5 ? parts.slice(5).join("|") : "");
            }
        }
        function normTitle(t) {
            t = (t || "").replace(/^\(\d+\+?\)\s*/, "");
            t = t.replace(/\s+[-\u2013\u2014|]\s+(YouTube Music|YouTube|Spotify|SoundCloud|Deezer|Tidal)\s*$/i, "");
            return t.trim().toLowerCase();
        }
        function isQsMusic() {
            var n = mediaFollowProcess.playerName;
            if (n !== "") return n.indexOf("qsmusic") === 0;
            return globalState.musicPlaying;
        }
        function syncQsMusic() {
            if (!isQsMusic() || globalState.mediaStatus === "Stopped") return false;
            var d = globalState.musicDurSec;
            if (d <= 0) return false;
            var p = Math.max(0, Math.min(d, globalState.musicPosSec));
            globalState.mediaDurSeconds = d;
            globalState.mediaPosSeconds = p;
            globalState.mediaPosition   = Math.min(1.0, p / d);
            return true;
        }
        function applyMedia(status, title, artist, durUs, pos, artUrl) {
            if (status === "Stopped" || status === "") { clearMedia(); return; }
            var dur = (isNaN(durUs) || durUs <= 0) ? 0 : Math.round(durUs / 1000000);
            globalState.mediaStatus = status;
            var isPhantomTitle = /^(YouTube Music|Spotify|SoundCloud)$/i.test(title.trim());
            title = cleanTitle(title);
            if (title !== "" && !isPhantomTitle && !applyTrack(title, artist, dur, pos, artUrl)) return;
            if (syncQsMusic()) return;
            applyPosition(pos);
        }
        function clearMedia() {
            mediaFollowProcess.playerName = "";
            globalState.mediaStatus     = "Stopped";
            globalState.mediaTitle      = "";
            globalState.mediaArtist     = "";
            globalState.mediaArtUrl     = "";
            globalState.mediaPosSeconds = 0;
            globalState.mediaDurSeconds = 0;
            globalState.mediaPosition   = 0;
            mediaArtFastPollTimer.stop();
        }
        function cleanTitle(title) {
            title = title.replace(/^\(\d+\+?\)\s*/, "");
            title = title.replace(/\s+[-\u2013\u2014|]\s+(YouTube Music|YouTube|Spotify|SoundCloud|Deezer|Tidal)\s*$/i, "");
            return title;
        }
        function applyTrack(title, artist, dur, pos, artUrl) {
            var sameArtist = artist === globalState.mediaArtist || artist === "" || globalState.mediaArtist === "";
            var isNewTrack = (title !== globalState.mediaTitle) || !sameArtist;
            var foreignSource = !isNewTrack && globalState.mediaDurSeconds > 0 && !isQsMusic()
            && (dur <= 0 || Math.abs(dur - globalState.mediaDurSeconds) > 2);
            if (foreignSource) {
                console.log("[cpMediaCard] line from another source for the same track ignored (dur", dur, "vs", globalState.mediaDurSeconds, ", pos", pos, ")");
                return false;
            }
            globalState.mediaTitle      = title;
            if (artist !== "" || isNewTrack) globalState.mediaArtist = artist;
            if (dur > 0 || isNewTrack) globalState.mediaDurSeconds = dur;
            if (isNewTrack) applyNewTrack(title, artUrl);
            else if (artUrl !== "" && artUrl !== globalState.mediaArtUrl) {
                console.log("[cpMediaCard] arturl changed without a new track:", artUrl);
                globalState.mediaArtUrl = artUrl;
                mediaArtFastPollTimer.stop();
            }
            return true;
        }
        function applyNewTrack(title, artUrl) {
            globalState.mediaPosSeconds = 0;
            globalState.mediaPosition   = 0;
            console.log("[cpMediaCard] nueva pista:", title, "| arturl crudo:", artUrl);
            mediaArtFastPollProcess.attempts = 0;
            if (artUrl === "") {
                var borrowed = mediaFollowProcess.artByTitle[normTitle(title)] || "";
                if (borrowed !== "") console.log("[cpMediaCard] cover taken from another player with the same track:", borrowed);
                artUrl = borrowed;
            }
            if (artUrl === "") {
                globalState.mediaArtUrl = "";
                mediaArtFastPollTimer.restart();
            } else if (artUrl === globalState.mediaArtUrl) {
                globalState.mediaArtUrl = "";
                Qt.callLater(function() { globalState.mediaArtUrl = artUrl; });
                mediaArtFastPollTimer.stop();
            } else {
                globalState.mediaArtUrl = artUrl;
                mediaArtFastPollTimer.stop();
            }
        }
        function applyPosition(pos) {
            if (globalState.mediaDurSeconds <= 0 || isNaN(pos)) return;
            if (pos > globalState.mediaDurSeconds + 1) return;
            globalState.mediaPosSeconds = pos;
            globalState.mediaPosition   = Math.min(1.0, pos / globalState.mediaDurSeconds);
        }
    }

    Timer {
        interval: mediaFollowProcess.running ? 15000 : 1000
        running: true; repeat: true
        onTriggered: if (!mediaProcess.running) mediaProcess.running = true
    }

    Process {
        id: mediaFollowProcess
        property int failures: 0
        property string playerName: ""
        property var artByTitle: ({})
        function handleLine(line) {
            mediaFollowProcess.failures = 0;
            if (line.trim() === "") {
                mediaFollowProcess.playerName = "";
                mediaProcess.applyMedia("Stopped", "", "", 0, 0, "");
                return;
            }
            var p0 = line.split("\u001f");
            if (p0.length < 7) return;
            var name = p0[0].trim();
            var p = p0.slice(1);
            var st = p[0].trim();
            if (st === "") st = "Stopped";
            var art = p.slice(5).join("\u001f").trim();
            if (art.charAt(0) === "/") art = "file://" + art;
            var title = p[1].replace(/\|/g, "-");
            mediaFollowProcess.rememberArt(title, art);
            if (otherPlayerIgnored(name, st, art, title)) return;
            if (st === "Stopped") {
                console.log("[cpMediaCard]", name, "reporta Stopped — confirmando en 1.5 s");
                mediaStopConfirmTimer.restart();
                return;
            }
            if (mediaStopConfirmTimer.running) {
                console.log("[cpMediaCard] Stopped cancelled:", name, "went back to", st);
                mediaStopConfirmTimer.stop();
            }
            mediaFollowProcess.playerName = name;
            var stateChanged = st !== globalState.mediaStatus;
            var posUs = parseInt(p[4]);
            var posS = isNaN(posUs) ? NaN : Math.floor(posUs / 1000000);
            console.log("[cpMediaCard] event", name, st, "| pos follow:", posS, "s | art:", art === "" ? "(empty)" : "ok");
            mediaProcess.applyMedia(st, title, p[2].replace(/\|/g, "-"),
            parseInt(p[3]), stateChanged ? posS : NaN, art);
            if (!mediaPosProcess.running) mediaPosProcess.running = true;
        }
        function otherPlayerIgnored(name, st, art, title) {
            var cur = mediaFollowProcess.playerName;
            if (cur !== "" && name !== cur) {
                var curPlaying = globalState.mediaStatus === "Playing";
                if (!(st === "Playing" && !curPlaying)) {
                    if (art !== "" && globalState.mediaArtUrl === ""
                    && mediaProcess.normTitle(title) === mediaProcess.normTitle(globalState.mediaTitle)) {
                        console.log("[cpMediaCard] cover taken from", name, "(same track as", cur + "):", art);
                        mediaArtFastPollTimer.stop();
                        globalState.mediaArtUrl = art;
                    }
                    console.log("[cpMediaCard] line from another player ignored:", name, st, "| pinned:", cur);
                    return true;
                }
                console.log("[cpMediaCard] cambio de reproductor:", cur, "→", name);
            }
            return false;
        }
        function rememberArt(title, art) {
            var k = mediaProcess.normTitle(title);
            if (k === "" || art === "" || artByTitle[k] === art) return;
            var m = {};
            var keys = Object.keys(artByTitle);
            for (var i = Math.max(0, keys.length - 7); i < keys.length; i++) m[keys[i]] = artByTitle[keys[i]];
            m[k] = art;
            artByTitle = m;
        }
        command: ["playerctl", "--no-messages", "--follow", "metadata", "--format",
        "{{playerName}}\u001f{{status}}\u001f{{xesam:title}}\u001f{{xesam:artist}}\u001f{{mpris:length}}\u001f{{position}}\u001f{{mpris:artUrl}}"]
        running: true
        stdout: SplitParser {
            onRead: (line) => mediaFollowProcess.handleLine(line)
        }
        onRunningChanged: {
            if (!running && failures < 5) { failures++; mediaFollowRestartTimer.start(); }
        }
    }

    Timer { id: mediaFollowRestartTimer; interval: 3000; repeat: false; onTriggered: mediaFollowProcess.running = true }

    Timer {
      id: mediaStopConfirmTimer
      interval: 1500; repeat: false
      onTriggered: {
        console.log("[cpMediaCard] Stopped confirmed — releasing the player", mediaFollowProcess.playerName);
        mediaFollowProcess.playerName = "";
        mediaProcess.applyMedia("Stopped", "", "", 0, 0, "");
      }
    }

    AudioPlayer {
        id: audioPlayer
    }
}
