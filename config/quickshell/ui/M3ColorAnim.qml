import QtQuick

// ColorAnimation with the theme's standard duration and curve
ColorAnimation {
    duration: m3.durDefault
    easing.type: Easing.BezierSpline
    easing.bezierCurve: m3.standardCurve
}
