import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Frame silhouette: bars, island notch and bulge
Shape {
    id: frameShape
    width:  unifiedFrame.barVertical ? parent.height : parent.width
    height: unifiedFrame.barVertical ? parent.width  : parent.height
    transform: Matrix4x4 { matrix: unifiedFrame.frameMatrix }
    opacity: currentFrameOpacity()
    Behavior on opacity { M3NumberAnim {} }

    ShapePath {
        fillColor: pal.surface
        fillRule: ShapePath.OddEvenFill
        strokeColor: "transparent"

        PathMove { x: 0; y: 0 }
        PathLine { x: frameShape.width; y: 0 }
        PathLine { x: frameShape.width; y: frameShape.height }
        PathLine { x: 0; y: frameShape.height }
        PathLine { x: 0; y: 0 }

        PathMove { x: unifiedFrame.leftW + unifiedFrame.topLeftOuterR; y: unifiedFrame.topStartY }
        PathLine { x: unifiedFrame.topNotchLeftX - unifiedFrame.topNotchJoinR; y: unifiedFrame.topStartY }
        PathQuad {
            x: unifiedFrame.topNotchLeftX
            y: unifiedFrame.topStartY + unifiedFrame.topNotchJoinR
            controlX: unifiedFrame.topNotchLeftX
            controlY: unifiedFrame.topStartY
        }
        PathLine {
            x: unifiedFrame.topNotchLeftX
            y: unifiedFrame.frameTopH + unifiedFrame.topLeftCornerExtend - unifiedFrame.topNotchJoinR
        }
        PathQuad {
            x: unifiedFrame.topNotchLeftX + unifiedFrame.topNotchJoinR
            y: unifiedFrame.frameTopH + unifiedFrame.topLeftCornerExtend
            controlX: unifiedFrame.topNotchLeftX
            controlY: unifiedFrame.frameTopH + unifiedFrame.topLeftCornerExtend
        }
        PathLine {
            x: unifiedFrame.bulgeLeftX - unifiedFrame.topLeftJoinR
            y: unifiedFrame.frameTopH + unifiedFrame.topLeftCornerExtend
        }
        PathQuad {
            x: unifiedFrame.bulgeLeftX
            y: unifiedFrame.frameTopH + unifiedFrame.topLeftCornerExtend + unifiedFrame.topLeftJoinR
            controlX: unifiedFrame.bulgeLeftX
            controlY: unifiedFrame.frameTopH + unifiedFrame.topLeftCornerExtend
        }
        PathLine {
            x: unifiedFrame.bulgeLeftX
            y: unifiedFrame.frameTopH + unifiedFrame.topBulgeDepth - unifiedFrame.topLeftJoinR
        }
        PathQuad {
            x: unifiedFrame.bulgeLeftX + unifiedFrame.topLeftJoinR
            y: unifiedFrame.frameTopH + unifiedFrame.topBulgeDepth
            controlX: unifiedFrame.bulgeLeftX
            controlY: unifiedFrame.frameTopH + unifiedFrame.topBulgeDepth
        }
        PathLine {
            x: unifiedFrame.bulgeRightX - unifiedFrame.topRightJoinR
            y: unifiedFrame.frameTopH + unifiedFrame.topBulgeDepth
        }
        PathQuad {
            x: unifiedFrame.bulgeRightX
            y: unifiedFrame.frameTopH + unifiedFrame.topBulgeDepth - unifiedFrame.topRightJoinR
            controlX: unifiedFrame.bulgeRightX
            controlY: unifiedFrame.frameTopH + unifiedFrame.topBulgeDepth
        }
        PathLine {
            x: unifiedFrame.bulgeRightX
            y: unifiedFrame.frameTopH + unifiedFrame.topRightCornerExtend + unifiedFrame.topRightJoinR
        }
        PathQuad {
            x: unifiedFrame.bulgeRightX + unifiedFrame.topRightJoinR
            y: unifiedFrame.frameTopH + unifiedFrame.topRightCornerExtend
            controlX: unifiedFrame.bulgeRightX
            controlY: unifiedFrame.frameTopH + unifiedFrame.topRightCornerExtend
        }
        PathLine { x: unifiedFrame.topNotchRightX - unifiedFrame.topNotchJoinR; y: unifiedFrame.frameTopH + unifiedFrame.topRightCornerExtend }
        PathQuad {
            x: unifiedFrame.topNotchRightX
            y: unifiedFrame.frameTopH + unifiedFrame.topRightCornerExtend - unifiedFrame.topNotchJoinR
            controlX: unifiedFrame.topNotchRightX
            controlY: unifiedFrame.frameTopH + unifiedFrame.topRightCornerExtend
        }
        PathLine { x: unifiedFrame.topNotchRightX; y: unifiedFrame.topEndY + unifiedFrame.topNotchJoinR }
        PathQuad {
            x: unifiedFrame.topNotchRightX + unifiedFrame.topNotchJoinR
            y: unifiedFrame.topEndY
            controlX: unifiedFrame.topNotchRightX
            controlY: unifiedFrame.topEndY
        }
        PathLine { x: frameShape.width - unifiedFrame.rightW - unifiedFrame.topRightOuterR; y: unifiedFrame.topEndY }
        PathArc  {
            x: frameShape.width - unifiedFrame.rightW; y: unifiedFrame.topEndY + unifiedFrame.topRightOuterR
            radiusX: unifiedFrame.topRightOuterR; radiusY: unifiedFrame.topRightOuterR
            direction: PathArc.Clockwise
        }
        PathLine { x: frameShape.width - unifiedFrame.rightW; y: unifiedFrame.bottomRightY - unifiedFrame.bottomRightOuterR }
        PathArc  {
            x: frameShape.width - unifiedFrame.rightW - unifiedFrame.bottomRightOuterR; y: unifiedFrame.bottomRightY
            radiusX: unifiedFrame.bottomRightOuterR; radiusY: unifiedFrame.bottomRightOuterR
            direction: PathArc.Clockwise
        }
        PathLine { x: unifiedFrame.bottomNotchRightX + unifiedFrame.bottomNotchJoinR; y: unifiedFrame.bottomRightY }
        PathQuad {
            x: unifiedFrame.bottomNotchRightX
            y: unifiedFrame.bottomRightY - unifiedFrame.bottomNotchJoinR
            controlX: unifiedFrame.bottomNotchRightX
            controlY: unifiedFrame.bottomRightY
        }
        PathLine {
            x: unifiedFrame.bottomNotchRightX
            y: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomRightCornerExtend + unifiedFrame.bottomNotchJoinR
        }
        PathQuad {
            x: unifiedFrame.bottomNotchRightX - unifiedFrame.bottomNotchJoinR
            y: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomRightCornerExtend
            controlX: unifiedFrame.bottomNotchRightX
            controlY: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomRightCornerExtend
        }
        PathLine {
            x: unifiedFrame.bulgeRightX + unifiedFrame.bottomRightJoinR
            y: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomRightCornerExtend
        }
        PathQuad {
            x: unifiedFrame.bulgeRightX
            y: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomRightCornerExtend - unifiedFrame.bottomRightJoinR
            controlX: unifiedFrame.bulgeRightX
            controlY: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomRightCornerExtend
        }
        PathLine {
            x: unifiedFrame.bulgeRightX
            y: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomBulgeDepth + unifiedFrame.bottomRightJoinR
        }
        PathQuad {
            x: unifiedFrame.bulgeRightX - unifiedFrame.bottomRightJoinR
            y: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomBulgeDepth
            controlX: unifiedFrame.bulgeRightX
            controlY: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomBulgeDepth
        }
        PathLine {
            x: unifiedFrame.bulgeLeftX + unifiedFrame.bottomLeftJoinR
            y: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomBulgeDepth
        }
        PathQuad {
            x: unifiedFrame.bulgeLeftX
            y: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomBulgeDepth + unifiedFrame.bottomLeftJoinR
            controlX: unifiedFrame.bulgeLeftX
            controlY: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomBulgeDepth
        }
        PathLine {
            x: unifiedFrame.bulgeLeftX
            y: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomLeftCornerExtend - unifiedFrame.bottomLeftJoinR
        }
        PathQuad {
            x: unifiedFrame.bulgeLeftX - unifiedFrame.bottomLeftJoinR
            y: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomLeftCornerExtend
            controlX: unifiedFrame.bulgeLeftX
            controlY: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomLeftCornerExtend
        }
        PathLine {
            x: unifiedFrame.bottomNotchLeftX + unifiedFrame.bottomNotchJoinR
            y: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomLeftCornerExtend
        }
        PathQuad {
            x: unifiedFrame.bottomNotchLeftX
            y: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomLeftCornerExtend + unifiedFrame.bottomNotchJoinR
            controlX: unifiedFrame.bottomNotchLeftX
            controlY: frameShape.height - unifiedFrame.frameBottomH - unifiedFrame.bottomLeftCornerExtend
        }
        PathLine { x: unifiedFrame.bottomNotchLeftX; y: unifiedFrame.bottomLeftY - unifiedFrame.bottomNotchJoinR }
        PathQuad {
            x: unifiedFrame.bottomNotchLeftX - unifiedFrame.bottomNotchJoinR
            y: unifiedFrame.bottomLeftY
            controlX: unifiedFrame.bottomNotchLeftX
            controlY: unifiedFrame.bottomLeftY
        }
        PathLine { x: unifiedFrame.leftW + unifiedFrame.bottomLeftOuterR; y: unifiedFrame.bottomLeftY }
        PathArc  {
            x: unifiedFrame.leftW; y: unifiedFrame.bottomLeftY - unifiedFrame.bottomLeftOuterR
            radiusX: unifiedFrame.bottomLeftOuterR; radiusY: unifiedFrame.bottomLeftOuterR
            direction: PathArc.Clockwise
        }
        PathLine { x: unifiedFrame.leftW; y: unifiedFrame.topStartY + unifiedFrame.topLeftOuterR }
        PathArc  {
            x: unifiedFrame.leftW + unifiedFrame.topLeftOuterR; y: unifiedFrame.topStartY
            radiusX: unifiedFrame.topLeftOuterR; radiusY: unifiedFrame.topLeftOuterR
            direction: PathArc.Clockwise
        }
    }
}
