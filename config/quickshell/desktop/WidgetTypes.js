.pragma library
// Desktop widget registry: state-property and widget-root names per widget type

var stems = {
    music: "music", weather: "weather", clock: "clock|Desktop", calendar: "cal|Desktop",
    clockDetail: "clockDetail", weatherDetail: "weatherDetail", calDetail: "calDetail",
    cpu: "cpu", ram: "ram", disk: "disk", sys: "sys", gpu: "gpu", charge: "charge",
    date: "date", bigtime: "bigTime", mediapill: "mediaPill", countdown: "countdown",
    wpills: "weatherPills", lyrcard: "lyricsCard", lyrline: "lyricsLine", lyrbubble: "lyricsBubble"
};
var types = Object.keys(stems);
var gridOrder = ["music", "clock", "calendar", "weather", "clockDetail", "weatherDetail", "calDetail",
    "cpu", "ram", "disk", "sys", "gpu", "charge", "date", "bigtime", "mediapill", "countdown",
    "wpills", "lyrcard", "lyrline", "lyrbubble"];
var pickerOrder = ["music", "mediapill", "weather", "weatherDetail", "wpills", "clock", "clockDetail",
    "bigtime", "calendar", "calDetail", "date", "countdown", "lyrcard", "lyrline", "lyrbubble",
    "cpu", "ram", "disk", "gpu", "sys", "charge"];
var resizable = ["music", "clockDetail", "weatherDetail", "calDetail"];

function name(type, mid) {
    var s = stems[type];
    if (!s) return "";
    var p = s.split("|");
    return p[0] + mid + (p[1] || "");
}
function prop(type, field) {
    var sized = resizable.indexOf(type) >= 0;
    if (field === "Scale" ? sized : (field === "W" || field === "H") && !sized) return "";
    return name(type, "Widget" + field);
}
function rootName(type) { return name(type, "WidgetRoot"); }
