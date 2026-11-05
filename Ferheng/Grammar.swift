import Foundation

/// Grammatik-Spickzettel für Kurmancî. Texte unterstützen **fett** und *kursiv*.
enum GrammarBlock: Hashable {
    case text(String)
    case table([[String]])
    case bullets([String])
}

struct GrammarSection: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let emoji: String
    let blocks: [GrammarBlock]
}

enum Grammar {
    static let sections: [GrammarSection] = [
        GrammarSection(title: "Aussprache & Alphabet", emoji: "🗣️", blocks: [
            .text("Kurmancî wird mit lateinischen Buchstaben geschrieben – fast alles wird so gesprochen, wie es geschrieben wird."),
            .table([
                ["**c**", "wie „dsch“ in *Dschungel*"],
                ["**ç**", "wie „tsch“ in *Tschüss*"],
                ["**ş**", "wie „sch“ in *Schule*"],
                ["**j**", "weiches „j“ wie in *Journal*"],
                ["**x**", "wie „ch“ in *Bach*"],
                ["**q**", "tiefes, hinten gesprochenes k"],
                ["**y**", "wie „j“ in *ja*"],
                ["**v / w**", "v = deutsches „w“, w = englisches „w“"],
                ["**z**", "stimmhaftes s wie in *Sonne*"],
                ["**ê**", "langes e wie in *See*"],
                ["**î / û**", "langes i bzw. langes u"],
                ["**e**", "kurzes e/ä wie in *Bett*"],
                ["**i**", "sehr kurzes, fast verschlucktes i"]
            ])
        ]),
        GrammarSection(title: "Personalpronomen", emoji: "🙋", blocks: [
            .text("Es gibt zwei Reihen: **Rektus** (Grundform) und **Obliquus** (für Besitz, nach Präpositionen und als Subjekt transitiver Verben in der Vergangenheit)."),
            .table([
                ["", "**Rektus**", "**Obliquus**"],
                ["ich", "ez", "min"],
                ["du", "tu", "te"],
                ["er / sie", "ew", "wî (m) / wê (f)"],
                ["wir", "em", "me"],
                ["ihr / Sie", "hûn", "we"],
                ["sie (Pl.)", "ew", "wan"]
            ])
        ]),
        GrammarSection(title: "Sein (Kopula)", emoji: "🟰", blocks: [
            .text("„Sein“ wird als Endung angehängt. Nach einem Vokal steht die zweite Form."),
            .table([
                ["ez … **im** / **me**", "Ez baş im. – Mir geht's gut."],
                ["tu … **î** / **yî**", "Tu çawa yî? – Wie geht's dir?"],
                ["ew … **e** / **ye**", "Ew mezin e. – Er/Sie ist groß."],
                ["em/hûn/ew … **in** / **ne**", "Em baş in. – Uns geht's gut."]
            ])
        ]),
        GrammarSection(title: "Verben: die wichtigsten Formen", emoji: "⚡️", blocks: [
            .text("Jedes Verb hat zwei Stämme, die du lernen musst – genau dafür gibt es den **Verb-Trainer**:"),
            .bullets([
                "**Infinitiv** (Grundform) endet auf *-in*, *-n* oder *-în*, z. B. *xwarin*",
                "**Vergangenheitsstamm** = Infinitiv ohne *-in/-n*: *xwar*",
                "**Präsensstamm** – oft unregelmäßig: *-xw-*"
            ]),
            .text("**Präsens** = *di-* + Präsensstamm + Personalendung:"),
            .table([
                ["ez di…**im**", "ez dixwim"],
                ["tu di…**î**", "tu dixwî"],
                ["ew di…**e**", "ew dixwe"],
                ["em/hûn/ew di…**in**", "em dixwin"]
            ]),
            .text("Bei Verben mit Vorsilbe steht *di-* dazwischen: *vexwarin → ez ve**di**xwim*.")
        ]),
        GrammarSection(title: "Imperativ (Befehlsform)", emoji: "❗", blocks: [
            .text("**bi-** + Präsensstamm + **-e** (Singular) / **-in** (Plural)"),
            .table([
                ["xwarin", "bixwe! / bixwin!"],
                ["kirin", "bike! / bikin!"],
                ["gotin", "bibêje! / bibêjin!"]
            ]),
            .text("Unregelmäßig: *çûn → here!*, *hatin → were!*. Verben mit Vorsilbe bekommen kein *bi-*: *vexwe!*, *rûne!*")
        ]),
        GrammarSection(title: "Vergangenheit & Ergativ", emoji: "⏪", blocks: [
            .text("Die große Besonderheit im Kurdischen: In der Vergangenheit kommt es darauf an, ob ein Verb **transitiv** (hat ein Objekt) oder **intransitiv** ist."),
            .text("**Intransitiv** (gehen, kommen, sitzen …): Subjekt im Rektus, das Verb richtet sich nach dem Subjekt."),
            .table([
                ["ez çûm", "ich ging"],
                ["tu çûyî", "du gingst"],
                ["ew çû", "er/sie ging"],
                ["em çûn", "wir gingen"]
            ]),
            .text("**Transitiv** (essen, sehen, sagen …): Subjekt im **Obliquus** (min, te, wî …), das Verb richtet sich nach dem **Objekt**."),
            .table([
                ["Min nan xwar.", "Ich aß Brot."],
                ["Te ez dîtim.", "Du hast mich gesehen."]
            ]),
            .text("💡 Markiere bei deinen Verben „transitiv“ oder „intransitiv“ – dann lernst du es direkt mit.")
        ]),
        GrammarSection(title: "Futur", emoji: "⏩", blocks: [
            .text("**ê** + **bi-** + Präsensstamm + Personalendung"),
            .table([
                ["ez ê biçim", "ich werde gehen"],
                ["tu yê bixwî", "du wirst essen"],
                ["ew ê bike", "er/sie wird machen"]
            ]),
            .text("Umgangssprachlich oft zusammengezogen: *ezê, tuyê, ewê*.")
        ]),
        GrammarSection(title: "Verneinung", emoji: "🚫", blocks: [
            .table([
                ["Präsens: **na-** statt *di-*", "ez naçim – ich gehe nicht"],
                ["Vergangenheit: **ne-**", "ez neçûm, min nexwar"],
                ["Imperativ: **ne-** statt *bi-*", "nexwe! – iss nicht!"]
            ])
        ]),
        GrammarSection(title: "Ezafe (Verbindung)", emoji: "🔗", blocks: [
            .text("Wird ein Nomen näher beschrieben (Besitz, Adjektiv), bekommt es eine Endung – abhängig vom Geschlecht. Deshalb kannst du bei Nomen **m** oder **f** angeben."),
            .table([
                ["männlich: **-ê**", "bavê min – mein Vater"],
                ["weiblich: **-a**", "dayika min – meine Mutter"],
                ["Plural: **-ên**", "birayên min – meine Brüder"]
            ]),
            .text("Unbestimmt („ein“): **-ek** – *pirtûkek* (ein Buch).")
        ]),
        GrammarSection(title: "So lernst du effektiv", emoji: "🧠", blocks: [
            .bullets([
                "**Jeden Tag ein bisschen** ist besser als einmal pro Woche viel. Setz dir ein Tagesziel.",
                "**Ehrlich bewerten:** Tippe „Nochmal“, wenn du ein Wort nicht wusstest. Schwere Wörter kommen dann öfter, leichte seltener.",
                "**Beide Richtungen** üben – Deutsch → Kurdisch ist deutlich schwerer.",
                "**Schreiben** statt nur Aufdecken – so lernst du auch ê, î, û, ç, ş.",
                "**Beispielsätze** und Eselsbrücken eintragen – Wörter im Zusammenhang bleiben besser hängen.",
                "Bei Verben immer **Präsensstamm** und **Vergangenheit** mitlernen."
            ])
        ])
    ]
}
