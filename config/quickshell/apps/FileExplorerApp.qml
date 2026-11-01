import QtQuick
import ".."

// Loads FileExplorer on demand
FileExplorer {
    gs: globalState
    colors: pal
    Binding on inst { when: typeof winId === "number"; value: typeof winId === "number" ? winId : 0 }
}
