import QtQuick
import Quickshell
import Quickshell.Io

// Lyrics engine, playback position and album-art color for the current track
MediaServices {
    property alias mediaArtFastPollProcess: mediaArtFastPollProcess
    property alias mediaArtFastPollTimer: mediaArtFastPollTimer
    property alias mediaPosProcess: mediaPosProcess

    Process {
        id: lyricsFetchProcess
        property string reqKey: ""
        property string pPlayer: ""
        property string pTitle: ""
        property string pArtist: ""
        property int    pDur: 0
        property bool   pOnline: true
        property bool   _again: false
        command: ["bash", "-c",
        "P=\"$1\"; T=\"$2\"; A=\"$3\"; D=\"$4\"; ON=\"$5\"\n" +
        "if [ -n \"$P\" ] && command -v playerctl >/dev/null 2>&1; then\n" +
        "  txt=$(playerctl --no-messages -p \"$P\" metadata xesam:asText 2>/dev/null)\n" +
        "  if [ -n \"$(printf '%s' \"$txt\" | tr -d '[:space:]')\" ]; then printf 'SRC:mpris\\n%s\\n' \"$txt\"; exit 0; fi\n" +
        "fi\n" +
        "if [ \"$ON\" != 1 ] || [ -z \"$T\" ]; then echo 'SRC:none'; exit 0; fi\n" +
        "dir=\"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/lyrics\"; mkdir -p \"$dir\"\n" +
        "key=$(printf '%s\\037%s' \"$A\" \"$T\" | tr '[:upper:]' '[:lower:]' | md5sum | cut -c1-20)\n" +
        "f=\"$dir/$key.lrc\"\n" +
        "if [ -s \"$f\" ]; then echo 'SRC:lrclib'; cat \"$f\"; exit 0; fi\n" +
        "if [ -f \"$f\" ] && [ -n \"$(find \"$f\" -mmin -4320 2>/dev/null)\" ]; then echo 'SRC:none'; exit 0; fi\n" +
        "exec python3 - \"$T\" \"$A\" \"$D\" \"$f\" <<'PY'\n" +
        "import sys, json, urllib.request, urllib.parse, urllib.error\n" +
        "t, a, d, f = sys.argv[1:5]\n" +
        "d = int(d) if d.isdigit() else 0\n" +
        "def get(path, q):\n" +
        "    req = urllib.request.Request('https://lrclib.net/api/' + path + '?' + urllib.parse.urlencode(q),\n" +
        "                                 headers={'User-Agent': 'IridiumShell/1.0 (quickshell lyrics)'})\n" +
        "    with urllib.request.urlopen(req, timeout=8) as r:\n" +
        "        return json.load(r)\n" +
        "def has(it): return bool(it and (it.get('syncedLyrics') or it.get('plainLyrics')))\n" +
        "res = None\n" +
        "try:\n" +
        "    if a:\n" +
        "        q = {'track_name': t, 'artist_name': a}\n" +
        "        if d > 0: q['duration'] = d\n" +
        "        try: res = get('get', q)\n" +
        "        except urllib.error.HTTPError as e:\n" +
        "            if e.code != 404: raise\n" +
        "    if not has(res):\n" +
        "        best = None\n" +
        "        for it in get('search', {'q': (a + ' ' + t).strip()}) or []:\n" +
        "            if not has(it): continue\n" +
        "            dd = abs(float(it.get('duration') or 0) - d) if d > 0 else 0\n" +
        "            if d > 0 and dd > 12: continue\n" +
        "            sc = (3 if it.get('syncedLyrics') else 0) - dd / 4\n" +
        "            if best is None or sc > best[0]: best = (sc, it)\n" +
        "        res = best[1] if best else None\n" +
        "except Exception:\n" +
        "    print('SRC:error'); sys.exit(0)\n" +
        "txt = (res or {}).get('syncedLyrics') or (res or {}).get('plainLyrics') or ''\n" +
        "try:\n" +
        "    open(f, 'w').write(txt)\n" +
        "except Exception: pass\n" +
        "print('SRC:lrclib' if txt else 'SRC:none')\n" +
        "if txt: print(txt)\n" +
        "PY\n",
        "qs-lyrics", pPlayer, pTitle, pArtist, String(pDur), pOnline ? "1" : "0"
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: lyricsEngine.onFetched(lyricsFetchProcess.reqKey, this.text || "")
        }
        onRunningChanged: {
            if (!running && _again) { _again = false; running = true; }
        }
    }

    QtObject {
        id: lyricsEngine
        property string curKey: ""
        property real basePos: 0
        property real baseStamp: 0
        function trackKey() {
            return mediaFollowProcess.playerName + "\u001f" + globalState.mediaTitle + "\u001f" + globalState.mediaArtist;
        }
        function parse(text) {
            text = (text || "").replace(/\r/g, "");
            if (!text.trim()) return { synced: false, lines: [] };
            var rx = /\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]/g;
            var offset = 0;
            var mo = text.match(/\[offset:\s*([+-]?\d+)\s*\]/i);
            if (mo) offset = parseInt(mo[1], 10) / 1000;
            var out = [], plain = [], any = false, rows = text.split("\n");
            for (var i = 0; i < rows.length; i++) {
                var row = rows[i], stamps = [], m, last = 0;
                rx.lastIndex = 0;
                while ((m = rx.exec(row)) !== null) {
                    if (m.index !== last) break;
                    var frac = m[3] ? parseInt(m[3], 10) / Math.pow(10, m[3].length) : 0;
                    stamps.push(parseInt(m[1], 10) * 60 + parseInt(m[2], 10) + frac);
                    last = rx.lastIndex;
                }
                if (stamps.length) {
                    any = true;
                    var txt = row.substring(last).replace(/<\d+:\d+(?:\.\d+)?>/g, "").trim();
                    for (var j = 0; j < stamps.length; j++) out.push({ t: Math.max(0, stamps[j] - offset), s: txt });
                } else if (!/^\[[a-z]+:.*\]$/i.test(row.trim())) {
                    plain.push({ t: -1, s: row.trim() });
                }
            }
            if (any) { out.sort(function (x, y) { return x.t - y.t; }); return { synced: true, lines: out }; }
            while (plain.length && !plain[0].s) plain.shift();
            while (plain.length && !plain[plain.length - 1].s) plain.pop();
            return { synced: false, lines: plain };
        }
        function apply(lines, synced, src) {
            globalState.mediaLyricsSynced = synced && lines.length > 0;
            globalState.mediaLyrics = lines;
            globalState.mediaLyricsSource = lines.length ? src : "";
            globalState.mediaLyricIndex = -1;
            globalState.mediaLyricProgress = 0;
            tick();
        }
        function ownActive() {
            return mediaProcess.isQsMusic() && globalState.musicLyrics.length > 0;
        }
        function refresh() {
            if (globalState.mediaStatus === "Stopped" || globalState.mediaTitle === "") {
                curKey = "";
                globalState.mediaLyricsLoading = false;
                if (globalState.mediaLyrics.length) apply([], false, "");
                return;
            }
            var k = trackKey();
            if (ownActive()) {
                curKey = k;
                globalState.mediaLyricsLoading = false;
                apply(globalState.musicLyrics, globalState.musicLyricsSynced, "qsmusic");
                return;
            }
            if (k === curKey && globalState.mediaLyricsSource !== "qsmusic") return;
            curKey = k;
            apply([], false, "");
            globalState.mediaLyricsLoading = true;
            lyricsFetchProcess.reqKey = k;
            lyricsFetchProcess.pPlayer = mediaFollowProcess.playerName;
            lyricsFetchProcess.pTitle = globalState.mediaTitle;
            lyricsFetchProcess.pArtist = globalState.mediaArtist;
            lyricsFetchProcess.pDur = globalState.mediaDurSeconds;
            lyricsFetchProcess.pOnline = globalState.lyricsOnlineFallback;
            if (lyricsFetchProcess.running) lyricsFetchProcess._again = true;
            else lyricsFetchProcess.running = true;
        }
        function reload() { curKey = ""; refresh(); }
        function onFetched(key, text) {
            if (key !== curKey || ownActive()) return;
            globalState.mediaLyricsLoading = false;
            var nl = text.indexOf("\n");
            var head = (nl < 0 ? text : text.substring(0, nl)).trim();
            var body = nl < 0 ? "" : text.substring(nl + 1);
            var src = head.indexOf("SRC:") === 0 ? head.substring(4) : "none";
            if (src === "error") { curKey = ""; return; }
            if (src !== "mpris" && src !== "lrclib") { apply([], false, ""); return; }
            var r = parse(body);
            console.log("[lyrics]", r.lines.length, "lines (" + (r.synced ? "synced" : "plain text") + ") from", src, "for", globalState.mediaTitle);
            apply(r.lines, r.synced, src);
        }
        function estPos() {
            var p = basePos;
            if (globalState.mediaStatus === "Playing" && baseStamp > 0) p += Math.min(1.25, (Date.now() - baseStamp) / 1000);
            return p;
        }
        function tick() {
            var L = globalState.mediaLyrics;
            if (!globalState.mediaLyricsSynced || !L.length) {
                if (globalState.mediaLyricIndex !== -1) globalState.mediaLyricIndex = -1;
                globalState.mediaLyricProgress = 0;
                return;
            }
            var pos = estPos(), ans = -1;
            if (globalState.mediaLyricsSource === "qsmusic") {
                ans = Math.min(L.length - 1, globalState.musicLyricIndex);
            } else {
                var t = pos + 0.2, lo = 0, hi = L.length - 1;
                while (lo <= hi) { var mid = (lo + hi) >> 1; if (L[mid].t <= t) { ans = mid; lo = mid + 1; } else hi = mid - 1; }
            }
            if (ans !== globalState.mediaLyricIndex) globalState.mediaLyricIndex = ans;
            var pr = 0;
            if (ans >= 0) {
                var t0 = L[ans].t, t1 = ans + 1 < L.length ? L[ans + 1].t : Math.max(t0 + 4, globalState.mediaDurSeconds);
                pr = t1 > t0 ? Math.max(0, Math.min(1, (pos - t0) / (t1 - t0))) : 1;
            }
            globalState.mediaLyricProgress = pr;
        }
    }

    Timer {
        id: lyricsRefreshTimer
        interval: 450; repeat: false
        onTriggered: lyricsEngine.refresh()
    }

    Timer {
        interval: 120; repeat: true
        running: globalState.mediaLyricsSynced && globalState.mediaStatus === "Playing" && !globalState.lockScreenActive
        onTriggered: lyricsEngine.tick()
    }

    Connections {
        target: globalState
        function onMediaTitleChanged() { lyricsRefreshTimer.restart(); }
        function onMediaArtistChanged() { lyricsRefreshTimer.restart(); }
        function onMediaStatusChanged() { if (globalState.mediaStatus === "Stopped") lyricsRefreshTimer.restart(); lyricsEngine.basePos = lyricsEngine.estPos(); lyricsEngine.baseStamp = Date.now(); }
        function onMediaPosSecondsChanged() { lyricsEngine.basePos = globalState.mediaPosSeconds; lyricsEngine.baseStamp = Date.now(); lyricsEngine.tick(); }
        function onMusicLyricsChanged() { if (mediaProcess.isQsMusic()) lyricsRefreshTimer.restart(); }
        function onMusicLyricsSyncedChanged() { if (mediaProcess.isQsMusic()) lyricsRefreshTimer.restart(); }
        function onMusicLyricIndexChanged() { if (globalState.mediaLyricsSource === "qsmusic") lyricsEngine.tick(); }
        function onLyricsOnlineFallbackChanged() { lyricsEngine.reload(); }
    }

    Connections {
        target: mediaFollowProcess
        function onPlayerNameChanged() { lyricsRefreshTimer.restart(); }
    }

    Connections {
        target: globalState
        function onMusicPosSecChanged() { mediaProcess.syncQsMusic(); }
        function onMusicDurSecChanged() { mediaProcess.syncQsMusic(); }
    }

    Timer {
        id: mediaPosTickTimer
        interval: 1000; repeat: true
        running: mediaFollowProcess.running && globalState.mediaStatus === "Playing" && globalState.mediaDurSeconds > 0
        && !(mediaFollowProcess.playerName.indexOf("qsmusic") === 0 && globalState.musicDurSec > 0)
        property int _ticks: 0
        onTriggered: {
            var d = globalState.mediaDurSeconds;
            var p = Math.min(d, globalState.mediaPosSeconds + 1);
            globalState.mediaPosSeconds = p;
            globalState.mediaPosition   = Math.min(1.0, p / d);
            if (++_ticks % 5 === 0 && !mediaPosProcess.running) mediaPosProcess.running = true;
        }
    }

    Process {
        id: mediaPosProcess
        command: mediaFollowProcess.playerName !== ""
        ? ["playerctl", "--no-messages", "--player=" + mediaFollowProcess.playerName, "position"]
        : ["playerctl", "--no-messages", "position"]
        running: false
        stdout: SplitParser {
            onRead: (line) => {
                if (mediaProcess.syncQsMusic()) return;
                var p = parseFloat(line.trim());
                var d = globalState.mediaDurSeconds;
                if (isNaN(p) || d <= 0) return;
                p = Math.floor(p);
                if (p > d + 1) return;
                globalState.mediaPosSeconds = p;
                globalState.mediaPosition   = Math.min(1.0, p / d);
            }
        }
    }

    Process {
        id: mediaArtFastPollProcess
        property int attempts: 0
        command: ["playerctl", "--no-messages", "-a", "metadata", "--format",
        "{{playerName}}\u001f{{xesam:title}}\u001f{{mpris:artUrl}}"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var fixed = mediaFollowProcess.playerName;
                var want = mediaProcess.normTitle(globalState.mediaTitle);
                var own = "", other = "", otherName = "";
                var lines = (this.text || "").split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var f = lines[i].split("\u001f");
                    if (f.length < 3) continue;
                    var url = f.slice(2).join("\u001f").trim();
                    if (url === "") continue;
                    if (url.charAt(0) === "/") url = "file://" + url;
                    var nm = f[0].trim();
                    if (nm === fixed) own = url;
                    else if (other === "" && want !== "" && mediaProcess.normTitle(f[1]) === want) { other = url; otherName = nm; }
                }
                var url2 = own !== "" ? own : other;
                if (url2 !== "") {
                    console.log("[cpMediaCard] arturl recovered by fast polling" + (own !== "" ? "" : " (from " + otherName + ")") + ":", url2);
                    mediaArtFastPollProcess.attempts = 0;
                    mediaArtFastPollTimer.stop();
                    globalState.mediaArtUrl = url2;
                } else {
                    mediaArtFastPollProcess.attempts++;
                    if (mediaArtFastPollProcess.attempts >= 20) {
                        console.warn("[cpMediaCard] fast arturl polling ran out without success");
                        mediaArtFastPollProcess.attempts = 0;
                        mediaArtFastPollTimer.stop();
                    }
                }
            }
        }
    }

    Timer {
        id: mediaArtFastPollTimer
        interval: 500
        repeat: true
        running: false
        onTriggered: mediaArtFastPollProcess.running = true
    }

    Process {
        id: mediaArtColorProcess
        property string _buf: ""
        command: ["bash", "-c",
        "art=\"$1\"\n" +
        "path=\"$art\"\n" +
        "case \"$art\" in\n" +
        "  file://*) path=\"${art#file://}\" ;;\n" +
        "  http://*|https://*)\n" +
        "    tmp=\"$XDG_RUNTIME_DIR/qs_media_art_cache\"\n" +
        "    curl -sL --max-time 3 \"$art\" -o \"$tmp\" 2>/dev/null || exit 1\n" +
        "    path=\"$tmp\" ;;\n" +
        "esac\n" +
        "[ -n \"$path\" ] && [ -f \"$path\" ] || { echo 'ERR:archivo no existe'; exit 1; }\n" +
        "ext=\"${path##*.}\"\n" +
        "cp \"$path\" \"$XDG_RUNTIME_DIR/qs_lastcover_debug.${ext}\" 2>/dev/null\n" +
        "if command -v magick >/dev/null 2>&1; then\n" +
        "  dim=$(magick identify -format '%wx%h' \"$path\" 2>/dev/null)\n" +
        "  col=$(magick \"$path\" -resize 1x1 -format '%[hex:p{0,0}]' info: 2>/dev/null)\n" +
        "elif command -v convert >/dev/null 2>&1; then\n" +
        "  dim=$(identify -format '%wx%h' \"$path\" 2>/dev/null)\n" +
        "  col=$(convert \"$path\" -resize 1x1 -format '%[hex:p{0,0}]' info: 2>/dev/null)\n" +
        "fi\n" +
        "echo \"DIM:${dim}\"\n" +
        "echo \"COL:${col}\"\n" +
        "echo \"DEBUGFILE:$XDG_RUNTIME_DIR/qs_lastcover_debug.${ext}\"",
        "_", globalState.mediaArtUrl
        ]
        stdout: SplitParser {
            onRead: (line) => { mediaArtColorProcess._buf += line + "\n"; }
        }
        onRunningChanged: {
            if (!running) {
                var buf = mediaArtColorProcess._buf;
                mediaArtColorProcess._buf = "";
                var colMatch = buf.match(/COL:([0-9a-fA-F]{6})/);
                var dimMatch = buf.match(/DIM:(\d+x\d+)/);
                var fileMatch = buf.match(/DEBUGFILE:(\S+)/);
                if (colMatch) globalState.mediaArtColor = colMatch[1];
                console.log("[cpMediaCard] cover read — dimensions:", dimMatch ? dimMatch[1] : "?",
                "| dominant color:", colMatch ? ("#" + colMatch[1]) : "?",
                "| copy at:", fileMatch ? fileMatch[1] : "?");
            }
        }
    }

    Connections {
        target: globalState
        function onMediaArtUrlChanged() {
            if (globalState.mediaArtUrl === "") {
                globalState.mediaArtColor = "";
            } else if (!mediaArtColorProcess.running) {
                mediaArtColorProcess.running = true;
            }
        }
    }
}
