import QtQuick
import ".."

// Loads TextEditor on demand
TextEditor {
    gs: globalState
    colors: pal
    Binding on inst { when: typeof winId === "number"; value: typeof winId === "number" ? winId : 0 }
}
