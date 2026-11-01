import QtQuick
import QtQuick.Layouts
import "../ui"

// Tile components of the Control Center grid, looked up by key
Item {
    id: ncTiles
    Component {
        id: ncCtlBrightComp
        Item {
            RowLayout {
                anchors.fill: parent
                spacing: 8
                PercentSlider {
                    id: ncBrightTrack
                    Layout.fillWidth: true
                    icon: ""
                    property real displayPct: globalState.rawBrightness / 100
                    value: displayPct
                    trackH: 28
                    handleHOverride: 38
                    height: 40
                    activeColor: pal.toggleOn
                    inactiveColor: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont)
                    showBubble: true
                    onPctPressed: { globalState.brightnessAdjusting = true; }
                    onPctMoved: (v) => { globalState.setBrightness(v); }
                    onPctReleased: { globalState.brightnessAdjusting = false; }
                }
            }
        }
    }
    Component {
        id: ncCtlVolComp
        CcMuteSlider {
            muted: globalState.isMuted
            icon: globalState.isMuted ? "" : ""
            level: globalState.rawVolumeValue / 100
            activeColor: globalState.isMuted?Qt.darker(pal.error, 1.8):pal.toggleOn
            onToggleMute: globalState.toggleMute()
            onPctMoved: (v) => setVolumePercent(v)
        }
    }
    Component {
        id: ncCtlMicComp
        CcMuteSlider {
            muted: globalState.isMicMuted
            icon: globalState.isMicMuted ? "" : ""
            level: globalState.rawMicVolume / 100
            onToggleMute: globalState.toggleMicMute()
            onPctMoved: (v) => setMicPercent(v)
        }
    }
    Component {
        id: ncCtlNetComp
        CcNetTile { id: ncNetTile }
    }
    Component {
        id: ncCtlAccessComp
        CcAccessTile { id: ncAccessTile }
    }
    Component {
        id: ncCtlTermComp
        CcTermTile { id: ccTermTile }
    }
    Component {
        id: ncCtlShotComp
        CcShotTile { id: ncShotTile }
    }

    Component {
        id: ncCtlRecComp
        CcRecTile { id: ncRecTile }
    }

    Component {
        id: ncCtlPerfComp
        CcPerfTile { id: ncPerfTile }
    }
    Component {
        id: ncCtlSaverComp
        CcSaverTile { id: ncSaverTile }
    }
    Component {
        id: ncCtlPlaneComp
        CcPlaneTile { id: ncPlaneTile }
    }
    Component {
        id: ncCtlEyeComp
        CcEyeTile { id: ncEyeTile }
    }
    function compFor(k) {
        switch (k) {
            case "bright": return ncCtlBrightComp;
            case "vol":    return ncCtlVolComp;
            case "mic":    return ncCtlMicComp;
            case "wifi":
            case "bt":     return ncCtlNetComp;
            case "dark":
            case "dnd":    return ncCtlAccessComp;
            case "term":   return ncCtlTermComp;
            case "shot":   return ncCtlShotComp;
            case "rec":    return ncCtlRecComp;
            case "perf":   return ncCtlPerfComp;
            case "saver":  return ncCtlSaverComp;
            case "plane":  return ncCtlPlaneComp;
            case "eye":    return ncCtlEyeComp;
        }
        return null;
    }
}
