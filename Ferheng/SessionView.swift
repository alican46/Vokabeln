import SwiftUI

@Observable
final class StudySession: Identifiable {
    let id = UUID()
    let title: String
    var queue: [StudyItem]
    var index = 0
    var practice: Bool
    let quizKind: QuizKind
    let direction: Direction
    var correctCount = 0
    var wrongCount = 0
    var wrongItems: [StudyItem] = []
    private var retries: [String: Int] = [:]

    var currentKind: QuizKind = .flashcard
    var currentDirection: Direction = .kuToDe
    var options: [String] = []

    init(title: String, items: [StudyItem], practice: Bool, quizKind: QuizKind, direction: Direction, store: AppStore) {
        self.title = title
        self.queue = items
        self.practice = practice
        self.quizKind = quizKind
        self.direction = direction
        prepare(store)
    }

    var current: StudyItem? { index < queue.count ? queue[index] : nil }
    var progress: Double { queue.isEmpty ? 1 : Double(index) / Double(queue.count) }

    func prepare(_ store: AppStore) {
        guard let item = current, let card = store.card(item.cardID) else { return }
        if item.form != nil {
            currentDirection = .kuToDe
        } else if direction == .mixed {
            currentDirection = Bool.random() ? .kuToDe : .deToKu
        } else {
            currentDirection = direction
        }

        var kind = quizKind
        if kind == .mixed {
            kind = [QuizKind.flashcard, .multipleChoice, .typing].randomElement() ?? .flashcard
        }
        options = []
        if kind == .multipleChoice {
            let wrong = store.distractors(for: item, card: card, direction: currentDirection, count: 3)
            if wrong.count < 3 {
                kind = .flashcard
            } else {
                options = (wrong + [store.answer(for: item, card: card, direction: currentDirection)]).shuffled()
            }
        }
        currentKind = kind
    }

    func answer(_ grade: Grade, store: AppStore) {
        guard let item = current else { return }
        store.record(item, grade: grade, practice: practice)
        if grade == .again {
            wrongCount += 1
            if !wrongItems.contains(where: { $0.key == item.key }) { wrongItems.append(item) }
            let tries = retries[item.key, default: 0]
            if tries < 2 {
                retries[item.key] = tries + 1
                let position = min(queue.count, index + 4)
                queue.insert(StudyItem(cardID: item.cardID, form: item.form), at: position)
            }
        } else {
            correctCount += 1
        }
        index += 1
        prepare(store)
    }

    func skip(_ store: AppStore) {
        index += 1
        prepare(store)
    }

    func restartWithMistakes(_ store: AppStore) {
        queue = wrongItems.map { StudyItem(cardID: $0.cardID, form: $0.form) }.shuffled()
        wrongItems = []
        retries = [:]
        index = 0
        correctCount = 0
        wrongCount = 0
        practice = true
        prepare(store)
    }
}

struct SessionView: View {
    @Environment(AppStore.self) private var store
    let session: StudySession
    var onClose: () -> Void
    @State private var confirmClose = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            if let item = session.current {
                if let card = store.card(item.cardID) {
                    QuestionView(
                        item: item,
                        card: card,
                        kind: session.currentKind,
                        direction: session.currentDirection,
                        options: session.options,
                        practice: session.practice,
                        reviewState: store.state(item.key)
                    ) { grade in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            session.answer(grade, store: store)
                        }
                    }
                    .id(item.id)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)))
                } else {
                    Color.clear.onAppear { session.skip(store) }
                }
            } else {
                summary
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .confirmationDialog("Sitzung beenden?", isPresented: $confirmClose, titleVisibility: .visible) {
            Button("Beenden", role: .destructive) { onClose() }
            Button("Weiterlernen", role: .cancel) {}
        } message: {
            Text("Dein bisheriger Fortschritt ist bereits gespeichert.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                if session.current != nil && session.index > 0 { confirmClose = true } else { onClose() }
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule().fill(Theme.brandGradient)
                        .frame(width: max(8, geo.size.width * session.progress))
                }
            }
            .frame(height: 10)
            Text("\(min(session.index + 1, session.queue.count))/\(session.queue.count)")
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var summary: some View {
        let total = session.correctCount + session.wrongCount
        let rate = total == 0 ? 1 : Double(session.correctCount) / Double(total)
        return ScrollView {
            VStack(spacing: 22) {
                ZStack {
                    ProgressRing(progress: rate, lineWidth: 14)
                    VStack(spacing: 2) {
                        Text("\(Int(rate * 100))%")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                        Text("richtig").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(width: 160, height: 160)
                .padding(.top, 20)

                Text(rate >= 0.9 ? "Bijî! Super gemacht! 🎉" : rate >= 0.6 ? "Gut gemacht! 💪" : "Dranbleiben – das wird! 🌱")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    statTile("\(session.correctCount)", "richtig", .green)
                    statTile("\(session.wrongCount)", "falsch", Theme.color(.hard))
                    statTile("\(store.streak)", "Tage Serie", .orange)
                }

                if !session.wrongItems.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Diese Wörter üben wir öfter")
                            .font(.headline)
                        ForEach(session.wrongItems) { item in
                            if let card = store.card(item.cardID) {
                                HStack {
                                    Text(item.form.map { "\(card.kurdish) · \($0.label)" } ?? card.kurdish)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(item.form.map { card.form($0) } ?? card.german)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                    Button {
                        withAnimation { session.restartWithMistakes(store) }
                    } label: {
                        Label("Fehler nochmal üben", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(GradientButtonStyle(gradient: Theme.hardGradient))
                }

                Button("Fertig") { onClose() }
                    .buttonStyle(session.wrongItems.isEmpty ? AnyButtonStyle(GradientButtonStyle()) : AnyButtonStyle(SoftButtonStyle()))
            }
            .padding()
        }
        .sensoryFeedback(.success, trigger: session.current == nil)
    }

    private func statTile(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2.bold()).foregroundStyle(color)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle(padding: 14)
    }
}

/// Typ-gelöschter ButtonStyle, um zwischen Stilen umschalten zu können.
struct AnyButtonStyle: ButtonStyle {
    private let make: (Configuration) -> AnyView
    init<S: ButtonStyle>(_ style: S) {
        make = { AnyView(style.makeBody(configuration: $0)) }
    }
    func makeBody(configuration: Configuration) -> some View { make(configuration) }
}

// MARK: - Eine einzelne Frage

struct QuestionView: View {
    @Environment(AppStore.self) private var store
    let item: StudyItem
    let card: Card
    let kind: QuizKind
    let direction: Direction
    let options: [String]
    let practice: Bool
    let reviewState: ReviewState
    let onGrade: (Grade) -> Void

    @State private var revealed = false
    @State private var picked: String?
    @State private var typed = ""
    @State private var verdict: AnswerChecker.Verdict?
    @State private var successTick = 0
    @State private var errorTick = 0
    @FocusState private var typingFocused: Bool

    private var prompt: String { store.prompt(for: item, card: card, direction: direction) }
    private var answer: String { store.answer(for: item, card: card, direction: direction) }
    private var answerIsGerman: Bool { item.form == nil && direction == .kuToDe }
    private var promptIsKurdish: Bool { item.form != nil || direction == .kuToDe }
    private var answered: Bool {
        switch kind {
        case .multipleChoice: return picked != nil
        case .typing: return verdict != nil
        default: return revealed
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                promptCard
                switch kind {
                case .multipleChoice: choices
                case .typing: typingField
                default: EmptyView()
                }
                if answered { details }
            }
            .padding(.horizontal)
            .padding(.top, 6)
            .padding(.bottom, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            bottomBar
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
        }
        .sensoryFeedback(.success, trigger: successTick)
        .sensoryFeedback(.error, trigger: errorTick)
        .onAppear {
            if kind == .typing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { typingFocused = true }
            }
        }
    }

    // MARK: Karte

    private var promptCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                Tag(text: item.form != nil ? "Verbform" : (direction == .kuToDe ? "KU → DE" : "DE → KU"),
                    color: item.form != nil ? .purple : Theme.brand)
                Tag(text: card.type.label)
                if promptIsKurdish && card.gender != .none {
                    Tag(text: card.gender.short, color: card.gender == .f ? .pink : .blue)
                }
                Spacer()
                let m = SRS.mastery(reviewState)
                Tag(text: m.label, color: Theme.color(m))
            }

            Spacer(minLength: 8)

            if let form = item.form {
                Text(form.label)
                    .font(.headline)
                    .foregroundStyle(Theme.verbGradient)
            }
            Text(prompt)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
            if item.form != nil {
                HStack(spacing: 6) {
                    Text(card.german).foregroundStyle(.secondary)
                    if card.transitivity != .unknown { Tag(text: card.transitivity.label, color: .purple) }
                }
                .font(.subheadline)
            }

            if kind == .flashcard || kind == .mixed {
                if revealed {
                    Divider().padding(.vertical, 4)
                    Text(answer)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.brand)
                        .multilineTextAlignment(.center)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("Tippe, um die Antwort zu sehen")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer(minLength: 8)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .cardStyle(padding: 22)
        .contentShape(Rectangle())
        .onTapGesture {
            if kind == .flashcard || kind == .mixed {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { revealed = true }
            }
        }
    }

    // MARK: Auswahl

    private var choices: some View {
        VStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                Button {
                    guard picked == nil else { return }
                    withAnimation(.easeOut(duration: 0.2)) { picked = option }
                    if option == answer { successTick += 1 } else { errorTick += 1 }
                } label: {
                    HStack {
                        Text(option)
                            .font(.body.weight(.medium))
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if picked != nil && option == answer {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        } else if picked == option {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.color(.hard))
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(choiceBackground(option), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(choiceBorder(option), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func choiceBackground(_ option: String) -> Color {
        guard picked != nil else { return Color(.secondarySystemGroupedBackground) }
        if option == answer { return .green.opacity(0.15) }
        if option == picked { return Theme.color(.hard).opacity(0.15) }
        return Color(.secondarySystemGroupedBackground)
    }

    private func choiceBorder(_ option: String) -> Color {
        guard picked != nil else { return .clear }
        if option == answer { return .green }
        if option == picked { return Theme.color(.hard) }
        return .clear
    }

    // MARK: Schreiben

    private var typingField: some View {
        VStack(spacing: 12) {
            TextField(answerIsGerman ? "Auf Deutsch …" : "Auf Kurdisch …", text: $typed)
                .font(.title3)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($typingFocused)
                .onSubmit(check)
                .disabled(verdict != nil)
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(verdictColor ?? .clear, lineWidth: 2)
                )
            if !answerIsGerman && verdict == nil {
                KurdishCharBar(text: $typed)
            }
            if let verdict {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: verdict.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(verdictColor ?? .primary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verdictTitle(verdict)).font(.headline)
                        if verdict != .exact {
                            Text("Richtig: **\(answer)**").font(.subheadline)
                        }
                    }
                    Spacer()
                }
                .padding(14)
                .background((verdictColor ?? .gray).opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var verdictColor: Color? {
        guard let verdict else { return nil }
        switch verdict {
        case .exact, .accentOnly: return .green
        case .typo: return .orange
        case .wrong: return Theme.color(.hard)
        }
    }

    private func verdictTitle(_ v: AnswerChecker.Verdict) -> String {
        switch v {
        case .exact: return "Richtig!"
        case .accentOnly: return "Richtig – achte auf die Sonderzeichen"
        case .typo: return "Fast richtig – kleiner Tippfehler"
        case .wrong: return "Leider falsch"
        }
    }

    private func check() {
        guard verdict == nil else { return }
        let v = AnswerChecker.check(typed, against: answer, germanAnswer: answerIsGerman)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { verdict = v }
        typingFocused = false
        if v.isCorrect { successTick += 1 } else { errorTick += 1 }
    }

    // MARK: Zusatzinfos nach der Antwort

    @ViewBuilder
    private var details: some View {
        let hasVerbForms = card.type == .verb && !card.filledForms.isEmpty
        let hasExtras = hasVerbForms || !card.exampleKu.isEmpty || !card.note.isEmpty || card.gender != .none || !card.plural.isEmpty
        if hasExtras {
            VStack(alignment: .leading, spacing: 12) {
                if item.form == nil && (card.gender != .none || !card.plural.isEmpty) {
                    HStack(spacing: 8) {
                        if card.gender != .none { Tag(text: card.gender.label, color: card.gender == .f ? .pink : .blue) }
                        if !card.plural.isEmpty { Text("Plural: \(card.plural)").font(.subheadline) }
                    }
                }
                if hasVerbForms {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Verbformen").font(.subheadline.bold())
                            if card.transitivity != .unknown { Tag(text: card.transitivity.label, color: .purple) }
                        }
                        ForEach(card.filledForms) { f in
                            HStack {
                                Text(f.label)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 120, alignment: .leading)
                                Text(card.form(f))
                                    .font(.footnote.weight(f == item.form ? .bold : .regular))
                                    .foregroundStyle(f == item.form ? Color.purple : Color.primary)
                            }
                        }
                    }
                }
                if !card.exampleKu.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.exampleKu).font(.subheadline.italic())
                        if !card.exampleDe.isEmpty {
                            Text(card.exampleDe).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                }
                if !card.note.isEmpty {
                    Label(card.note, systemImage: "lightbulb.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
            .transition(.opacity)
        }
    }

    // MARK: Untere Leiste

    @ViewBuilder
    private var bottomBar: some View {
        switch kind {
        case .multipleChoice:
            if let picked {
                Button("Weiter") { onGrade(picked == answer ? .good : .again) }
                    .buttonStyle(GradientButtonStyle())
            } else {
                Button("Weiß ich nicht") {
                    withAnimation { self.picked = "" }
                    errorTick += 1
                }
                .buttonStyle(SoftButtonStyle(tint: .secondary))
            }
        case .typing:
            if let verdict {
                HStack(spacing: 10) {
                    if !verdict.isCorrect {
                        Button("Ich lag richtig") { onGrade(.hard) }
                            .buttonStyle(SoftButtonStyle())
                    }
                    Button("Weiter") { onGrade(grade(for: verdict)) }
                        .buttonStyle(GradientButtonStyle())
                }
            } else {
                HStack(spacing: 10) {
                    Button("Weiß ich nicht") {
                        typed = ""
                        withAnimation { verdict = .wrong }
                        errorTick += 1
                        typingFocused = false
                    }
                    .buttonStyle(SoftButtonStyle(tint: .secondary))
                    Button("Prüfen", action: check)
                        .buttonStyle(GradientButtonStyle())
                        .disabled(typed.trimmed.isEmpty)
                }
            }
        default:
            if revealed {
                if practice {
                    HStack(spacing: 10) {
                        gradeButton(.again, title: "Nicht gewusst", subtitle: nil)
                        gradeButton(.good, title: "Gewusst", subtitle: nil)
                    }
                } else {
                    HStack(spacing: 8) {
                        ForEach(Grade.allCases, id: \.self) { g in
                            gradeButton(g, title: g.label, subtitle: SRS.intervalLabel(reviewState, grade: g))
                        }
                    }
                }
            } else {
                Button("Antwort zeigen") {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { revealed = true }
                }
                .buttonStyle(GradientButtonStyle())
            }
        }
    }

    private func gradeButton(_ grade: Grade, title: String, subtitle: String?) -> some View {
        Button {
            onGrade(grade)
        } label: {
            VStack(spacing: 2) {
                Text(title).font(.subheadline.weight(.bold))
                if let subtitle {
                    Text(subtitle).font(.caption2).opacity(0.85)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.gradeColor(grade), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func grade(for verdict: AnswerChecker.Verdict) -> Grade {
        switch verdict {
        case .exact, .accentOnly: return .good
        case .typo: return .hard
        case .wrong: return .again
        }
    }
}
