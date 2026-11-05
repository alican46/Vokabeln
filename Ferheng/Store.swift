import Foundation
import Observation

struct FlatFolder: Identifiable {
    let folder: Folder
    let depth: Int
    var id: UUID { folder.id }
}

enum MergeMode: String, CaseIterable, Identifiable {
    case link, combine
    var id: String { rawValue }
    var label: String {
        switch self {
        case .link: return "Verknüpfen"
        case .combine: return "Zusammenführen"
        }
    }
    var explanation: String {
        switch self {
        case .link: return "Neuer Sammel-Ordner, der die Wörter der ausgewählten Ordner enthält. Die Originale bleiben bestehen, der Lernfortschritt ist geteilt."
        case .combine: return "Alle Wörter und Unterordner werden in den neuen Ordner verschoben. Die ausgewählten Ordner werden danach entfernt."
        }
    }
}

@Observable
final class AppStore {
    var folders: [Folder] = []
    var cards: [Card] = []
    var progress: [String: ReviewState] = [:]
    var log: [String: DayStat] = [:]
    var settings = AppSettings()
    var hasOnboarded = false

    // MARK: Persistenz

    struct Snapshot: Codable {
        var folders: [Folder] = []
        var cards: [Card] = []
        var progress: [String: ReviewState] = [:]
        var log: [String: DayStat] = [:]
        var settings = AppSettings()
        var hasOnboarded = false

        init() {}

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            folders = try c.decodeIfPresent([Folder].self, forKey: .folders) ?? []
            cards = try c.decodeIfPresent([Card].self, forKey: .cards) ?? []
            progress = try c.decodeIfPresent([String: ReviewState].self, forKey: .progress) ?? [:]
            log = try c.decodeIfPresent([String: DayStat].self, forKey: .log) ?? [:]
            settings = try c.decodeIfPresent(AppSettings.self, forKey: .settings) ?? AppSettings()
            hasOnboarded = try c.decodeIfPresent(Bool.self, forKey: .hasOnboarded) ?? false
        }
    }

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("ferheng-daten.json")
    }

    init() {
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else { return }
        apply(snap)
    }

    private func apply(_ snap: Snapshot) {
        folders = snap.folders
        cards = snap.cards
        progress = snap.progress
        log = snap.log
        settings = snap.settings
        hasOnboarded = snap.hasOnboarded
    }

    var snapshot: Snapshot {
        var s = Snapshot()
        s.folders = folders
        s.cards = cards
        s.progress = progress
        s.log = log
        s.settings = settings
        s.hasOnboarded = hasOnboarded
        return s
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: Self.fileURL, options: .atomic)
        } catch {
            print("Speichern fehlgeschlagen: \(error)")
        }
    }

    /// Erstellt eine Backup-Datei und gibt deren URL zurück (zum Teilen).
    func exportBackup() -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snapshot) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Ferheng-Backup-\(Day.key()).json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    func importBackup(from url: URL) throws {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let snap = try JSONDecoder().decode(Snapshot.self, from: data)
        apply(snap)
        hasOnboarded = true
        save()
    }

    func resetAll() {
        folders = []
        cards = []
        progress = [:]
        log = [:]
        save()
    }

    // MARK: Ordner-Abfragen

    func folder(_ id: UUID?) -> Folder? {
        guard let id else { return nil }
        return folders.first { $0.id == id }
    }

    func children(of parent: UUID?) -> [Folder] {
        folders.filter { $0.parentID == parent }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func path(to id: UUID) -> [Folder] {
        var result: [Folder] = []
        var current = folder(id)
        var guardCount = 0
        while let f = current, guardCount < 50 {
            result.insert(f, at: 0)
            current = folder(f.parentID)
            guardCount += 1
        }
        return result
    }

    func descendantIDs(of id: UUID) -> Set<UUID> {
        var result: Set<UUID> = [id]
        var stack = [id]
        while let next = stack.popLast() {
            for child in folders where child.parentID == next && !result.contains(child.id) {
                result.insert(child.id)
                stack.append(child.id)
            }
        }
        return result
    }

    func flatFolders(excluding excluded: Set<UUID> = []) -> [FlatFolder] {
        var out: [FlatFolder] = []
        func walk(_ parent: UUID?, _ depth: Int) {
            for f in children(of: parent) where !excluded.contains(f.id) {
                out.append(FlatFolder(folder: f, depth: depth))
                walk(f.id, depth + 1)
            }
        }
        walk(nil, 0)
        return out
    }

    func directCards(in folderID: UUID) -> [Card] {
        cards.filter { $0.folderID == folderID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Alle Wörter eines Ordners inkl. Unterordner und verknüpfter Ordner (ohne Doppelte).
    func allCards(in folderID: UUID) -> [Card] {
        var folderIDs: Set<UUID> = []
        var stack = [folderID]
        while let id = stack.popLast() {
            guard !folderIDs.contains(id) else { continue }
            folderIDs.insert(id)
            for child in folders where child.parentID == id { stack.append(child.id) }
            if let f = folder(id) { stack.append(contentsOf: f.linkedIDs) }
        }
        return cards.filter { folderIDs.contains($0.folderID) }
    }

    func card(_ id: UUID) -> Card? {
        cards.first { $0.id == id }
    }

    // MARK: Ordner-Änderungen

    @discardableResult
    func addFolder(name: String, emoji: String, colorName: String, parentID: UUID?) -> Folder {
        let f = Folder(name: name, emoji: emoji.isEmpty ? "📁" : emoji, colorName: colorName, parentID: parentID)
        folders.append(f)
        save()
        return f
    }

    func updateFolder(_ folder: Folder) {
        guard let i = folders.firstIndex(where: { $0.id == folder.id }) else { return }
        folders[i] = folder
        save()
    }

    func deleteFolder(_ id: UUID) {
        let ids = descendantIDs(of: id)
        let removedCards = cards.filter { ids.contains($0.folderID) }
        for c in removedCards { removeProgress(for: c.id) }
        cards.removeAll { ids.contains($0.folderID) }
        folders.removeAll { ids.contains($0.id) }
        for i in folders.indices {
            folders[i].linkedIDs.removeAll { ids.contains($0) }
        }
        save()
    }

    /// Fügt mehrere Ordner zu einem neuen Ordner zusammen.
    @discardableResult
    func merge(_ ids: [UUID], name: String, emoji: String, colorName: String, parentID: UUID?, mode: MergeMode) -> Folder {
        let selected = Set(ids)
        var parent = parentID
        // Der neue Ordner darf nicht in einem Ordner landen, der gleich verschwindet.
        if mode == .combine, let p = parent,
           let outermost = path(to: p).first(where: { selected.contains($0.id) }) {
            parent = outermost.parentID
        }
        var newFolder = Folder(name: name, emoji: emoji.isEmpty ? "🗂️" : emoji, colorName: colorName, parentID: parent)

        switch mode {
        case .link:
            newFolder.linkedIDs = ids
            folders.append(newFolder)
        case .combine:
            folders.append(newFolder)
            for id in ids {
                for i in folders.indices where folders[i].parentID == id && !selected.contains(folders[i].id) {
                    folders[i].parentID = newFolder.id
                }
                for i in cards.indices where cards[i].folderID == id {
                    cards[i].folderID = newFolder.id
                }
            }
            folders.removeAll { selected.contains($0.id) }
            for i in folders.indices {
                let hadLink = folders[i].linkedIDs.contains { selected.contains($0) }
                folders[i].linkedIDs.removeAll { selected.contains($0) }
                if hadLink && folders[i].id != newFolder.id && !folders[i].linkedIDs.contains(newFolder.id) {
                    folders[i].linkedIDs.append(newFolder.id)
                }
            }
        }
        save()
        return newFolder
    }

    func unlink(_ linkedID: UUID, from folderID: UUID) {
        guard let i = folders.firstIndex(where: { $0.id == folderID }) else { return }
        folders[i].linkedIDs.removeAll { $0 == linkedID }
        save()
    }

    // MARK: Karten-Änderungen

    func upsert(_ card: Card) {
        if let i = cards.firstIndex(where: { $0.id == card.id }) {
            cards[i] = card
        } else {
            cards.append(card)
        }
        save()
    }

    func deleteCard(_ id: UUID) {
        cards.removeAll { $0.id == id }
        removeProgress(for: id)
        save()
    }

    func resetProgress(for cardID: UUID) {
        removeProgress(for: cardID)
        save()
    }

    private func removeProgress(for cardID: UUID) {
        let s = cardID.uuidString
        progress = progress.filter { !$0.key.contains(s) }
    }

    /// Fügt mehrere Wörter aus Text ein. Eine Zeile pro Wort, z. B. "av = Wasser".
    func bulkAdd(text: String, folderID: UUID, type: WordType) -> Int {
        var count = 0
        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmed
            guard !line.isEmpty else { continue }
            guard let pair = Self.splitLine(line) else { continue }
            cards.append(Card(folderID: folderID, kurdish: pair.0, german: pair.1, type: type))
            count += 1
        }
        if count > 0 { save() }
        return count
    }

    static func splitLine(_ line: String) -> (String, String)? {
        for sep in ["\t", " = ", "=", ";", " – ", " — ", " - ", ":"] {
            if let r = line.range(of: sep) {
                let a = String(line[..<r.lowerBound]).trimmed
                let b = String(line[r.upperBound...]).trimmed
                if !a.isEmpty && !b.isEmpty { return (a, b) }
            }
        }
        return nil
    }

    // MARK: Lernstand

    func state(_ key: String) -> ReviewState {
        progress[key] ?? ReviewState()
    }

    func mastery(of card: Card) -> Mastery {
        SRS.mastery(state("c:\(card.id.uuidString)"))
    }

    func record(_ item: StudyItem, grade: Grade, practice: Bool) {
        let before = state(item.key)
        let after = practice
            ? SRS.practice(before, correct: grade != .again)
            : SRS.schedule(before, grade: grade)
        progress[item.key] = after

        let today = Day.key()
        var stat = log[today] ?? DayStat()
        stat.reviews += 1
        if grade != .again { stat.correct += 1 }
        if before.seen == 0 { stat.newCards += 1 }
        log[today] = stat
        save()
    }

    var todayStat: DayStat { log[Day.key()] ?? DayStat() }

    var streak: Int {
        var days = 0
        var offset = (log[Day.key()]?.reviews ?? 0) > 0 ? 0 : 1
        while (log[Day.key(Day.date(daysAgo: offset))]?.reviews ?? 0) > 0 {
            days += 1
            offset += 1
        }
        return days
    }

    func dueCount(in scope: [Card]) -> Int {
        let now = Date()
        return vocabItems(scope).filter { let s = state($0.key); return s.seen > 0 && s.due <= now }.count
    }

    func newCount(in scope: [Card]) -> Int {
        vocabItems(scope).filter { state($0.key).seen == 0 }.count
    }

    func hardItems(in scope: [Card]) -> [StudyItem] {
        (vocabItems(scope) + verbItems(scope))
            .filter { SRS.mastery(state($0.key)) == .hard }
    }

    func masteryCounts(_ scope: [Card]) -> [Mastery: Int] {
        var result: [Mastery: Int] = [:]
        for c in scope { result[mastery(of: c), default: 0] += 1 }
        return result
    }

    // MARK: Lernsitzungen

    func vocabItems(_ scope: [Card]) -> [StudyItem] {
        scope.map { StudyItem(cardID: $0.id, form: nil) }
    }

    func verbItems(_ scope: [Card]) -> [StudyItem] {
        scope.flatMap { card in card.filledForms.map { StudyItem(cardID: card.id, form: $0) } }
    }

    func buildSession(scope: [Card], mode: LearnMode, size: Int) -> [StudyItem] {
        let now = Date()
        switch mode {
        case .smart, .verbs:
            let items = mode == .verbs ? verbItems(scope) : vocabItems(scope)
            let due = items
                .filter { let s = state($0.key); return s.seen > 0 && s.due <= now }
                .sorted { SRS.difficulty(state($0.key)) > SRS.difficulty(state($1.key)) }
            let fresh = items.filter { state($0.key).seen == 0 }.shuffled()
            let newLimit = mode == .verbs ? size : max(0, settings.newPerDay - todayStat.newCards)
            var result = Array(due.prefix(size))
            if result.count < size {
                result += fresh.prefix(min(newLimit, size - result.count))
            }
            if mode == .verbs && result.count < size {
                let used = Set(result.map(\.key))
                result += weightedSample(items.filter { !used.contains($0.key) }, count: size - result.count)
            }
            return result.shuffled()
        case .hard:
            let items = (vocabItems(scope) + verbItems(scope))
                .filter { let s = state($0.key); return s.seen > 0 && SRS.difficulty(s) > 0.5 }
                .sorted { SRS.difficulty(state($0.key)) > SRS.difficulty(state($1.key)) }
            return Array(items.prefix(size)).shuffled()
        case .practice:
            return weightedSample(vocabItems(scope), count: size)
        }
    }

    /// Zufallsauswahl, bei der schwere Wörter ein höheres Gewicht haben.
    func weightedSample(_ items: [StudyItem], count: Int) -> [StudyItem] {
        var pool = items.map { item -> (StudyItem, Double) in
            let s = state(item.key)
            let w = s.seen == 0 ? 1.5 : 1 + max(0, SRS.difficulty(s)) * 1.5
            return (item, w)
        }
        var out: [StudyItem] = []
        while out.count < count && !pool.isEmpty {
            let total = pool.reduce(0) { $0 + $1.1 }
            var r = Double.random(in: 0..<total)
            var index = pool.count - 1
            for (i, entry) in pool.enumerated() {
                r -= entry.1
                if r <= 0 { index = i; break }
            }
            out.append(pool.remove(at: index).0)
        }
        return out
    }

    // MARK: Abfrage-Texte

    func prompt(for item: StudyItem, card: Card, direction: Direction) -> String {
        if item.form != nil { return card.kurdish }
        return direction == .deToKu ? card.german : card.kurdish
    }

    func answer(for item: StudyItem, card: Card, direction: Direction) -> String {
        if let form = item.form { return card.form(form) }
        return direction == .deToKu ? card.kurdish : card.german
    }

    func distractors(for item: StudyItem, card: Card, direction: Direction, count: Int) -> [String] {
        let correct = answer(for: item, card: card, direction: direction)
        var pool: [String] = []
        if let form = item.form {
            pool += card.filledForms.filter { $0 != form }.map { card.form($0) }
            pool += cards.filter { $0.id != card.id }.map { $0.form(form) }.filter { !$0.isEmpty }.shuffled()
        } else {
            let others = cards.filter { $0.id != card.id }.shuffled()
            let same = others.filter { $0.type == card.type }
            let rest = others.filter { $0.type != card.type }
            pool = (same + rest).map { direction == .deToKu ? $0.kurdish : $0.german }
        }
        var seen: Set<String> = [correct.lowercased()]
        var out: [String] = []
        for p in pool where !seen.contains(p.lowercased()) {
            seen.insert(p.lowercased())
            out.append(p)
            if out.count == count { break }
        }
        return out
    }

    // MARK: Startpaket

    func loadStarterPack() {
        func insert(_ node: StarterFolder, parent: UUID?) {
            let f = Folder(name: node.name, emoji: node.emoji, colorName: node.color, parentID: parent)
            folders.append(f)
            for c in node.cards {
                var card = Card(folderID: f.id, kurdish: c.ku, german: c.de, type: c.type)
                card.gender = c.gender
                card.transitivity = c.trans
                card.forms = c.forms
                card.exampleKu = c.exKu
                card.exampleDe = c.exDe
                card.note = c.note
                cards.append(card)
            }
            for child in node.children { insert(child, parent: f.id) }
        }
        insert(StarterPack.root, parent: nil)
        hasOnboarded = true
        save()
    }
}
