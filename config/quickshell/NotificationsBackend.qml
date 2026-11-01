import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Notification server (freedesktop D-Bus); emits notificationReceived for toasts
NotificationServer {
    id: notificationsBackend

    keepOnReload:   true
    bodySupported:  true
    bodyMarkupSupported: true
    imageSupported: true
    actionsSupported: true
    actionIconsSupported: false
    persistenceSupported: true

    property bool dndEnabled: false
    // "" = system default sound
    property string soundPath: ""
    // 0-100, passed to mpv --volume
    property real volume: 100

    signal notificationReceived(var notification)

    onNotification: (notification) => {
        notification.tracked = true;
        if (dndEnabled) return;
        var file = soundPath !== "" ? soundPath : "/usr/share/sounds/freedesktop/stereo/message-new-instant.oga";
        Quickshell.execDetached(["mpv", "--no-video", "--really-quiet", "--volume=" + Math.round(volume), file]);
        notificationsBackend.notificationReceived(notification);
    }
}
