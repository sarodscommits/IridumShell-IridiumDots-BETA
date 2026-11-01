import QtQuick

// NumberAnimation with the theme's standard duration and curve
NumberAnimation {
    duration: m3.durDefault
    easing.type: Easing.BezierSpline
    easing.bezierCurve: m3.standardCurve
}
