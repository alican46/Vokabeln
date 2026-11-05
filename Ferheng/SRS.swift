import Foundation

/// Spaced-Repetition-Logik (angelehnt an SM-2).
/// Schwere Wörter bekommen kurze Abstände und werden öfter abgefragt,
/// leichte Wörter wandern schnell in große Abstände.
enum SRS {
    static let day: TimeInterval = 86_400

    static func schedule(_ s: ReviewState, grade: Grade, now: Date = Date()) -> ReviewState {
        var n = s
        n.seen += 1
        n.lastSeen = now

        if grade == .again {
            n.wrong += 1
            if n.reps > 0 { n.lapses += 1 }
            n.reps = 0
            n.streak = 0
            n.interval = 0
            n.ease = max(1.3, n.ease - 0.2)
            n.due = now.addingTimeInterval(10 * 60)
            return n
        }

        n.correct += 1
        n.streak += 1
        if s.seen == 0 && grade == .easy { n.firstEasy = true }

        var interval: Int
        switch n.reps {
        case 0:
            interval = grade == .easy ? 4 : 1
        case 1:
            interval = grade == .hard ? 2 : (grade == .good ? 3 : 6)
        default:
            let factor: Double
            switch grade {
            case .hard: factor = 1.2
            case .good: factor = n.ease
            default: factor = n.ease * 1.3
            }
            interval = Int((Double(max(n.interval, 1)) * factor).rounded())
            if grade != .hard { interval = max(interval, n.interval + 1) }
            interval = max(interval, 1)
        }

        switch grade {
        case .hard: n.ease = max(1.3, n.ease - 0.15)
        case .easy: n.ease = min(3.2, n.ease + 0.15)
        default: break
        }

        n.interval = interval
        n.reps += 1
        let startOfToday = Calendar.current.startOfDay(for: now)
        n.due = startOfToday.addingTimeInterval(Double(interval) * day)
        return n
    }

    /// Freies Üben: verändert den Wiederholungsplan nicht, merkt sich aber, was schwerfällt.
    static func practice(_ s: ReviewState, correct: Bool, now: Date = Date()) -> ReviewState {
        var n = s
        n.seen += 1
        n.lastSeen = now
        if correct {
            n.correct += 1
            n.streak += 1
        } else {
            n.wrong += 1
            n.streak = 0
            n.ease = max(1.3, n.ease - 0.1)
            n.due = min(n.due, now)
        }
        return n
    }

    /// Je höher, desto schwerer fällt dir das Wort.
    static func difficulty(_ s: ReviewState) -> Double {
        guard s.seen > 0 else { return 0 }
        let accuracy = Double(s.correct) / Double(s.seen)
        return (1 - accuracy) * 5
            + Double(s.lapses) * 1.5
            + (2.5 - s.ease) * 3
            - Double(min(s.streak, 5)) * 0.4
    }

    static func mastery(_ s: ReviewState) -> Mastery {
        if s.seen == 0 { return .new }
        if difficulty(s) >= 2.5 { return .hard }
        if s.interval >= 21 { return .mastered }
        if s.firstEasy || (s.wrong == 0 && s.seen >= 2) { return .easy }
        return .learning
    }

    static func intervalLabel(_ s: ReviewState, grade: Grade) -> String {
        let n = schedule(s, grade: grade)
        if n.interval == 0 { return "10 Min" }
        if n.interval == 1 { return "1 Tag" }
        if n.interval < 30 { return "\(n.interval) Tage" }
        if n.interval < 365 { return "\(n.interval / 30) Mon." }
        return "\(n.interval / 365) J."
    }
}

/// Vergleicht getippte Antworten tolerant (Groß/Klein, Satzzeichen, Artikel, Sonderzeichen, Tippfehler).
enum AnswerChecker {
    enum Verdict {
        case exact, accentOnly, typo, wrong
        var isCorrect: Bool { self != .wrong }
    }

    static func check(_ input: String, against answer: String, germanAnswer: Bool) -> Verdict {
        let given = normalize(input, german: germanAnswer)
        guard !given.isEmpty else { return .wrong }
        let alternatives = alternativesOf(answer, german: germanAnswer)

        if alternatives.contains(given) { return .exact }
        let foldedGiven = fold(given)
        if alternatives.contains(where: { fold($0) == foldedGiven }) { return .accentOnly }
        for alt in alternatives {
            let a = fold(alt)
            let allowed = a.count >= 9 ? 2 : (a.count >= 4 ? 1 : 0)
            if allowed > 0 && levenshtein(a, foldedGiven) <= allowed { return .typo }
        }
        return .wrong
    }

    static func alternativesOf(_ answer: String, german: Bool) -> [String] {
        let full = normalize(answer, german: german)
        let separators: Set<Character> = german ? ["/", ";", ","] : ["/", ";"]
        let parts = answer.split(whereSeparator: { separators.contains($0) })
            .map { normalize(String($0), german: german) }
            .filter { !$0.isEmpty }
        return Array(Set(parts + [full]))
    }

    static func normalize(_ s: String, german: Bool) -> String {
        var t = s.lowercased()
        // Klammerinhalte entfernen, z. B. "Bitte (Aufforderung)"
        while let open = t.firstIndex(of: "("), let close = t[open...].firstIndex(of: ")") {
            t.removeSubrange(open...close)
        }
        let drop = CharacterSet(charactersIn: "?!.,;:¡¿\"'“”„…")
        t = String(t.unicodeScalars.filter { !drop.contains($0) })
        var words = t.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }).map(String.init)
        if german, words.count > 1, ["der", "die", "das", "ein", "eine", "einen", "sich", "zu"].contains(words[0]) {
            words.removeFirst()
        }
        return words.joined(separator: " ")
    }

    static func fold(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }

    static func levenshtein(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var prev = Array(0...b.count)
        var cur = [Int](repeating: 0, count: b.count + 1)
        for i in 1...a.count {
            cur[0] = i
            for j in 1...b.count {
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1))
            }
            swap(&prev, &cur)
        }
        return prev[b.count]
    }
}
