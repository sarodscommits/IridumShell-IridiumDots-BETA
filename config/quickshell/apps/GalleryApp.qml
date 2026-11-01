import QtQuick
import ".."

// Loads Gallery on demand
Gallery {
    gs: globalState
    colors: pal
    Binding on inst { when: typeof winId === "number"; value: typeof winId === "number" ? winId : 0 }
}
