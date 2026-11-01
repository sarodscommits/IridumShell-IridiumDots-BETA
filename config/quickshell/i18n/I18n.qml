import QtQuick
import "settings.js" as SettingsStrings
import "desktop.js" as DesktopStrings
import "system.js" as SystemStrings
import "tables.js" as Tables
import "weather.js" as Weather

// Translation lookup for the current `language`, falling back to English
QtObject {
    property string language: "en"
    readonly property var dict: Object.assign({}, SettingsStrings.strings, DesktopStrings.strings, SystemStrings.strings)
    readonly property var languages: Tables.languages

    function has(key) { return dict[key] !== undefined }
    function tr(key) {
        var entry = dict[key];
        if (!entry) return key;
        return entry[language] || entry.en || key;
    }
    // wttr.in conditions come in English; translate for display only
    function weatherText(en) { return Weather.describe(en, language) }
    function localeCode() { return Tables.localeMap[language] || "en_US" }
    function weekdayInitials() { return Tables.weekdays[language] || Tables.weekdays.en }
    function motivationText(idx) {
        var arr = Tables.motivations[language] || Tables.motivations.en;
        return arr[idx] || Tables.motivations.en[idx] || "";
    }
}
