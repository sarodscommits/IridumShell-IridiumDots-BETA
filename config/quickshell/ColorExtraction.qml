import QtQuick
import Quickshell.Io

// Matugen color extraction: reads and watches colors.json
Item {
    id: colorExtraction

    signal colorsLoaded(var colors)

    function reload() { walColorProcess.running = true }

    // Reads data.colors.<role>.dark.color (matugen >= 4.x)
    Process {
        id: walColorProcess
        command: ["bash", "-c",
          "f=\"$HOME/.config/matugen/colors.json\"; [ -f \"$f\" ] || exit 1; cat \"$f\""
        ]
        running: true
        property string _buf: ""
        stdout: SplitParser {
          onRead: (line) => {
            walColorProcess._buf += line;
          }
        }
        onRunningChanged: {
          if (!running) {
            var raw = walColorProcess._buf.trim();
            walColorProcess._buf = "";
            if (!raw) return;
            try {
              var data = JSON.parse(raw);
              var colors = data.colors;
              if (!colors) return;
              colorExtraction.colorsLoaded(colors);
            } catch(e) {
              console.warn("matugen: error parseando colors.json ->", e);
            }
          }
        }
    }

    // Watch ~/.config/matugen/colors.json for changes with inotifywait
    Process {
        id: walWatchProcess
        command: ["bash", "-c",
          "f=\"$HOME/.config/matugen/colors.json\"; " +
          "while true; do " +
          "  [ -f \"$f\" ] && inotifywait -e close_write,moved_to,create -qq \"$(dirname \"$f\")\" 2>/dev/null; " +
          "  echo changed; " +
          "  sleep 0.2; " +
          "done"
        ]
        running: true
        stdout: SplitParser {
          onRead: (line) => {
            if (line.trim() === "changed") {
              walColorProcess.running = true;
              walColorReloadDelayTimer.restart();
            }
          }
        }
        onRunningChanged: {
          if (!running) walWatchRestartTimer.start();
        }
    }
    Timer {
        id: walWatchRestartTimer
        interval: 3000; repeat: false
        onTriggered: walWatchProcess.running = true
    }
    // Second delayed reload in case inotify fires before matugen finishes writing
    Timer {
        id: walColorReloadDelayTimer
        interval: 450; repeat: false
        onTriggered: walColorProcess.running = true
    }
}
