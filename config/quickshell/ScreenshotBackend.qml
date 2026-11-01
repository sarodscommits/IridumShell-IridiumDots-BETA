import QtQuick
import Quickshell.Io

// Area screenshot (grim + slurp), fired by selectCaptureTrigger
Item {
    id: screenshotBackend

    property int trigger: 0
    onTriggerChanged: screenshotSelectProcess.running = true

    // Run slurp under Hyprland via hl.dsp.exec_cmd()
    Process {
        id: screenshotSelectProcess
        command: ["hyprctl", "dispatch",
            "hl.dsp.exec_cmd([[mkdir -p ~/screenshots; FILE=~/screenshots/$(date +%Y%m%d_%H%M%S).png; if grim -g \"$(slurp)\" \"$FILE\"; then notify-send \"Screenshot saved\" \"$FILE\" -t 2000; fi]])"]
        running: false
        onRunningChanged: console.log("[SS] running =", running)
        stdout: SplitParser {
            onRead: (line) => console.log("[SS] stdout:", line)
        }
        stderr: SplitParser {
            onRead: (line) => console.log("[SS] stderr:", line)
        }
        onExited: (exitCode, exitStatus) => {
            // dispatch returns early; the script itself notifies on completion
            console.log("[SS] hyprctl dispatch exited, exitCode =", exitCode, " exitStatus =", exitStatus);
        }
    }
}
