.pragma library
// EasyEffects output preset (8-band equalizer) built from the slider values

var freqs = [60, 150, 400, 1000, 2400, 6000, 12000, 16000];

function _band(gain, freq) {
    return { "type": "Bell", "mode": "RLC (BT)", "slope": "x1", "solo": false, "mute": false,
        "gain": gain, "frequency": freq, "q": 1.5, "width": 4.0 };
}

function build(vals, toDb) {
    var bandsL = {}, bandsR = {};
    for (var i = 0; i < freqs.length; i++) {
        var gain = Math.round(toDb(vals[i]) * 10) / 10;
        bandsL["band" + i] = _band(gain, freqs[i]);
        bandsR["band" + i] = _band(gain, freqs[i]);
    }
    var eq = { "balance": 0.0, "bypass": false, "decramp": "Off", "input-gain": 0.0, "output-gain": 0.0,
        "mode": "IIR", "num-bands": freqs.length, "pitch-left": 0.0, "pitch-right": 0.0,
        "split-channels": false, "left": bandsL, "right": bandsR };
    return JSON.stringify({ "output": { "blocklist": [], "equalizer#0": eq, "plugins_order": ["equalizer#0"] } }, null, 2);
}
