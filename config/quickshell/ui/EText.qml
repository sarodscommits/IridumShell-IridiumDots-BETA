import QtQuick

// Text using the M3 type scale
Text {
    property string role: "bodyMedium"
    property bool emph: false
    readonly property var spec: m3.type[role]
    color: m3.inkSurface
    font.family: (role.indexOf("body") === 0) ? m3.fontBody : m3.font
    font.pixelSize: Math.round(spec[0] * m3.fs)
    font.weight: m3.tw(role, emph)
    lineHeightMode: Text.FixedHeight
    lineHeight: Math.round(spec[1] * m3.fs)
    wrapMode: Text.NoWrap
}
