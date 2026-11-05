// Inhalte: Startpaket (Kurmancî) und Grammatik – identisch mit der iOS-App.
(function () {
  const noun = (ku, de, gender, exKu = '', exDe = '') => ({ ku, de, type: 'noun', gender, exKu, exDe });
  const phrase = (ku, de, note = '') => ({ ku, de, type: 'phrase', note });
  const other = (ku, de) => ({ ku, de, type: 'other' });
  const adj = (ku, de) => ({ ku, de, type: 'adj' });
  const verb = (ku, de, trans, stem, present, past, imperative, future) =>
    ({ ku, de, type: 'verb', trans, forms: { stem, present, past, imperative, future } });

  window.STARTER_PACK = {
    name: 'Kurmancî Grundlagen', emoji: '☀️', color: 'teal', cards: [],
    children: [
      { name: 'Begrüßung & Höflichkeit', emoji: '👋', color: 'amber', cards: [
        phrase('Silav', 'Hallo'),
        phrase('Rojbaş', 'Guten Morgen / Guten Tag'),
        phrase('Êvarbaş', 'Guten Abend'),
        phrase('Şevbaş', 'Gute Nacht'),
        phrase('Tu çawa yî?', 'Wie geht es dir?'),
        phrase('Ez baş im', 'Mir geht es gut'),
        phrase('Spas', 'Danke'),
        phrase('Ji kerema xwe', 'Bitte (Aufforderung)'),
        phrase('Bi xêr hatî', 'Willkommen', 'Antwort: Bi xêr bimînî'),
        phrase('Xatirê te', 'Auf Wiedersehen', 'Sagt derjenige, der geht.'),
        other('Erê', 'Ja'),
        other('Na', 'Nein'),
        phrase('Navê te çi ye?', 'Wie heißt du?'),
        phrase('Navê min … ye', 'Ich heiße …')
      ] },
      { name: 'Zahlen', emoji: '🔢', color: 'blue', cards: [
        ['yek', 'eins'], ['du', 'zwei'], ['sê', 'drei'], ['çar', 'vier'], ['pênc', 'fünf'],
        ['şeş', 'sechs'], ['heft', 'sieben'], ['heşt', 'acht'], ['neh', 'neun'], ['deh', 'zehn']
      ].map(([k, d]) => other(k, d)) },
      { name: 'Familie', emoji: '👨‍👩‍👧', color: 'pink', cards: [
        noun('dayik', 'Mutter', 'f'),
        noun('bav', 'Vater', 'm'),
        noun('bira', 'Bruder', 'm'),
        noun('xwişk', 'Schwester', 'f'),
        noun('kur', 'Sohn / Junge', 'm'),
        noun('keç', 'Tochter / Mädchen', 'f'),
        noun('malbat', 'Familie', 'f'),
        noun('bapîr', 'Großvater', 'm'),
        noun('dapîr', 'Großmutter', 'f')
      ] },
      { name: 'Alltag', emoji: '🏠', color: 'green', cards: [
        noun('av', 'Wasser', 'f'),
        noun('nan', 'Brot', 'm', 'Min nan xwar.', 'Ich habe Brot gegessen.'),
        noun('mal', 'Haus / Zuhause', 'f', 'Ez diçim malê.', 'Ich gehe nach Hause.'),
        noun('pirtûk', 'Buch', 'f'),
        noun('çay', 'Tee', 'f'),
        noun('sêv', 'Apfel', 'f'),
        noun('roj', 'Tag / Sonne', 'f'),
        noun('şev', 'Nacht', 'f'),
        noun('dil', 'Herz', 'm'),
        adj('mezin', 'groß'), adj('biçûk', 'klein'), adj('baş', 'gut'), adj('xweş', 'schön / angenehm'),
        adj('nû', 'neu'), adj('germ', 'warm'), adj('sar', 'kalt')
      ] },
      { name: 'Wichtige Verben', emoji: '⚡️', color: 'violet', cards: [
        verb('çûn', 'gehen', 'intransitive', '-ç-', 'ez diçim', 'ez çûm', 'here!', 'ez ê biçim'),
        verb('hatin', 'kommen', 'intransitive', '-ê-', 'ez têm', 'ez hatim', 'were!', 'ez ê bêm'),
        verb('xwarin', 'essen', 'transitive', '-xw-', 'ez dixwim', 'min xwar', 'bixwe!', 'ez ê bixwim'),
        verb('vexwarin', 'trinken', 'transitive', '-vexw-', 'ez vedixwim', 'min vexwar', 'vexwe!', 'ez ê vexwim'),
        verb('kirin', 'machen / tun', 'transitive', '-k-', 'ez dikim', 'min kir', 'bike!', 'ez ê bikim'),
        verb('dîtin', 'sehen / finden', 'transitive', '-bîn-', 'ez dibînim', 'min dît', 'bibîne!', 'ez ê bibînim'),
        verb('gotin', 'sagen', 'transitive', '-bêj-', 'ez dibêjim', 'min got', 'bibêje!', 'ez ê bibêjim'),
        verb('xwendin', 'lesen / lernen', 'transitive', '-xwîn-', 'ez dixwînim', 'min xwend', 'bixwîne!', 'ez ê bixwînim'),
        verb('dan', 'geben', 'transitive', '-d-', 'ez didim', 'min da', 'bide!', 'ez ê bidim'),
        verb('zanîn', 'wissen / können', 'transitive', '-zan-', 'ez dizanim', 'min zanî', 'bizane!', 'ez ê bizanim'),
        verb('rûniştin', 'sich setzen / sitzen', 'intransitive', '-rûn-', 'ez rûdinim', 'ez rûniştim', 'rûne!', 'ez ê rûnim')
      ] }
    ]
  };

  // Blöcke: ['t', text] | ['tab', rows] | ['ul', items]. Text: **fett**, *kursiv*.
  window.GRAMMAR = [
    { title: 'Aussprache & Alphabet', emoji: '🗣️', blocks: [
      ['t', 'Kurmancî wird mit lateinischen Buchstaben geschrieben – fast alles wird so gesprochen, wie es geschrieben wird.'],
      ['tab', [
        ['**c**', 'wie „dsch“ in *Dschungel*'], ['**ç**', 'wie „tsch“ in *Tschüss*'], ['**ş**', 'wie „sch“ in *Schule*'],
        ['**j**', 'weiches „j“ wie in *Journal*'], ['**x**', 'wie „ch“ in *Bach*'], ['**q**', 'tiefes, hinten gesprochenes k'],
        ['**y**', 'wie „j“ in *ja*'], ['**v / w**', 'v = deutsches „w“, w = englisches „w“'], ['**z**', 'stimmhaftes s wie in *Sonne*'],
        ['**ê**', 'langes e wie in *See*'], ['**î / û**', 'langes i bzw. langes u'], ['**e**', 'kurzes e/ä wie in *Bett*'],
        ['**i**', 'sehr kurzes, fast verschlucktes i']
      ]]
    ] },
    { title: 'Personalpronomen', emoji: '🙋', blocks: [
      ['t', 'Es gibt zwei Reihen: **Rektus** (Grundform) und **Obliquus** (für Besitz, nach Präpositionen und als Subjekt transitiver Verben in der Vergangenheit).'],
      ['tab', [
        ['', '**Rektus**', '**Obliquus**'], ['ich', 'ez', 'min'], ['du', 'tu', 'te'], ['er / sie', 'ew', 'wî (m) / wê (f)'],
        ['wir', 'em', 'me'], ['ihr / Sie', 'hûn', 'we'], ['sie (Pl.)', 'ew', 'wan']
      ]]
    ] },
    { title: 'Sein (Kopula)', emoji: '🟰', blocks: [
      ['t', '„Sein“ wird als Endung angehängt. Nach einem Vokal steht die zweite Form.'],
      ['tab', [
        ['ez … **im** / **me**', 'Ez baş im. – Mir geht\'s gut.'], ['tu … **î** / **yî**', 'Tu çawa yî? – Wie geht\'s dir?'],
        ['ew … **e** / **ye**', 'Ew mezin e. – Er/Sie ist groß.'], ['em/hûn/ew … **in** / **ne**', 'Em baş in. – Uns geht\'s gut.']
      ]]
    ] },
    { title: 'Verben: die wichtigsten Formen', emoji: '⚡️', blocks: [
      ['t', 'Jedes Verb hat zwei Stämme, die du lernen musst – genau dafür gibt es den **Verb-Trainer**:'],
      ['ul', [
        '**Infinitiv** (Grundform) endet auf *-in*, *-n* oder *-în*, z. B. *xwarin*',
        '**Vergangenheitsstamm** = Infinitiv ohne *-in/-n*: *xwar*',
        '**Präsensstamm** – oft unregelmäßig: *-xw-*'
      ]],
      ['t', '**Präsens** = *di-* + Präsensstamm + Personalendung:'],
      ['tab', [['ez di…**im**', 'ez dixwim'], ['tu di…**î**', 'tu dixwî'], ['ew di…**e**', 'ew dixwe'], ['em/hûn/ew di…**in**', 'em dixwin']]],
      ['t', 'Bei Verben mit Vorsilbe steht *di-* dazwischen: *vexwarin → ez ve**di**xwim*.']
    ] },
    { title: 'Imperativ (Befehlsform)', emoji: '❗', blocks: [
      ['t', '**bi-** + Präsensstamm + **-e** (Singular) / **-in** (Plural)'],
      ['tab', [['xwarin', 'bixwe! / bixwin!'], ['kirin', 'bike! / bikin!'], ['gotin', 'bibêje! / bibêjin!']]],
      ['t', 'Unregelmäßig: *çûn → here!*, *hatin → were!*. Verben mit Vorsilbe bekommen kein *bi-*: *vexwe!*, *rûne!*']
    ] },
    { title: 'Vergangenheit & Ergativ', emoji: '⏪', blocks: [
      ['t', 'Die große Besonderheit im Kurdischen: In der Vergangenheit kommt es darauf an, ob ein Verb **transitiv** (hat ein Objekt) oder **intransitiv** ist.'],
      ['t', '**Intransitiv** (gehen, kommen, sitzen …): Subjekt im Rektus, das Verb richtet sich nach dem Subjekt.'],
      ['tab', [['ez çûm', 'ich ging'], ['tu çûyî', 'du gingst'], ['ew çû', 'er/sie ging'], ['em çûn', 'wir gingen']]],
      ['t', '**Transitiv** (essen, sehen, sagen …): Subjekt im **Obliquus** (min, te, wî …), das Verb richtet sich nach dem **Objekt**.'],
      ['tab', [['Min nan xwar.', 'Ich aß Brot.'], ['Te ez dîtim.', 'Du hast mich gesehen.']]],
      ['t', '💡 Markiere bei deinen Verben „transitiv“ oder „intransitiv“ – dann lernst du es direkt mit.']
    ] },
    { title: 'Futur', emoji: '⏩', blocks: [
      ['t', '**ê** + **bi-** + Präsensstamm + Personalendung'],
      ['tab', [['ez ê biçim', 'ich werde gehen'], ['tu yê bixwî', 'du wirst essen'], ['ew ê bike', 'er/sie wird machen']]],
      ['t', 'Umgangssprachlich oft zusammengezogen: *ezê, tuyê, ewê*.']
    ] },
    { title: 'Verneinung', emoji: '🚫', blocks: [
      ['tab', [
        ['Präsens: **na-** statt *di-*', 'ez naçim – ich gehe nicht'],
        ['Vergangenheit: **ne-**', 'ez neçûm, min nexwar'],
        ['Imperativ: **ne-** statt *bi-*', 'nexwe! – iss nicht!']
      ]]
    ] },
    { title: 'Ezafe (Verbindung)', emoji: '🔗', blocks: [
      ['t', 'Wird ein Nomen näher beschrieben (Besitz, Adjektiv), bekommt es eine Endung – abhängig vom Geschlecht. Deshalb kannst du bei Nomen **m** oder **f** angeben.'],
      ['tab', [['männlich: **-ê**', 'bavê min – mein Vater'], ['weiblich: **-a**', 'dayika min – meine Mutter'], ['Plural: **-ên**', 'birayên min – meine Brüder']]],
      ['t', 'Unbestimmt („ein“): **-ek** – *pirtûkek* (ein Buch).']
    ] },
    { title: 'So lernst du effektiv', emoji: '🧠', blocks: [
      ['ul', [
        '**Jeden Tag ein bisschen** ist besser als einmal pro Woche viel. Setz dir ein Tagesziel.',
        '**Ehrlich bewerten:** Tippe „Nochmal“, wenn du ein Wort nicht wusstest. Schwere Wörter kommen dann öfter, leichte seltener.',
        '**Beide Richtungen** üben – Deutsch → Kurdisch ist deutlich schwerer.',
        '**Schreiben** statt nur Aufdecken – so lernst du auch ê, î, û, ç, ş.',
        '**Beispielsätze** und Eselsbrücken eintragen – Wörter im Zusammenhang bleiben besser hängen.',
        'Bei Verben immer **Präsensstamm** und **Vergangenheit** mitlernen.'
      ]]
    ] }
  ];
})();
