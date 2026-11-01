import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Edit mode overlay of the overview dashboard
Item {
    id: ncDashEditLayer
    anchors.fill: ncDashLayer
    visible: globalState.ncEditMode && ncPage1Group.pageOn
    readonly property var info: ({
        weather: { icon: "", name: tr("nce_weather") },
        cal:     { icon: "", name: tr("nce_cal") },
        mon:     { icon: "", name: tr("ic_page_monitor") },
        aud:     { icon: "", name: tr("equalizer") },
        clip:    { icon: "", name: tr("nce_clip") },
        fetch:   { icon: "", name: tr("nce_fetch") }
    })
    function rectFor(k) {
        switch (k) {
            case "weather": return ncDashLayer.rWeather;
            case "cal":     return ncDashLayer.rCal;
            case "mon":     return ncDashLayer.rMon;
            case "aud":     return ncDashLayer.rAud;
            case "clip":    return ncDashLayer.rClip;
            case "fetch":   return ncDashLayer.rFetch;
        }
        return Qt.rect(0, 0, 0, 0);
    }

    Repeater {
        model: globalState.ncDashOrder
        Rectangle {
            id: ncDashEditCard
            required property string modelData
            required property int index
            readonly property rect r: ncDashEditLayer.rectFor(modelData)
            readonly property bool first: index === 0
            readonly property bool last: index === globalState.ncDashOrder.length - 1
            x: r.x; y: r.y; width: r.width; height: r.height
            Behavior on y { M3SpringAnim { token: "spatialDefault" } }
            radius: 28
            color: ga(pal.surface, 0.55)
            border.width: 2
            border.color: ga(pal.primary, ncDashCardHov.hovered ? 0.9 : 0.5)
            Behavior on border.color { M3ColorAnim { duration: m3.durFast } }
            HoverHandler { id: ncDashCardHov }
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width - 24, ncDashEditRow.implicitWidth + 20)
                height: 48; radius: 24
                color: globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.92) : containerDark(pal.secondaryCont)
                border.width: 1
                border.color: ga(pal.primary, 0.35)
                RowLayout {
                    id: ncDashEditRow
                    anchors.fill: parent
                    anchors.leftMargin: 14; anchors.rightMargin: 6
                    spacing: 6
                    FadeIcon {
                        text: ncDashEditLayer.info[ncDashEditCard.modelData] ? ncDashEditLayer.info[ncDashEditCard.modelData].icon : ""
                        font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: pal.primary
                    }
                    Text {
                        Layout.fillWidth: true
                        text: ncDashEditLayer.info[ncDashEditCard.modelData] ? ncDashEditLayer.info[ncDashEditCard.modelData].name : ncDashEditCard.modelData
                        font.family: globalState.fontPrimary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.Bold
                        color: pal.colorOnSurface; elide: Text.ElideRight
                    }
                    Repeater {
                        model: [
                        { icon: "", act: "up" },
                        { icon: "", act: "down" },
                        { icon: "", act: "remove" }
                        ]
                        Rectangle {
                            id: ncDashActBtn
                            required property var modelData
                            readonly property bool can: modelData.act === "up" ? !ncDashEditCard.first
                            : modelData.act === "down" ? !ncDashEditCard.last : true
                            readonly property bool hot: can && ncDashActHov.hovered
                            width: 36; height: 36; radius: 18
                            opacity: can ? 1 : 0.35
                            color: modelData.act === "remove"
                            ? (hot ? pal.error : ga(pal.error, 0.18))
                            : (hot ? pal.primary : (globalState.glassMode ? ga(pal.surface, 0.5) : pal.surface))
                            Behavior on color { M3ColorAnim { duration: m3.durFast } }
                            Text {
                                anchors.centerIn: parent
                                text: ncDashActBtn.modelData.icon
                                font.family: "Material Symbols Rounded"; font.pixelSize: 18
                                color: ncDashActBtn.modelData.act === "remove"
                                ? (ncDashActBtn.hot ? "white" : pal.error)
                                : (ncDashActBtn.hot ? pal.colorOnPrimary : pal.colorOnSurface)
                            }
                            HoverHandler { id: ncDashActHov }
                            MouseArea {
                                anchors.fill: parent
                                enabled: ncDashActBtn.can
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var k = ncDashEditCard.modelData;
                                    if (ncDashActBtn.modelData.act === "up") globalState.ncDashMove(k, -1);
                                    else if (ncDashActBtn.modelData.act === "down") globalState.ncDashMove(k, 1);
                                    else globalState.ncDashRemove(k);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        visible: ncDashLayer.vert && ncDashLayer.vAddH > 0
        x: 0
        y: ncDashLayer.vAddY
        width: ncDashLayer.width
        height: ncDashLayer.vAddH
        Behavior on y { M3SpringAnim { token: "spatialDefault" } }
        radius: 28
        color: "transparent"
        border.width: 2
        border.color: ga(pal.colorOnSurfVar, 0.35)
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 8
            Text {
                Layout.fillWidth: true
                text: globalState.ncDashHidden.length > 0 ? tr("nce_add_cards") : tr("nce_all_cards")
                font.family: globalState.fontPrimary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Bold
                color: globalState.ncDashHidden.length > 0 ? pal.colorOnSurface : pal.colorOnSurfVar
                horizontalAlignment: globalState.ncDashHidden.length > 0 ? Text.AlignLeft : Text.AlignHCenter
                Layout.fillHeight: globalState.ncDashHidden.length === 0
                verticalAlignment: Text.AlignVCenter
            }
            Flow {
                Layout.fillWidth: true
                visible: globalState.ncDashHidden.length > 0
                spacing: 6
                Repeater {
                    model: globalState.ncDashHidden
                    Rectangle {
                        id: ncDashAddChip
                        required property string modelData
                        width: ncDashAddRow.implicitWidth + 22
                        height: 34; radius: 17
                        color: ncDashAddHov.hovered ? pal.primary : (globalState.glassMode ? ga(containerDark(pal.secondaryCont), 0.6) : containerDark(pal.secondaryCont))
                        Behavior on color { M3ColorAnim { duration: m3.durFast } }
                        RowLayout {
                            id: ncDashAddRow
                            anchors.centerIn: parent
                            spacing: 5
                            Text { text: ""; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: ncDashAddHov.hovered ? pal.colorOnPrimary : pal.primary }
                            FadeIcon { text: ncDashEditLayer.info[ncDashAddChip.modelData].icon; font.family: "Material Symbols Rounded"; font.pixelSize: 15; color: ncDashAddHov.hovered ? pal.colorOnPrimary : pal.colorOnSurfVar }
                            Text { text: ncDashEditLayer.info[ncDashAddChip.modelData].name; font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium; color: ncDashAddHov.hovered ? pal.colorOnPrimary : pal.colorOnSurface }
                        }
                        HoverHandler { id: ncDashAddHov }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: globalState.ncDashAdd(ncDashAddChip.modelData) }
                    }
                }
            }
        }
    }
}
