import QtQuick

// Shell-wide state; each base type in the chain holds one domain
PanelsState {
    property real desktopZoom: 1.0
    property bool desktopZoomBusy: false
    property bool deferredReady:     false
    property bool deferredLateReady: false
    readonly property int  icVisiblePage: islandControlOpen ? islandControlPage : -1
    readonly property int  ncVisiblePage: notchControlOpen  ? notchControlPage  : -1
    readonly property bool monitorStatsVisible: icVisiblePage === 1 || icVisiblePage === 3 || ncVisiblePage === 1 || (mediaMenuOpen && rightPanelPage === 0) || ((gamingOpen || gamingFloating) && !lockScreenActive)
    readonly property bool quickSlidersVisible: icVisiblePage === 0 || ncVisiblePage === 0 || (mediaMenuOpen && rightPanelPage === 0) || (gamingOpen && !lockScreenActive)
    readonly property bool fetchVisible: icVisiblePage === 1 || ncVisiblePage === 1 || calendarMenuOpen || settingsOpen

    readonly property bool cavaConsumerVisible: lockScreenActive || mediaMenuOpen || ncVisiblePage === 1 || icVisiblePage === 1
                                              || (barVertical && barModules.audio && mediaStatus === "Playing")

    readonly property bool waveConsumerVisible: lockScreenActive || mediaMenuOpen || notchMediaOpen || battBulgeOpen ||
        icVisiblePage === 0 || icVisiblePage === 1 || icVisiblePage === 3 ||
        ncVisiblePage === 0 || ncVisiblePage === 1
}
