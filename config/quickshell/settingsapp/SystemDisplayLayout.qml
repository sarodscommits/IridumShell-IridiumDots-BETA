import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"

// Settings > System: live arrangement of the enabled monitors (logical size = px / scale)
SystemSecondaryCard {
    id: lay
    required property var logic
    icon: ""
    title: tr("sys_layout")
    value: lay.logic.monitors.filter(function (m) { return !m.disabled; }).length + " / " + lay.logic.monitors.length
    accent: pal.accent

    Item {
        id: layArea
        Layout.fillWidth: true
        Layout.preferredHeight: 140
        readonly property var mons: lay.logic.monitors.filter(function (m) { return !m.disabled && m.width > 0; })
        readonly property var box: {
            var x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
            mons.forEach(function (m) {
                x0 = Math.min(x0, m.x); y0 = Math.min(y0, m.y);
                x1 = Math.max(x1, m.x + m.width / m.scale); y1 = Math.max(y1, m.y + m.height / m.scale);
            });
            return mons.length ? { x: x0, y: y0, w: x1 - x0, h: y1 - y0 } : { x: 0, y: 0, w: 1, h: 1 };
        }
        readonly property real k: Math.min((width - 8) / box.w, (height - 8) / box.h)

        Repeater {
            model: layArea.mons
            Rectangle {
                required property var modelData
                readonly property real lw: modelData.width / modelData.scale
                readonly property real lh: modelData.height / modelData.scale
                x: (layArea.width - layArea.box.w * layArea.k) / 2 + (modelData.x - layArea.box.x) * layArea.k + 2
                y: (layArea.height - layArea.box.h * layArea.k) / 2 + (modelData.y - layArea.box.y) * layArea.k + 2
                width: lw * layArea.k - 4
                height: lh * layArea.k - 4
                radius: 10
                color: modelData.focused ? ga(pal.primary, 0.28) : ga(pal.colorOnSurface, 0.08)
                border.width: 2
                border.color: modelData.focused ? pal.primary : pal.surfaceVar
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.name
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.DemiBold
                        color: pal.colorOnSurface
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.width + "×" + modelData.height
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(9.5 * globalState.fontScale)
                        color: pal.muted
                    }
                }
            }
        }
    }
}
