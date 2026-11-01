import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import ".."
import "../ui"

// Keyboard layout search results
Item {
    id: keyboardLayoutList
    Layout.fillWidth: true
    implicitHeight: 312
    ELoading {
        anchors.centerIn: parent
        visible: kbLayoutsLoading && !kbLayoutsLoaded
        running: visible
    }
    EText {
        anchors.centerIn: parent
        visible: kbLayoutsLoaded && kbPage.filteredLayouts.length === 0
        role: "bodyLarge"; color: m3.inkSurfaceVariant
        text: tr("kb_no_results")
    }
    ListView {
        id: kbLayoutList
        anchors.fill: parent
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: kbPage.filteredLayouts
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        delegate: Rectangle {
            id: kbLayRow
            required property var modelData
            required property int index
            width: kbLayoutList.width - 10
            height: 60
            readonly property bool isCur: modelData.n === kbCurLayout
            readonly property bool sel: modelData.n === kbPage.shownLayout
            readonly property bool first: index === 0
            readonly property bool last: index === kbLayoutList.count - 1
            Spring { id: kbLayS; target: kbLayRow.sel ? 1 : 0; token: "spatialFast"; eps: 0.002 }
            Spring { id: kbLayH; target: kbLayMa.containsMouse ? 1 : 0; token: "effectsFast" }
            readonly property real outerR: m3.corner(20)
            readonly property real r: 4 + (outerR - 4) * Math.max(0, Math.min(1, kbLayS.value))
            topLeftRadius: first ? outerR : r; topRightRadius: first ? outerR : r
            bottomLeftRadius: last ? outerR : r; bottomRightRadius: last ? outerR : r
            color: m3.state(sel ? m3.secondaryContainer : m3.glassy(m3.surfaceContainerHigh, 0.6), m3.inkSurface, 0.06 * kbLayH.value)
            Behavior on color { ColorAnimation { duration: 160 } }
            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 14
                spacing: 12
                Rectangle {
                    Layout.preferredWidth: 48; Layout.preferredHeight: 36
                    radius: kbLayRow.sel ? 12 : 18
                    Behavior on radius { M3SpringAnim { token: "spatialFast" } }
                    color: kbLayRow.sel ? m3.primary : m3.surfaceContainerHighest
                    EText {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        horizontalAlignment: Text.AlignHCenter
                        fontSizeMode: Text.HorizontalFit; minimumPixelSize: 9
                        role: "labelLarge"; emph: true
                        text: kbLayRow.modelData.n.toUpperCase()
                        color: kbLayRow.sel ? m3.inkPrimary : m3.inkSurfaceVariant
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 0
                    EText {
                        Layout.fillWidth: true
                        role: "titleSmall"; elide: Text.ElideRight
                        text: kbLayRow.modelData.d
                        color: kbLayRow.sel ? m3.inkSecondaryContainer : m3.inkSurface
                    }
                    EText {
                        Layout.fillWidth: true
                        role: "bodySmall"; elide: Text.ElideRight
                        color: m3.inkSurfaceVariant
                        text: (kbLayRow.modelData.v.length ? tr("kb_n_variants").arg(kbLayRow.modelData.v.length) : tr("kb_no_variants"))
                              + (kbLayRow.modelData.l.length ? "  ·  " + kbLayRow.modelData.l.join(", ") : "")
                    }
                }
                Rectangle {
                    visible: kbLayRow.isCur
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: kbCurTag.implicitWidth + 20
                    radius: 12
                    color: m3.primary
                    EText { id: kbCurTag; anchors.centerIn: parent; role: "labelMedium"; emph: true; text: tr("kb_in_use"); color: m3.inkPrimary }
                }
                EIcon {
                    visible: kbLayRow.sel && !kbLayRow.isCur
                    name: "check"; filled: true
                    color: m3.inkSecondaryContainer
                }
            }
            MouseArea {
                id: kbLayMa
                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var n = kbLayRow.modelData.n;
                    if (n === kbCurLayout) { kbPage.resetSelection(); }
                    else { kbPage.selLayout = n; kbPage.selVariant = ""; }
                    globalState.playUiClick();
                }
            }
        }
    }
}
