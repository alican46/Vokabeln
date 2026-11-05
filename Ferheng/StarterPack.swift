import Foundation

struct StarterCard {
    var ku: String
    var de: String
    var type: WordType = .other
    var gender: Gender = .none
    var trans: Transitivity = .unknown
    var forms: [String: String] = [:]
    var exKu = ""
    var exDe = ""
    var note = ""
}

struct StarterFolder {
    var name: String
    var emoji: String
    var color: String
    var cards: [StarterCard] = []
    var children: [StarterFolder] = []
}

/// Beispielvokabeln in Kurmancî, damit du sofort loslegen kannst.
enum StarterPack {
    private static func noun(_ ku: String, _ de: String, _ g: Gender, exKu: String = "", exDe: String = "") -> StarterCard {
        StarterCard(ku: ku, de: de, type: .noun, gender: g, exKu: exKu, exDe: exDe)
    }
    private static func phrase(_ ku: String, _ de: String, note: String = "") -> StarterCard {
        StarterCard(ku: ku, de: de, type: .phrase, note: note)
    }
    private static func verb(_ ku: String, _ de: String, _ t: Transitivity,
                             stem: String, pres: String, past: String, imp: String, fut: String) -> StarterCard {
        StarterCard(ku: ku, de: de, type: .verb, trans: t, forms: [
            VerbForm.stem.rawValue: stem,
            VerbForm.present.rawValue: pres,
            VerbForm.past.rawValue: past,
            VerbForm.imperative.rawValue: imp,
            VerbForm.future.rawValue: fut
        ])
    }

    static let root = StarterFolder(
        name: "Kurmancî Grundlagen", emoji: "☀️", color: "teal",
        children: [
            StarterFolder(name: "Begrüßung & Höflichkeit", emoji: "👋", color: "amber", cards: [
                phrase("Silav", "Hallo"),
                phrase("Rojbaş", "Guten Morgen / Guten Tag"),
                phrase("Êvarbaş", "Guten Abend"),
                phrase("Şevbaş", "Gute Nacht"),
                phrase("Tu çawa yî?", "Wie geht es dir?"),
                phrase("Ez baş im", "Mir geht es gut"),
                phrase("Spas", "Danke"),
                phrase("Ji kerema xwe", "Bitte (Aufforderung)"),
                phrase("Bi xêr hatî", "Willkommen", note: "Antwort: Bi xêr bimînî"),
                phrase("Xatirê te", "Auf Wiedersehen", note: "Sagt derjenige, der geht."),
                StarterCard(ku: "Erê", de: "Ja"),
                StarterCard(ku: "Na", de: "Nein"),
                phrase("Navê te çi ye?", "Wie heißt du?"),
                phrase("Navê min … ye", "Ich heiße …")
            ]),
            StarterFolder(name: "Zahlen", emoji: "🔢", color: "blue", cards: [
                ("yek", "eins"), ("du", "zwei"), ("sê", "drei"), ("çar", "vier"), ("pênc", "fünf"),
                ("şeş", "sechs"), ("heft", "sieben"), ("heşt", "acht"), ("neh", "neun"), ("deh", "zehn")
            ].map { StarterCard(ku: $0.0, de: $0.1) }),
            StarterFolder(name: "Familie", emoji: "👨‍👩‍👧", color: "pink", cards: [
                noun("dayik", "Mutter", .f),
                noun("bav", "Vater", .m),
                noun("bira", "Bruder", .m),
                noun("xwişk", "Schwester", .f),
                noun("kur", "Sohn / Junge", .m),
                noun("keç", "Tochter / Mädchen", .f),
                noun("malbat", "Familie", .f),
                noun("bapîr", "Großvater", .m),
                noun("dapîr", "Großmutter", .f)
            ]),
            StarterFolder(name: "Alltag", emoji: "🏠", color: "green", cards: [
                noun("av", "Wasser", .f),
                noun("nan", "Brot", .m, exKu: "Min nan xwar.", exDe: "Ich habe Brot gegessen."),
                noun("mal", "Haus / Zuhause", .f, exKu: "Ez diçim malê.", exDe: "Ich gehe nach Hause."),
                noun("pirtûk", "Buch", .f),
                noun("çay", "Tee", .f),
                noun("sêv", "Apfel", .f),
                noun("roj", "Tag / Sonne", .f),
                noun("şev", "Nacht", .f),
                noun("dil", "Herz", .m),
                StarterCard(ku: "mezin", de: "groß", type: .adj),
                StarterCard(ku: "biçûk", de: "klein", type: .adj),
                StarterCard(ku: "baş", de: "gut", type: .adj),
                StarterCard(ku: "xweş", de: "schön / angenehm", type: .adj),
                StarterCard(ku: "nû", de: "neu", type: .adj),
                StarterCard(ku: "germ", de: "warm", type: .adj),
                StarterCard(ku: "sar", de: "kalt", type: .adj)
            ]),
            StarterFolder(name: "Wichtige Verben", emoji: "⚡️", color: "violet", cards: [
                verb("çûn", "gehen", .intransitive, stem: "-ç-", pres: "ez diçim", past: "ez çûm", imp: "here!", fut: "ez ê biçim"),
                verb("hatin", "kommen", .intransitive, stem: "-ê-", pres: "ez têm", past: "ez hatim", imp: "were!", fut: "ez ê bêm"),
                verb("xwarin", "essen", .transitive, stem: "-xw-", pres: "ez dixwim", past: "min xwar", imp: "bixwe!", fut: "ez ê bixwim"),
                verb("vexwarin", "trinken", .transitive, stem: "-vexw-", pres: "ez vedixwim", past: "min vexwar", imp: "vexwe!", fut: "ez ê vexwim"),
                verb("kirin", "machen / tun", .transitive, stem: "-k-", pres: "ez dikim", past: "min kir", imp: "bike!", fut: "ez ê bikim"),
                verb("dîtin", "sehen / finden", .transitive, stem: "-bîn-", pres: "ez dibînim", past: "min dît", imp: "bibîne!", fut: "ez ê bibînim"),
                verb("gotin", "sagen", .transitive, stem: "-bêj-", pres: "ez dibêjim", past: "min got", imp: "bibêje!", fut: "ez ê bibêjim"),
                verb("xwendin", "lesen / lernen", .transitive, stem: "-xwîn-", pres: "ez dixwînim", past: "min xwend", imp: "bixwîne!", fut: "ez ê bixwînim"),
                verb("dan", "geben", .transitive, stem: "-d-", pres: "ez didim", past: "min da", imp: "bide!", fut: "ez ê bidim"),
                verb("zanîn", "wissen / können", .transitive, stem: "-zan-", pres: "ez dizanim", past: "min zanî", imp: "bizane!", fut: "ez ê bizanim"),
                verb("rûniştin", "sich setzen / sitzen", .intransitive, stem: "-rûn-", pres: "ez rûdinim", past: "ez rûniştim", imp: "rûne!", fut: "ez ê rûnim")
            ])
        ]
    )
}
