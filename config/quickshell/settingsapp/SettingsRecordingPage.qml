import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"
import "../settings"
import "../panels"

// Settings: screen recording page
Item {
    id: settingsRecordingPage
    anchors.fill: parent
    visible: settingsPopup.activeSection === "screen record"
    onVisibleChanged: if (visible && !recDetectProcess.running) recDetectProcess.running = true

    ScrollView {
        id: recSettingsScrollView
        anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.left: parent.left
        anchors.leftMargin: 24; anchors.topMargin: 24; anchors.bottomMargin: 24
        width: parent.width - 36
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: recSettingsScrollView.availableWidth
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: recStatusRow.implicitHeight + 40
                radius: 32
                color: globalState.glassMode ? ga(pal.surfacePop, 0.78) : pal.surfacePop

                GridLayout {
                    id: recStatusRow
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                    anchors.margins: 20
                    columns: 2
                    columnSpacing: 16; rowSpacing: 16

                    Item {
                        width: 48; height: 48
                        RecIndicator {
                            anchors.fill: parent
                            size: 48
                            active: globalState.recBusy
                            running: settingsWindow.winOpen
                            idleColor: pal.secondaryCont
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "\ue04b"
                            font.family: "Material Symbols Rounded"; font.pixelSize: 22
                            color: globalState.recBusy ? "#FFFFFF" : pal.colorOnSurface
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            Layout.fillWidth: true
                            text: !globalState.recBusy ? tr("rec_idle")
                                  : globalState.recSaving ? tr("rec_saving")
                                  : (globalState.recPaused ? tr("rec_paused") : tr("rec_recording")) + " · " + globalState.recFmt(globalState.recElapsedMs)
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(16 * globalState.fontScale); font.weight: Font.DemiBold
                            color: pal.colorOnSurface
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: globalState.recBackendAvail === "gsr" ? tr("rec_backend") + ": gpu-screen-recorder"
                                : globalState.recBackendAvail === "wf"  ? tr("rec_backend") + ": wf-recorder"
                                : globalState.recBackendAvail === "none" ? tr("rec_err_nobin") : " "
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                            color: globalState.recBackendAvail === "none" ? pal.error : pal.muted
                            elide: Text.ElideRight
                        }
                    }
                    Rectangle {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: 24
                        opacity: globalState.recBackendAvail === "none" && !globalState.recBusy ? 0.5 : 1
                        color: globalState.recBusy ? ga(pal.error, 0.18) : pal.primary
                        Behavior on color { M3ColorAnim {} }
                        Text {
                            id: recStartTxt
                            anchors.centerIn: parent
                            text: globalState.recBusy ? tr("rec_stop") : tr("rec_start")
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale); font.weight: Font.DemiBold
                            color: globalState.recBusy ? pal.error : pal.colorOnPrimary
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            enabled: globalState.recBusy || globalState.recBackendAvail !== "none"
                            onClicked: {
                                if (!globalState.recBusy) settingsWindow.closeWin();
                                globalState.recToggle();
                            }
                        }
                    }
                }
            }

            SettingsGroup {
                Layout.fillWidth: true
                title: tr("rec_group_video")
                icon: "\ue04b"
                titleSize: 12; bodySpacing: 12
                expanded: globalState.settingsExpanded["rec_group_video"] === true
                onToggled: globalState.toggleSettingsGroup("rec_group_video")
                accent: pal.primary; textColor: pal.colorOnSurfVar; lineColor: pal.surfaceVar; hoverColor: pal.surfaceVar
            cardColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.7) : pal.surfaceDeep; cardOpenColor: globalState.glassMode ? ga(pal.surfaceElevated, 0.78) : pal.surfaceElevated; innerColor: globalState.glassMode ? ga(pal.surfaceHigh, 0.82) : pal.surfaceHigh; iconContColor: pal.secondaryCont; titleColor: pal.colorOnSurface; subColor: pal.colorOnSurfVar; bodyFont: globalState.fontSecondary
                titleFont: globalState.fontPrimary; fontScale: globalState.fontScale

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text { text: "\ue9e4"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary }
                        Text {
                            Layout.fillWidth: true
                            text: tr("rec_fps")
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                            color: pal.colorOnSurfVar
                        }
                        Text {
                            text: globalState.recFps + " fps"
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
                            color: pal.muted
                        }
                    }
                    SegmentedPill {
                        Layout.fillWidth: true
                        options: [24, 30, 60, 120, 144].map(function (f) { return { value: f, label: f + "" }; })
                        current: globalState.recFps
                        onPicked: (v) => setRecFps(v)
                        trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
                        selectedColor: pal.primary
                        textColor: pal.colorOnSurfVar
                        selectedTextColor: pal.colorOnPrimary
                        iconColor: pal.primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text { text: "\ue30c"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary }
                        Text {
                            Layout.fillWidth: true
                            text: tr("rec_resolution")
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                            color: pal.colorOnSurfVar
                        }
                    }
                    SegmentedPill {
                        Layout.fillWidth: true
                        fontSize: Math.round(11 * globalState.fontScale)
                        options: [{ value: "native", label: tr("rec_native") },
                                  { value: "2160",   label: "4K" },
                                  { value: "1440",   label: "1440p" },
                                  { value: "1080",   label: "1080p" },
                                  { value: "720",    label: "720p" }]
                        current: globalState.recResolution
                        onPicked: (v) => setRecResolution(v)
                        trackColor: m3.glassy(m3.surfaceContainerHighest, 0.6)
                        selectedColor: pal.primary
                        textColor: pal.colorOnSurfVar
                        selectedTextColor: pal.colorOnPrimary
                        iconColor: pal.primary
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: tr("rec_res_note") + " " + tr("rec_apply_note")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                        color: pal.mutedDeep
                    }
                }
            }

            SettingsGroup {
                Layout.fillWidth: true
                title: tr("rec_group_output")
                icon: "\ue2c7"
                titleSize: 12; bodySpacing: 12
                expanded: globalState.settingsExpanded["rec_group_output"] === true
                onToggled: globalState.toggleSettingsGroup("rec_group_output")
                accent: pal.primary; textColor: pal.colorOnSurfVar; lineColor: pal.surfaceVar; hoverColor: pal.surfaceVar
            cardColor: globalState.glassMode ? ga(pal.surfaceDeep, 0.7) : pal.surfaceDeep; cardOpenColor: globalState.glassMode ? ga(pal.surfaceElevated, 0.78) : pal.surfaceElevated; innerColor: globalState.glassMode ? ga(pal.surfaceHigh, 0.82) : pal.surfaceHigh; iconContColor: pal.secondaryCont; titleColor: pal.colorOnSurface; subColor: pal.colorOnSurfVar; bodyFont: globalState.fontSecondary
                titleFont: globalState.fontPrimary; fontScale: globalState.fontScale

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        FadeIcon { text: globalState.recMic ? "\ue029" : "\ue02b"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary }
                        Text {
                            Layout.fillWidth: true
                            text: tr("rec_mic")
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                            color: pal.colorOnSurfVar
                        }
                        ESwitch {
                            checked: globalState.recMic
                            onToggled: setRecMic(!globalState.recMic)
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: tr("rec_mic_note") + " " + tr("rec_apply_note")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                        color: pal.mutedDeep
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text { text: "\ue2c7"; font.family: "Material Symbols Rounded"; font.pixelSize: 16; color: pal.primary }
                    Text {
                        Layout.fillWidth: true
                        text: tr("rec_folder")
                        font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale); font.weight: Font.Medium
                        color: pal.colorOnSurfVar
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        Layout.preferredWidth: recOpenTxt.implicitWidth + 24
                        height: 30; radius: 10
                        color: recOpenHov.hovered ? pal.surfaceVar : (globalState.glassMode ? ga(pal.surfaceDeep, 0.6) : pal.surfaceDeep)
                        Behavior on color { M3ColorAnim { duration: m3.durFast } }
                        Text {
                            id: recOpenTxt
                            anchors.centerIn: parent
                            text: tr("rec_open_folder")
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                            color: pal.colorOnSurface
                        }
                        HoverHandler { id: recOpenHov }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: openRecFolder() }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: globalState.recBackendAvail === "wf"
                    wrapMode: Text.WordWrap
                    text: tr("rec_wf_note")
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(10 * globalState.fontScale)
                    color: pal.mutedDeep
                }
            }
        }
    }
}
