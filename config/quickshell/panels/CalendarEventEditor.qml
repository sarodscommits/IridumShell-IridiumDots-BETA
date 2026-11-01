import QtQuick
import QtQuick.Layouts
import "../ui"

// Calendar event editor
Item {
    id: editorRoot

    required property color colorPrimary
    required property color colorOnPrimaryCont
    required property color colorOnSurface
    required property color colorOnSurfVar
    required property color colorTextSecondary
    required property color colorSurface
    property color colorError: "#F2B8B5"
    readonly property bool glass: globalState.glassMode
    function cardColor(hover) {
        var c = editorRoot.colorSurface;
        return glass ? Qt.rgba(c.r, c.g, c.b, 0.6) : c;
    }
    readonly property int _rmCloseW: 44
    readonly property int _rmGap: 4

    property bool   hasSelection:     false
    property string selectedDateLabel: ""
    property var    eventsForDay:     []
    property var    allEvents:        []
    property var    eventTypes:       []
    property int    selectedTypeIndex: 0
    property string placeholderText:  "Pick a day"
    property string inputPlaceholder: "Add a reminder..."
    property string addLabel:         "Add"
    property string emptyListText:    "No reminders for this day yet"

    signal addRequested(string title, string type)
    signal removeRequested(int index)
    signal removeGlobalRequested(string dateKey, int index)
    signal inputFocusChanged(bool focused)

    Item {
        visible: !editorRoot.hasSelection
        anchors.fill: parent

        Text {
            visible: editorRoot.allEvents.length === 0
            anchors.centerIn: parent
            width: parent.width - 24
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: editorRoot.placeholderText
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(13 * globalState.fontScale)
            color: editorRoot.colorTextSecondary
            opacity: 0.8
        }

        ListView {
            visible: editorRoot.allEvents.length > 0
            anchors.fill: parent
            clip: true
            spacing: 4
            model: editorRoot.allEvents
            delegate: ReminderRow {
                editor: editorRoot; height: 38; iconSize: 15; showDate: true
                onRemoveClicked: editorRoot.removeGlobalRequested(modelData.dateKey, modelData.indexInDay)
            }
        }
    }

    ColumnLayout {
        visible: editorRoot.hasSelection
        anchors.fill: parent
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: editorRoot.selectedDateLabel
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(14 * globalState.fontScale); font.weight: Font.Medium
            color: editorRoot.colorOnSurface
            elide: Text.ElideRight
        }

        Flow {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: editorRoot.eventTypes
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    property bool active: index === editorRoot.selectedTypeIndex
                    height: 26
                    width: chipRow.implicitWidth + 18
                    radius: 13
                    color: active ? editorRoot.colorPrimary : editorRoot.colorSurface

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: modelData.icon
                            font.family: "Material Symbols Rounded"; font.pixelSize: 13
                            color: active ? editorRoot.colorOnPrimaryCont : editorRoot.colorOnSurfVar
                        }
                        Text {
                            text: modelData.label
                            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale); font.weight: Font.Medium
                            color: active ? editorRoot.colorOnPrimaryCont : editorRoot.colorOnSurfVar
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: editorRoot.selectedTypeIndex = index
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 34; radius: 17
                color: editorRoot.colorSurface

                Text {
                    visible: eventTitleInput.text === ""
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: editorRoot.inputPlaceholder
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                    color: editorRoot.colorTextSecondary
                    opacity: 0.7
                }

                TextInput {
                    id: eventTitleInput
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: globalState.fontSecondary; font.pixelSize: Math.round(12 * globalState.fontScale)
                    color: editorRoot.colorOnSurface
                    clip: true
                    onActiveFocusChanged: editorRoot.inputFocusChanged(activeFocus)
                    onAccepted: {
                        if (text.trim() === "") return;
                        editorRoot.addRequested(text, editorRoot.eventTypes[editorRoot.selectedTypeIndex].key);
                        text = "";
                    }
                }
            }

            Rectangle {
                width: 34; height: 34; radius: 17
                color: editorRoot.colorPrimary
                Text { anchors.centerIn: parent; text: "\ue145"; font.family: "Material Symbols Rounded"; font.pixelSize: 18; color: editorRoot.colorOnPrimaryCont }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (eventTitleInput.text.trim() === "") return;
                        editorRoot.addRequested(eventTitleInput.text, editorRoot.eventTypes[editorRoot.selectedTypeIndex].key);
                        eventTitleInput.text = "";
                    }
                }
            }
        }

        Text {
            visible: editorRoot.eventsForDay.length === 0
            Layout.fillWidth: true
            text: editorRoot.emptyListText
            font.family: globalState.fontSecondary; font.pixelSize: Math.round(11 * globalState.fontScale)
            color: editorRoot.colorTextSecondary
            opacity: 0.7
        }

        ListView {
            visible: editorRoot.eventsForDay.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: editorRoot.eventsForDay
            delegate: ReminderRow {
                editor: editorRoot; height: 34; iconSize: 14
                onRemoveClicked: editorRoot.removeRequested(index)
            }
        }
    }
}
