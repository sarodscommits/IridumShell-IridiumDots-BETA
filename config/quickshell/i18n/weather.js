.pragma library
// wttr.in conditions translated for display only (icons match English keywords).
// Keys: lowercased English. Row order: es, zh, hi, pt (Brazilian), fr, de, ja, ru

var langs = ["es", "zh", "hi", "pt", "fr", "de", "ja", "ru"];

var rows = {
    "sunny":                        ["Soleado", "晴", "धूप", "Ensolarado", "Ensoleillé", "Sonnig", "晴れ", "Солнечно"],
    "clear":                        ["Despejado", "晴朗", "साफ़", "Céu limpo", "Dégagé", "Klar", "快晴", "Ясно"],
    "partly cloudy":                ["Parcialmente nublado", "局部多云", "आंशिक रूप से बादल", "Parcialmente nublado", "Partiellement nuageux", "Teilweise bewölkt", "晴れ時々曇り", "Переменная облачность"],
    "cloudy":                       ["Nublado", "多云", "बादल छाए", "Nublado", "Nuageux", "Bewölkt", "曇り", "Облачно"],
    "overcast":                     ["Cubierto", "阴", "घने बादल", "Encoberto", "Couvert", "Bedeckt", "本曇り", "Пасмурно"],
    "mist":                         ["Neblina", "薄雾", "धुंध", "Névoa", "Brume", "Dunst", "もや", "Дымка"],
    "haze":                         ["Calima", "霾", "कोहरा", "Bruma", "Brume sèche", "Diesig", "煙霧", "Мгла"],
    "smoke":                        ["Humo", "烟", "धुआँ", "Fumaça", "Fumée", "Rauch", "煙", "Дым"],
    "dust":                         ["Polvo", "浮尘", "धूल", "Poeira", "Poussière", "Staub", "砂じん", "Пыль"],
    "sand":                         ["Arena", "扬沙", "रेत", "Areia", "Sable", "Sand", "砂", "Песок"],
    "fog":                          ["Niebla", "雾", "कोहरा", "Neblina", "Brouillard", "Nebel", "霧", "Туман"],
    "freezing fog":                 ["Niebla helada", "冻雾", "जमा देने वाला कोहरा", "Neblina congelante", "Brouillard givrant", "Gefrierender Nebel", "着氷性の霧", "Переохлаждённый туман"],
    "patchy rain possible":         ["Posible lluvia dispersa", "可能有零星小雨", "छिटपुट बारिश संभव", "Possível chuva esparsa", "Pluie éparse possible", "Vereinzelt Regen möglich", "所により雨の可能性", "Возможен местами дождь"],
    "patchy rain nearby":           ["Lluvia dispersa cerca", "附近有零星小雨", "आसपास छिटपुट बारिश", "Chuva esparsa nas proximidades", "Pluie éparse à proximité", "Vereinzelt Regen in der Nähe", "近くで所により雨", "Местами дождь поблизости"],
    "patchy snow possible":         ["Posible nieve dispersa", "可能有零星小雪", "छिटपुट बर्फबारी संभव", "Possível neve esparsa", "Neige éparse possible", "Vereinzelt Schnee möglich", "所により雪の可能性", "Возможен местами снег"],
    "patchy snow nearby":           ["Nieve dispersa cerca", "附近有零星小雪", "आसपास छिटपुट बर्फबारी", "Neve esparsa nas proximidades", "Neige éparse à proximité", "Vereinzelt Schnee in der Nähe", "近くで所により雪", "Местами снег поблизости"],
    "patchy sleet possible":        ["Posible aguanieve dispersa", "可能有零星雨夹雪", "छिटपुट ओलावृष्टि संभव", "Possível granizo esparso", "Grésil épars possible", "Vereinzelt Schneeregen möglich", "所によりみぞれの可能性", "Возможен местами мокрый снег"],
    "patchy sleet nearby":          ["Aguanieve dispersa cerca", "附近有零星雨夹雪", "आसपास छिटपुट ओलावृष्टि", "Granizo esparso nas proximidades", "Grésil épars à proximité", "Vereinzelt Schneeregen in der Nähe", "近くで所によりみぞれ", "Местами мокрый снег поблизости"],
    "patchy freezing drizzle possible": ["Posible llovizna helada dispersa", "可能有零星冻毛毛雨", "छिटपुट जमा देने वाली बूंदाबांदी संभव", "Possível garoa congelante esparsa", "Bruine verglaçante éparse possible", "Vereinzelt gefrierender Nieselregen möglich", "所により着氷性の霧雨の可能性", "Возможна местами ледяная морось"],
    "patchy freezing drizzle nearby": ["Llovizna helada dispersa cerca", "附近有零星冻毛毛雨", "आसपास छिटपुट जमा देने वाली बूंदाबांदी", "Garoa congelante esparsa nas proximidades", "Bruine verglaçante éparse à proximité", "Vereinzelt gefrierender Nieselregen in der Nähe", "近くで所により着氷性の霧雨", "Местами ледяная морось поблизости"],
    "thundery outbreaks possible":  ["Posibles tormentas", "可能有雷暴", "गरज के साथ तूफ़ान संभव", "Possíveis trovoadas", "Orages possibles", "Gewitter möglich", "雷雨の可能性", "Возможны грозы"],
    "thundery outbreaks in nearby": ["Tormentas cerca", "附近有雷暴", "आसपास गरज के साथ तूफ़ान", "Trovoadas nas proximidades", "Orages à proximité", "Gewitter in der Nähe", "近くで雷雨", "Грозы поблизости"],
    "thundery outbreaks nearby":    ["Tormentas cerca", "附近有雷暴", "आसपास गरज के साथ तूफ़ान", "Trovoadas nas proximidades", "Orages à proximité", "Gewitter in der Nähe", "近くで雷雨", "Грозы поблизости"],
    "blowing snow":                 ["Ventisca", "风吹雪", "उड़ती बर्फ़", "Neve com vento", "Poudrerie", "Schneetreiben", "地吹雪", "Позёмок"],
    "blizzard":                     ["Tormenta de nieve", "暴风雪", "बर्फ़ीला तूफ़ान", "Nevasca", "Blizzard", "Schneesturm", "猛吹雪", "Метель"],
    "patchy light drizzle":         ["Llovizna ligera dispersa", "零星小毛毛雨", "छिटपुट हल्की बूंदाबांदी", "Garoa fraca esparsa", "Faible bruine éparse", "Vereinzelt leichter Nieselregen", "所により弱い霧雨", "Местами слабая морось"],
    "light drizzle":                ["Llovizna ligera", "小毛毛雨", "हल्की बूंदाबांदी", "Garoa fraca", "Faible bruine", "Leichter Nieselregen", "弱い霧雨", "Слабая морось"],
    "drizzle":                      ["Llovizna", "毛毛雨", "बूंदाबांदी", "Garoa", "Bruine", "Nieselregen", "霧雨", "Морось"],
    "freezing drizzle":             ["Llovizna helada", "冻毛毛雨", "जमा देने वाली बूंदाबांदी", "Garoa congelante", "Bruine verglaçante", "Gefrierender Nieselregen", "着氷性の霧雨", "Ледяная морось"],
    "heavy freezing drizzle":       ["Llovizna helada intensa", "强冻毛毛雨", "तेज़ जमा देने वाली बूंदाबांदी", "Garoa congelante forte", "Forte bruine verglaçante", "Starker gefrierender Nieselregen", "強い着氷性の霧雨", "Сильная ледяная морось"],
    "light drizzle and rain":       ["Llovizna y lluvia ligera", "小毛毛雨和小雨", "हल्की बूंदाबांदी और बारिश", "Garoa e chuva fraca", "Faible bruine et pluie", "Leichter Nieselregen und Regen", "弱い霧雨と雨", "Слабая морось и дождь"],
    "patchy light rain":            ["Lluvia ligera dispersa", "零星小雨", "छिटपुट हल्की बारिश", "Chuva fraca esparsa", "Faible pluie éparse", "Vereinzelt leichter Regen", "所により弱い雨", "Местами небольшой дождь"],
    "light rain":                   ["Lluvia ligera", "小雨", "हल्की बारिश", "Chuva fraca", "Pluie faible", "Leichter Regen", "小雨", "Небольшой дождь"],
    "rain":                         ["Lluvia", "雨", "बारिश", "Chuva", "Pluie", "Regen", "雨", "Дождь"],
    "moderate rain at times":       ["Lluvia moderada a ratos", "时有中雨", "कभी-कभी मध्यम बारिश", "Chuva moderada às vezes", "Pluie modérée par moments", "Zeitweise mäßiger Regen", "時々並の雨", "Временами умеренный дождь"],
    "moderate rain":                ["Lluvia moderada", "中雨", "मध्यम बारिश", "Chuva moderada", "Pluie modérée", "Mäßiger Regen", "並の雨", "Умеренный дождь"],
    "heavy rain at times":          ["Lluvia intensa a ratos", "时有大雨", "कभी-कभी भारी बारिश", "Chuva forte às vezes", "Forte pluie par moments", "Zeitweise starker Regen", "時々強い雨", "Временами сильный дождь"],
    "heavy rain":                   ["Lluvia intensa", "大雨", "भारी बारिश", "Chuva forte", "Forte pluie", "Starker Regen", "強い雨", "Сильный дождь"],
    "light freezing rain":          ["Lluvia helada ligera", "小冻雨", "हल्की जमा देने वाली बारिश", "Chuva congelante fraca", "Faible pluie verglaçante", "Leichter gefrierender Regen", "弱い着氷性の雨", "Слабый ледяной дождь"],
    "moderate or heavy freezing rain": ["Lluvia helada moderada o intensa", "中到大冻雨", "मध्यम या भारी जमा देने वाली बारिश", "Chuva congelante moderada ou forte", "Pluie verglaçante modérée ou forte", "Mäßiger bis starker gefrierender Regen", "並から強い着氷性の雨", "Умеренный или сильный ледяной дождь"],
    "light sleet":                  ["Aguanieve ligera", "小雨夹雪", "हल्की ओलावृष्टि", "Granizo fraco", "Faible grésil", "Leichter Schneeregen", "弱いみぞれ", "Слабый мокрый снег"],
    "moderate or heavy sleet":      ["Aguanieve moderada o intensa", "中到大雨夹雪", "मध्यम या भारी ओलावृष्टि", "Granizo moderado ou forte", "Grésil modéré ou fort", "Mäßiger bis starker Schneeregen", "並から強いみぞれ", "Умеренный или сильный мокрый снег"],
    "patchy light snow":            ["Nieve ligera dispersa", "零星小雪", "छिटपुट हल्की बर्फबारी", "Neve fraca esparsa", "Faible neige éparse", "Vereinzelt leichter Schneefall", "所により弱い雪", "Местами небольшой снег"],
    "light snow":                   ["Nieve ligera", "小雪", "हल्की बर्फबारी", "Neve fraca", "Neige faible", "Leichter Schneefall", "小雪", "Небольшой снег"],
    "snow":                         ["Nieve", "雪", "बर्फबारी", "Neve", "Neige", "Schnee", "雪", "Снег"],
    "patchy moderate snow":         ["Nieve moderada dispersa", "零星中雪", "छिटपुट मध्यम बर्फबारी", "Neve moderada esparsa", "Neige modérée éparse", "Vereinzelt mäßiger Schneefall", "所により並の雪", "Местами умеренный снег"],
    "moderate snow":                ["Nieve moderada", "中雪", "मध्यम बर्फबारी", "Neve moderada", "Neige modérée", "Mäßiger Schneefall", "並の雪", "Умеренный снег"],
    "patchy heavy snow":            ["Nieve intensa dispersa", "零星大雪", "छिटपुट भारी बर्फबारी", "Neve forte esparsa", "Forte neige éparse", "Vereinzelt starker Schneefall", "所により強い雪", "Местами сильный снег"],
    "heavy snow":                   ["Nieve intensa", "大雪", "भारी बर्फबारी", "Neve forte", "Forte neige", "Starker Schneefall", "大雪", "Сильный снег"],
    "ice pellets":                  ["Granizo fino", "冰粒", "बर्फ़ के कण", "Granizo miúdo", "Granules de glace", "Eiskörner", "凍雨", "Ледяная крупа"],
    "light rain shower":            ["Chubasco ligero", "小阵雨", "हल्की बौछार", "Pancada de chuva fraca", "Faible averse", "Leichter Regenschauer", "弱いにわか雨", "Небольшой ливень"],
    "rain shower":                  ["Chubasco", "阵雨", "बौछार", "Pancada de chuva", "Averse", "Regenschauer", "にわか雨", "Ливень"],
    "shower in vicinity":           ["Chubascos cerca", "附近有阵雨", "आसपास बौछारें", "Pancadas nas proximidades", "Averses à proximité", "Schauer in der Nähe", "付近でにわか雨", "Ливни поблизости"],
    "moderate or heavy rain shower": ["Chubasco moderado o intenso", "中到大阵雨", "मध्यम या भारी बौछार", "Pancada de chuva moderada ou forte", "Averse modérée ou forte", "Mäßiger bis starker Regenschauer", "並から強いにわか雨", "Умеренный или сильный ливень"],
    "torrential rain shower":       ["Chubasco torrencial", "暴雨", "मूसलाधार बारिश", "Pancada de chuva torrencial", "Averse torrentielle", "Sintflutartiger Regenschauer", "豪雨", "Проливной ливень"],
    "light sleet showers":          ["Chubascos ligeros de aguanieve", "小阵雨夹雪", "हल्की ओलावृष्टि की बौछारें", "Pancadas fracas de granizo", "Faibles averses de grésil", "Leichte Schneeregenschauer", "弱いみぞれのにわか雨", "Небольшой ливневый мокрый снег"],
    "moderate or heavy sleet showers": ["Chubascos de aguanieve moderados o intensos", "中到大阵雨夹雪", "मध्यम या भारी ओलावृष्टि की बौछारें", "Pancadas de granizo moderadas ou fortes", "Averses de grésil modérées ou fortes", "Mäßige bis starke Schneeregenschauer", "並から強いみぞれのにわか雨", "Умеренный или сильный ливневый мокрый снег"],
    "light snow showers":           ["Chubascos ligeros de nieve", "小阵雪", "हल्की बर्फ़ की बौछारें", "Pancadas fracas de neve", "Faibles averses de neige", "Leichte Schneeschauer", "弱いにわか雪", "Небольшой ливневый снег"],
    "moderate or heavy snow showers": ["Chubascos de nieve moderados o intensos", "中到大阵雪", "मध्यम या भारी बर्फ़ की बौछारें", "Pancadas de neve moderadas ou fortes", "Averses de neige modérées ou fortes", "Mäßige bis starke Schneeschauer", "並から強いにわか雪", "Умеренный или сильный ливневый снег"],
    "light showers of ice pellets": ["Chubascos ligeros de granizo fino", "小阵冰粒", "हल्की बर्फ़ के कणों की बौछारें", "Pancadas fracas de granizo miúdo", "Faibles averses de granules de glace", "Leichte Eiskörnerschauer", "弱い凍雨のにわか雨", "Небольшая ледяная крупа"],
    "moderate or heavy showers of ice pellets": ["Chubascos de granizo fino moderados o intensos", "中到大阵冰粒", "मध्यम या भारी बर्फ़ के कणों की बौछारें", "Pancadas de granizo miúdo moderadas ou fortes", "Averses de granules de glace modérées ou fortes", "Mäßige bis starke Eiskörnerschauer", "並から強い凍雨のにわか雨", "Умеренная или сильная ледяная крупа"],
    "patchy light rain with thunder": ["Lluvia ligera dispersa con tormenta", "零星小雷阵雨", "गरज के साथ छिटपुट हल्की बारिश", "Chuva fraca esparsa com trovoada", "Faible pluie éparse avec orage", "Vereinzelt leichter Regen mit Gewitter", "所により雷を伴う弱い雨", "Местами небольшой дождь с грозой"],
    "patchy light rain in area with thunder": ["Lluvia ligera dispersa con tormenta", "零星小雷阵雨", "गरज के साथ छिटपुट हल्की बारिश", "Chuva fraca esparsa com trovoada", "Faible pluie éparse avec orage", "Vereinzelt leichter Regen mit Gewitter", "所により雷を伴う弱い雨", "Местами небольшой дождь с грозой"],
    "moderate or heavy rain with thunder": ["Lluvia moderada o intensa con tormenta", "中到大雷阵雨", "गरज के साथ मध्यम या भारी बारिश", "Chuva moderada ou forte com trovoada", "Pluie modérée ou forte avec orage", "Mäßiger bis starker Regen mit Gewitter", "雷を伴う並から強い雨", "Умеренный или сильный дождь с грозой"],
    "moderate or heavy rain in area with thunder": ["Lluvia moderada o intensa con tormenta", "中到大雷阵雨", "गरज के साथ मध्यम या भारी बारिश", "Chuva moderada ou forte com trovoada", "Pluie modérée ou forte avec orage", "Mäßiger bis starker Regen mit Gewitter", "雷を伴う並から強い雨", "Умеренный или сильный дождь с грозой"],
    "patchy light snow with thunder": ["Nieve ligera dispersa con tormenta", "零星小雷阵雪", "गरज के साथ छिटपुट हल्की बर्फबारी", "Neve fraca esparsa com trovoada", "Faible neige éparse avec orage", "Vereinzelt leichter Schneefall mit Gewitter", "所により雷を伴う弱い雪", "Местами небольшой снег с грозой"],
    "patchy light snow in area with thunder": ["Nieve ligera dispersa con tormenta", "零星小雷阵雪", "गरज के साथ छिटपुट हल्की बर्फबारी", "Neve fraca esparsa com trovoada", "Faible neige éparse avec orage", "Vereinzelt leichter Schneefall mit Gewitter", "所により雷を伴う弱い雪", "Местами небольшой снег с грозой"],
    "moderate or heavy snow with thunder": ["Nieve moderada o intensa con tormenta", "中到大雷阵雪", "गरज के साथ मध्यम या भारी बर्फबारी", "Neve moderada ou forte com trovoada", "Neige modérée ou forte avec orage", "Mäßiger bis starker Schneefall mit Gewitter", "雷を伴う並から強い雪", "Умеренный или сильный снег с грозой"],
    "moderate or heavy snow in area with thunder": ["Nieve moderada o intensa con tormenta", "中到大雷阵雪", "गरज के साथ मध्यम या भारी बर्फबारी", "Neve moderada ou forte com trovoada", "Neige modérée ou forte avec orage", "Mäßiger bis starker Schneefall mit Gewitter", "雷を伴う並から強い雪", "Умеренный или сильный снег с грозой"],
    "thunderstorm":                 ["Tormenta", "雷暴", "आंधी-तूफ़ान", "Trovoada", "Orage", "Gewitter", "雷雨", "Гроза"],
    "thunderstorm in vicinity":     ["Tormenta cerca", "附近有雷暴", "आसपास आंधी-तूफ़ान", "Trovoada nas proximidades", "Orage à proximité", "Gewitter in der Nähe", "付近で雷雨", "Гроза поблизости"],
    "light rain with thunderstorm": ["Lluvia ligera con tormenta", "小雨伴雷暴", "आंधी के साथ हल्की बारिश", "Chuva fraca com trovoada", "Pluie faible avec orage", "Leichter Regen mit Gewitter", "雷を伴う小雨", "Небольшой дождь с грозой"],
    "heavy rain with thunderstorm": ["Lluvia intensa con tormenta", "大雨伴雷暴", "आंधी के साथ भारी बारिश", "Chuva forte com trovoada", "Forte pluie avec orage", "Starker Regen mit Gewitter", "雷を伴う強い雨", "Сильный дождь с грозой"]
};

function _one(part, lang) {
    var k = part.toLowerCase().replace(/\s+/g, " ").trim();
    var row = rows[k];
    if (!row) return part.trim();
    var i = langs.indexOf(lang);
    return i >= 0 ? row[i] : part.trim();
}

// wttr.in sometimes combines conditions: "Light rain, mist"
function describe(en, lang) {
    if (!en) return "";
    if (!lang || lang === "en") return en.trim();
    var parts = en.split(",");
    var out = [];
    for (var i = 0; i < parts.length; i++) {
        if (parts[i].trim() === "") continue;
        var t = _one(parts[i], lang);
        // later parts lowercase where nouns aren't capitalized (not German)
        if (out.length > 0 && ["es", "pt", "fr", "ru"].indexOf(lang) >= 0) t = t.charAt(0).toLowerCase() + t.slice(1);
        out.push(t);
    }
    return out.join(lang === "zh" ? "，" : lang === "ja" ? "、" : ", ");
}
