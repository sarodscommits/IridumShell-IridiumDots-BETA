import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import ".."

// Notification server wiring, clear-all handling and notification sounds
CoreServices {
    property alias notifClearTimer: notifClearTimer
    property alias notificationSoundWatchProcess: notificationSoundWatchProcess
    property alias notificationsBackend: notificationsBackend

    Connections {
        target: notificationsBackend.trackedNotifications
        function onValuesChanged() { notifCapTimer.restart(); }
    }

    Timer {
        id: notifCapTimer
        interval: 600; repeat: false
        onTriggered: {
            var v = notificationsBackend.trackedNotifications.values.slice();
            var extra = v.length - 50;
            for (var i = 0; i < extra; i++) v[i].dismiss();
        }
    }

    Timer {
        id: notifClearTimer
        interval: 720; repeat: false
        onTriggered: {
            var v = globalState.notifClearSnapshot;
            globalState.notifClearSnapshot = [];
            globalState.dismissNotifications(v);
            globalState.notifClearing = false;
            globalState.notifExpanded = ({});
        }
    }

    NotificationsBackend {
        id: notificationsBackend
        dndEnabled: globalState.dndEnabled
        soundPath: globalState.notificationSoundPath
        volume: globalState.notificationSoundVolume
        onNotificationReceived: (notification) => {
            toastWindow.pushToast(
            notification.appName,
            notification.summary,
            notification.body,
            notification.urgency === NotificationUrgency.Critical
            );
        }
    }

    Process {
        id: notificationSoundListProcess
        command: ["bash", "-c",
        "SDIR=\"$HOME/.config/quickshell/notification-sound\"; mkdir -p \"$SDIR\"; " +
        "find \"$SDIR\" -maxdepth 1 -type f \\( -iname '*.mp3' -o -iname '*.wav' -o -iname '*.ogg' -o -iname '*.oga' -o -iname '*.flac' \\) | sort | while read -r f; do " +
        "  echo \"$f|$(basename \"$f\")\"; " +
        "done"
        ]
        running: false
        property var _acc: []
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.split("|");
                if (parts.length < 2) return;
                notificationSoundListProcess._acc.push({ path: parts[0], name: parts[1] });
            }
        }
        onRunningChanged: {
            if (running) { notificationSoundListProcess._acc = []; return; }
            globalState.notificationSoundList = notificationSoundListProcess._acc;
            notificationSoundListProcess._acc = [];
            globalState.notificationSoundLoaded = true;
        }
    }

    function reloadNotificationSounds() {
      globalState.notificationSoundList = [];
      globalState.notificationSoundLoaded = false;
      notificationSoundListProcess.running = true;
    }

    Timer {
        id: notificationSoundListInitTimer
        interval: 900; running: globalState.deferredLateReady; repeat: false
        onTriggered: reloadNotificationSounds()
    }

    Process {
        id: notificationSoundWatchProcess
        command: ["bash", "-c",
        "SDIR=\"$HOME/.config/quickshell/notification-sound\"; mkdir -p \"$SDIR\"; " +
        "while true; do " +
        "  inotifywait -e create,delete,moved_to,moved_from,close_write -qq \"$SDIR\" 2>/dev/null; " +
        "  sleep 0.3; echo reload; " +
        "done"
        ]
        running: false
        stdout: SplitParser { onRead: (line) => { reloadNotificationSounds(); } }
    }

    function setNotificationSoundPath(path) {
      globalState.notificationSoundPath = path;
      savePrefs();
    }

    function setNotificationSoundVolume(v) {
      v = Math.max(0, Math.min(100, Math.round(v)));
      if (globalState.notificationSoundVolume === v) return;
      globalState.notificationSoundVolume = v;
      savePrefs();
    }

    function previewNotificationSound(path) {
      if (!path) return;
      Quickshell.execDetached(["mpv", "--no-video", "--really-quiet", "--volume=" + Math.round(globalState.notificationSoundVolume), path]);
    }
}
