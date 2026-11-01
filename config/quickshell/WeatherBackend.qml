import QtQuick
import Quickshell.Io

// Weather backend (wttr.in): 10 min refresh, today + 2-day forecast
Item {
    id: weatherBackend

    signal weatherUpdated(var fields)

    function reload() { weatherProcess.running = true }

    Process {
        id: weatherProcess
        command: ["bash", "-c",
          "for attempt in 1 2 3; do\n" +
          "  RAW=$(curl --max-time 15 --retry 2 --retry-delay 3 -sf 'https://wttr.in/?format=j1' 2>/dev/null)\n" +
          "  [ -n \"$RAW\" ] && echo \"$RAW\" | python3 -c \"\nimport sys,json,sys\ntry:\n d=json.load(sys.stdin)\n c=d['current_condition'][0]\n w=d['weather'][0]\n a=d['nearest_area'][0]\n print('CITY:'+a['areaName'][0]['value']+', '+a['country'][0]['value'])\n print('TEMP:'+c['temp_C'])\n print('FEEL:'+c['FeelsLikeC'])\n print('DESC:'+c['weatherDesc'][0]['value'])\n print('HUMIDITY:'+c['humidity'])\n print('WIND:'+c['windspeedKmph'])\n print('MAX:'+w['maxtempC'])\n print('MIN:'+w['mintempC'])\n for i,day in enumerate(d.get('weather',[])[:3]):\n  hr=day.get('hourly') or []\n  mid=hr[len(hr)//2] if hr else {}\n  desc=(mid.get('weatherDesc') or [{'value':''}])[0]['value']\n  print('FDATE'+str(i)+':'+day.get('date',''))\n  print('FMAX'+str(i)+':'+day.get('maxtempC',''))\n  print('FMIN'+str(i)+':'+day.get('mintempC',''))\n  print('FDESC'+str(i)+':'+desc.strip())\nexcept: pass\n\" 2>/dev/null && exit 0\n" +
          "  sleep 10\n" +
          "done"
        ]
        running: true
        property var _fields: ({})
        stdout: SplitParser {
          onRead: (line) => {
            var idx = line.indexOf(":");
            if (idx < 0) return;
            var key = line.substring(0, idx);
            var val = line.substring(idx + 1).trim();
            weatherProcess._fields[key] = val;
          }
        }
        onRunningChanged: {
          if (!running) {
            if (Object.keys(weatherProcess._fields).length > 0) {
              weatherBackend.weatherUpdated(weatherProcess._fields);
              weatherProcess._fields = {};
            } else {
              weatherRetryTimer.restart();
            }
          }
        }
    }
    Timer {
        id: weatherRetryTimer
        interval: 30000; repeat: false
        onTriggered: { weatherProcess.running = true; }
    }
    Timer {
        interval: 600000; running: true; repeat: true
        onTriggered: weatherProcess.running = true
    }
}
