.pragma library
// Per-language locale codes, weekday initials, greetings and language list

var localeMap = { en:"en_US", es:"es_ES", zh:"zh_CN", hi:"hi_IN", pt:"pt_PT", fr:"fr_FR", de:"de_DE", ja:"ja_JP", ru:"ru_RU" };

var weekdays = {
    en: ["S","M","T","W","T","F","S"],
    es: ["D","L","M","M","J","V","S"],
    zh: ["日","一","二","三","四","五","六"],
    hi: ["र","सो","मं","बु","गु","शु","श"],
    pt: ["D","S","T","Q","Q","S","S"],
    fr: ["D","L","M","M","J","V","S"],
    de: ["S","M","D","M","D","F","S"],
    ja: ["日","月","火","水","木","金","土"],
    ru: ["В","П","В","С","Ч","П","С"],
};

var motivations = {
    en: ["Let's get to work","Time to make things happen","Let's crush this project","Let's set the bar high","Focus, focus, focus","Let's execute with excellence","Game face on, team","Let's lead the way","Results start here","Let's win this together"],
    es: ["Manos a la obra","Hora de hacer que las cosas pasen","A darle con todo a este proyecto","Pongamos la barra alta","Concentración, concentración, concentración","Ejecutemos con excelencia","Cara de juego, equipo","Lideremos el camino","Los resultados empiezan aquí","Ganemos esto juntos"],
    zh: ["开始工作吧","是时候让事情发生了","全力以赴完成这个项目","把标准定高一点","专注，专注，专注","以卓越的方式执行","拿出比赛状态，团队","让我们带头前进","成果从这里开始","让我们一起赢下这一局"],
    hi: ["चलो काम पर लग जाते हैं","अब चीज़ों को अंजाम देने का समय है","इस प्रोजेक्ट में जान डाल दें","मानक ऊँचा रखें","ध्यान, ध्यान, ध्यान","उत्कृष्टता के साथ काम करें","टीम, अब पूरी तैयारी के साथ","आइए नेतृत्व करें","नतीजे यहीं से शुरू होते हैं","आइए मिलकर यह जीतें"],
    pt: ["Vamos ao trabalho","Hora de fazer as coisas acontecerem","Vamos arrasar neste projeto","Vamos elevar o nível","Foco, foco, foco","Vamos executar com excelência","Cara de jogo, equipe","Vamos liderar o caminho","Os resultados começam aqui","Vamos vencer isso juntos"],
    fr: ["Au travail","Il est temps de faire bouger les choses","Donnons tout sur ce projet","Visons haut","Concentration, concentration, concentration","Exécutons avec excellence","Esprit de compétition, équipe","Montrons la voie","Les résultats commencent ici","Gagnons ça ensemble"],
    de: ["Los geht's","Zeit, Dinge in Bewegung zu bringen","Geben wir bei diesem Projekt alles","Setzen wir die Bar hoch","Konzentration, Konzentration, Konzentration","Lasst uns mit Exzellenz umsetzen","Wettkampfmodus, Team","Gehen wir voran","Ergebnisse fangen hier an","Lasst uns das zusammen gewinnen"],
    ja: ["さあ、仕事を始めよう","物事を動かす時間だ","このプロジェクトに全力を尽くそう","基準を高く設定しよう","集中、集中、集中","卓越した実行を","気合を入れよう、チーム","先頭に立とう","結果はここから始まる","一緒にこれを勝ち取ろう"],
    ru: ["Пора приступать к работе","Время воплощать идеи в жизнь","Покажем максимум на этом проекте","Поднимем планку выше","Концентрация, концентрация, концентрация","Сделаем всё на высшем уровне","Боевой настрой, команда","Покажем пример остальным","Результаты начинаются здесь","Победим в этом вместе"],
};

var languages = [
    { code: "en", name: "English" },
    { code: "es", name: "Español" },
    { code: "zh", name: "中文" },
    { code: "hi", name: "हिन्दी" },
    { code: "pt", name: "Português" },
    { code: "fr", name: "Français" },
    { code: "de", name: "Deutsch" },
    { code: "ja", name: "日本語" },
    { code: "ru", name: "Русский" },
];
