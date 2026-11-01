import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."
import "../ui"
import "SystemDisplay.js" as SD

// Settings > System: one monitor (resolution, refresh rate, scale, position, mirror, VRR)
SystemSecondaryCard {
    id: mc
    required property var logic
    required property var mon
    property int cols: 5
    readonly property var d: logic.drafts[mon.name] || ({})
    readonly property bool multi: logic.monitors.length > 1
    readonly property string nativeRes: SD.nativeRes(mon)
    readonly property var supported: SD.supportedRes(mon)
    readonly property string curRes: d.res === "auto" ? nativeRes : (d.res || nativeRes)
    readonly property var rates: SD.ratesFor(mon, curRes)

    icon: ""
    title: mon.name
    value: ((mon.make || "") + " " + (mon.model || "")).trim() || mon.description || mon.name
    sub: mon.disabled ? tr("sys_off") : SD.resLabel(mon.width + "x" + mon.height) + " · " + SD.rateLabel(mon.refreshRate) + " · ×" + (Math.round(mon.scale * 100) / 100)
    accent: pal.primary

    headerExtra: ESwitch {
        visible: mc.multi
        checked: !mc.d.disabled
        onToggled: mc.logic.setField(mc.mon.name, "disabled", !mc.d.disabled)
    }

    component Pill: SegmentedPill {
        Layout.fillWidth: true
        trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
        selectedColor: pal.primary
        textColor: pal.colorOnSurfVar
        selectedTextColor: pal.colorOnPrimary
        iconColor: pal.primary
        fontSize: Math.round(11 * globalState.fontScale)
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 14
        visible: !mc.d.disabled

        SystemOptionRow {
            icon: ""
            label: tr("sys_resolution")
            valueText: SD.resLabel(mc.nativeRes) + " " + tr("sys_native")
            hint: tr("sys_unsupported")
            Pill {
                columns: mc.cols
                options: {
                    var o = [{ value: "auto", label: tr("sys_auto") }];
                    var extra = mc.d.res && mc.d.res !== "auto" && SD.presets.indexOf(mc.d.res) < 0 ? [mc.d.res] : [];
                    if (SD.presets.indexOf(mc.nativeRes) < 0 && extra.indexOf(mc.nativeRes) < 0) extra.push(mc.nativeRes);
                    extra.concat(SD.presets).forEach(function (r) {
                        o.push({ value: r, label: SD.resLabel(r), enabled: mc.supported.indexOf(r) >= 0 });
                    });
                    return o;
                }
                current: mc.d.res
                onPicked: (v) => mc.logic.setField(mc.mon.name, "res", v)
            }
        }

        SystemOptionRow {
            icon: ""
            label: tr("sys_refresh")
            valueText: SD.resLabel(mc.curRes)
            Pill {
                columns: Math.min(mc.cols, mc.rates.length + 1)
                options: [{ value: "auto", label: tr("sys_auto") }].concat(mc.rates.map(function (r) { return { value: r, label: SD.rateLabel(r) }; }))
                current: mc.d.rate
                onPicked: (v) => mc.logic.setField(mc.mon.name, "rate", v)
            }
        }

        SystemOptionRow {
            icon: ""
            label: tr("sys_scale")
            Pill {
                options: [{ value: "auto", label: tr("sys_auto") }].concat([1, 1.25, 1.5, 1.75, 2].map(function (s) { return { value: s, label: "×" + s }; }))
                current: mc.d.scale
                onPicked: (v) => mc.logic.setField(mc.mon.name, "scale", v)
            }
        }

        SystemOptionRow {
            visible: mc.multi
            icon: ""
            label: tr("sys_mirror")
            Pill {
                options: [{ value: "", label: tr("sys_none") }].concat(mc.logic.monitors.filter(function (m) { return m.name !== mc.mon.name; })
                    .map(function (m) { return { value: m.name, label: m.name }; }))
                current: mc.d.mirror || ""
                onPicked: (v) => mc.logic.setField(mc.mon.name, "mirror", v)
            }
        }

        SystemOptionRow {
            visible: mc.multi && !mc.d.mirror
            icon: ""
            label: tr("sys_position")
            Pill {
                options: {
                    var o = [{ value: "auto", label: tr("sys_auto") }, { value: "auto-left", label: tr("sys_left") },
                             { value: "auto-right", label: tr("sys_right") }, { value: "auto-up", label: tr("sys_above") },
                             { value: "auto-down", label: tr("sys_below") }];
                    if (mc.d.position && mc.d.position.indexOf("auto") !== 0) o.push({ value: mc.d.position, label: mc.d.position });
                    return o;
                }
                current: mc.d.position
                onPicked: (v) => mc.logic.setField(mc.mon.name, "position", v)
            }
        }

        SystemOptionRow {
            icon: ""
            label: tr("sys_vrr")
            Pill {
                options: [{ value: 0, label: tr("sys_off") }, { value: 1, label: tr("sys_on") }, { value: 2, label: tr("sys_fullscreen") }]
                current: mc.d.vrr
                onPicked: (v) => mc.logic.setField(mc.mon.name, "vrr", v)
            }
        }
    }
}
