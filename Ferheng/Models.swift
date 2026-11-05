import Foundation

// MARK: - Wortarten & Eigenschaften

enum WordType: String, Codable, CaseIterable, Identifiable {
    case noun, verb, adj, phrase, other
    var id: String { rawValue }
    var label: String {
        switch self {
        case .noun: return "Nomen"
        case .verb: return "Verb"
        case .adj: return "Adjektiv"
        case .phrase: return "Redewendung"
        case .other: return "Sonstiges"
        }
    }
    var icon: String {
        switch self {
        case .noun: return "cube"
        case .verb: return "bolt"
        case .adj: return "paintpalette"
        case .phrase: return "text.bubble"
        case .other: return "textformat"
        }
    }
}

enum Gender: String, Codable, CaseIterable, Identifiable {
    case none, m, f
    var id: String { rawValue }
    var label: String {
        switch self {
        case .none: return "–"
        case .m: return "männlich (m)"
        case .f: return "weiblich (f)"
        }
    }
    var short: String { self == .none ? "" : rawValue }
}

enum Transitivity: String, Codable, CaseIterable, Identifiable {
    case unknown, transitive, intransitive
    var id: String { rawValue }
    var label: String {
        switch self {
        case .unknown: return "–"
        case .transitive: return "transitiv"
        case .intransitive: return "intransitiv"
        }
    }
}

/// Die Verbformen, die im Verb-Trainer einzeln abgefragt werden.
enum VerbForm: String, Codable, CaseIterable, Identifiable {
    case stem, present, past, imperative, future
    var id: String { rawValue }
    var label: String {
        switch self {
        case .stem: return "Präsensstamm"
        case .present: return "Präsens (ez …)"
        case .past: return "Vergangenheit"
        case .imperative: return "Imperativ"
        case .future: return "Futur"
        }
    }
    var hint: String {
        switch self {
        case .stem: return "z. B. -ç-"
        case .present: return "z. B. ez diçim"
        case .past: return "z. B. ez çûm / min xwar"
        case .imperative: return "z. B. here!"
        case .future: return "z. B. ez ê biçim"
        }
    }
}

// MARK: - Ordner & Karten

struct Folder: Codable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var emoji: String = "📁"
    var colorName: String = "teal"
    var parentID: UUID? = nil
    /// Verknüpfte Ordner: deren Wörter erscheinen ebenfalls in diesem Ordner (Sammlung).
    var linkedIDs: [UUID] = []
    var createdAt = Date()
}

struct Card: Codable, Identifiable, Hashable {
    var id = UUID()
    var folderID: UUID
    var kurdish: String
    var german: String
    var type: WordType = .other
    var gender: Gender = .none
    var plural: String = ""
    var transitivity: Transitivity = .unknown
    var forms: [String: String] = [:]
    var exampleKu: String = ""
    var exampleDe: String = ""
    var note: String = ""
    var createdAt = Date()

    func form(_ f: VerbForm) -> String {
        (forms[f.rawValue] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var filledForms: [VerbForm] {
        guard type == .verb else { return [] }
        return VerbForm.allCases.filter { !form($0).isEmpty }
    }
}

// MARK: - Lernstand

struct ReviewState: Codable, Hashable {
    var ease: Double = 2.5
    var interval: Int = 0
    var due: Date = .distantPast
    var reps: Int = 0
    var lapses: Int = 0
    var seen: Int = 0
    var correct: Int = 0
    var wrong: Int = 0
    var streak: Int = 0
    var firstEasy: Bool = false
    var lastSeen: Date? = nil
}

enum Grade: Int, CaseIterable {
    case again, hard, good, easy
    var label: String {
        switch self {
        case .again: return "Nochmal"
        case .hard: return "Schwer"
        case .good: return "Gut"
        case .easy: return "Einfach"
        }
    }
}

enum Mastery: String, CaseIterable, Identifiable {
    case new, hard, learning, easy, mastered
    var id: String { rawValue }
    var label: String {
        switch self {
        case .new: return "Neu"
        case .hard: return "Schwer"
        case .learning: return "In Arbeit"
        case .easy: return "Leicht"
        case .mastered: return "Sitzt"
        }
    }
}

struct DayStat: Codable, Hashable {
    var reviews: Int = 0
    var correct: Int = 0
    var newCards: Int = 0
}

// MARK: - Lern-Einstellungen

enum Direction: String, Codable, CaseIterable, Identifiable {
    case kuToDe, deToKu, mixed
    var id: String { rawValue }
    var label: String {
        switch self {
        case .kuToDe: return "Kurdisch → Deutsch"
        case .deToKu: return "Deutsch → Kurdisch"
        case .mixed: return "Gemischt"
        }
    }
}

enum QuizKind: String, Codable, CaseIterable, Identifiable {
    case flashcard, multipleChoice, typing, mixed
    var id: String { rawValue }
    var label: String {
        switch self {
        case .flashcard: return "Karteikarte"
        case .multipleChoice: return "Auswahl"
        case .typing: return "Schreiben"
        case .mixed: return "Gemischt"
        }
    }
    var icon: String {
        switch self {
        case .flashcard: return "rectangle.on.rectangle.angled"
        case .multipleChoice: return "list.bullet.rectangle"
        case .typing: return "keyboard"
        case .mixed: return "shuffle"
        }
    }
}

enum LearnMode: String, CaseIterable, Identifiable {
    case smart, hard, practice, verbs
    var id: String { rawValue }
    var label: String {
        switch self {
        case .smart: return "Smart lernen"
        case .hard: return "Schwierige Wörter"
        case .practice: return "Freies Üben"
        case .verbs: return "Verb-Trainer"
        }
    }
    var subtitle: String {
        switch self {
        case .smart: return "Fällige Wiederholungen + neue Wörter"
        case .hard: return "Nur Wörter, die dir schwerfallen"
        case .practice: return "Zufällig – schwere Wörter kommen öfter"
        case .verbs: return "Stamm, Präsens, Vergangenheit, Imperativ, Futur"
        }
    }
    var icon: String {
        switch self {
        case .smart: return "brain.head.profile"
        case .hard: return "flame"
        case .practice: return "dice"
        case .verbs: return "bolt.fill"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var dailyGoal: Int = 20
    var newPerDay: Int = 10
    var sessionSize: Int = 20
    var direction: Direction = .mixed
    var quizKind: QuizKind = .mixed
}

/// Ein einzelner Abfrage-Eintrag: entweder eine Vokabel oder eine bestimmte Verbform.
struct StudyItem: Identifiable, Hashable {
    let id = UUID()
    let cardID: UUID
    let form: VerbForm?

    var key: String {
        if let form { return "v:\(cardID.uuidString):\(form.rawValue)" }
        return "c:\(cardID.uuidString)"
    }
}

enum Day {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    static func key(_ date: Date = Date()) -> String { formatter.string(from: date) }
    static func date(daysAgo: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
