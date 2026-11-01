import QtQuick

// SpringAnimation driven by a theme motion token
SpringAnimation {
    property string token: "spatialDefault"
    spring: m3.qs(token)
    damping: m3.qd(token)
    epsilon: 0.05
}
