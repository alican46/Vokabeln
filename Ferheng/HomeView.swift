import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @State private var session: StudySession?
    @State private var setup: LearnSetupRequest?
    @State private var emptyAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    goalCard
                    learnButtons
                    if let card = wordOfTheDay { wordOfDayCard(card) }
                    hardWordsCard
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(greeting)
        }
        .fullScreenCover(item: $session) { s in
            SessionView(session: s) { session = nil }
        }
        .sheet(item: $setup) { req in
            LearnSetupView(request: req)
        }
        .alert("Gerade nichts fällig 🎉", isPresented: $emptyAlert) {
            Button("Freies Üben") { start(mode: .practice) }
            Button("Später", role: .cancel) {}
        } message: {
            Text("Du hast alle fälligen Wörter wiederholt und dein Limit für neue Wörter erreicht. Möchtest du trotzdem üben?")
        }
    }

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 11 { return "Rojbaş ☀️" }
        if h < 18 { return "Silav 👋" }
        return "Êvarbaş 🌙"
    }

    private var goalCard: some View {
        let today = store.todayStat
        let goal = max(1, store.settings.dailyGoal)
        let progress = Double(today.reviews) / Double(goal)
        let due = store.dueCount(in: store.cards)
        return HStack(spacing: 20) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: 12)
                VStack(spacing: 0) {
                    Text("\(today.reviews)")
                        .font(.title.bold())
                        .contentTransition(.numericText())
                    Text("von \(goal)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)

            VStack(alignment: .leading, spacing: 10) {
                Text(progress >= 1 ? "Tagesziel erreicht! 🎉" : "Tagesziel")
                    .font(.headline)
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill").foregroundStyle(Theme.sunGradient)
                    Text("\(store.streak) \(store.streak == 1 ? "Tag" : "Tage") in Folge")
                        .font(.subheadline.weight(.medium))
                }
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath").foregroundStyle(Theme.brand)
                    Text("\(due) fällig · \(store.newCount(in: store.cards)) neu")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .cardStyle(padding: 20)
    }

    private var learnButtons: some View {
        VStack(spacing: 12) {
            Button {
                start(mode: .smart)
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Jetzt lernen")
                    Spacer()
                    let due = store.dueCount(in: store.cards)
                    if due > 0 {
                        Text("\(due)")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(.white.opacity(0.25), in: Capsule())
                    }
                }
                .padding(.horizontal, 20)
            }
            .buttonStyle(GradientButtonStyle())

            HStack(spacing: 12) {
                quickTile("Schwierige\nWörter", icon: "flame.fill", gradient: Theme.hardGradient, count: store.hardItems(in: store.cards).count) {
                    start(mode: .hard)
                }
                quickTile("Verb-\nTrainer", icon: "bolt.fill", gradient: Theme.verbGradient, count: store.verbItems(store.cards).count) {
                    start(mode: .verbs)
                }
                quickTile("Optionen\nwählen", icon: "slider.horizontal.3", gradient: Theme.sunGradient, count: nil) {
                    setup = LearnSetupRequest(title: "Alle Wörter", folderID: nil)
                }
            }
        }
    }

    private func quickTile(_ title: String, icon: String, gradient: LinearGradient, count: Int?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Spacer()
                    if let count {
                        Text("\(count)").font(.subheadline.bold()).foregroundStyle(.secondary)
                    }
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .cardStyle(padding: 14)
        }
        .buttonStyle(.plain)
    }

    private var wordOfTheDay: Card? {
        guard !store.cards.isEmpty else { return nil }
        let dayNumber = Int(Date().timeIntervalSince1970 / 86_400)
        let sorted = store.cards.sorted { $0.createdAt < $1.createdAt }
        return sorted[dayNumber % sorted.count]
    }

    private func wordOfDayCard(_ card: Card) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Wort des Tages", systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Text(card.type.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            Text(card.kurdish)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(card.german)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
            if !card.exampleKu.isEmpty {
                Text("„\(card.exampleKu)“ – \(card.exampleDe)")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Theme.brandGradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 90))
                .foregroundStyle(.white.opacity(0.1))
                .offset(x: 10, y: -10)
                .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var hardWordsCard: some View {
        let hard = store.hardItems(in: store.cards)
            .sorted { SRS.difficulty(store.state($0.key)) > SRS.difficulty(store.state($1.key)) }
            .prefix(5)
        return Group {
            if !hard.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fällt dir noch schwer")
                        .font(.headline)
                    ForEach(Array(hard)) { item in
                        if let card = store.card(item.cardID) {
                            HStack {
                                Circle().fill(Theme.color(.hard)).frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.form.map { "\(card.kurdish) · \($0.label)" } ?? card.kurdish)
                                        .font(.subheadline.weight(.semibold))
                                    Text(item.form.map { card.form($0) } ?? card.german)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                let s = store.state(item.key)
                                Text("\(s.wrong)× falsch")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
        }
    }

    private func start(mode: LearnMode) {
        let items = store.buildSession(scope: store.cards, mode: mode, size: store.settings.sessionSize)
        guard !items.isEmpty else {
            if mode == .smart && !store.cards.isEmpty { emptyAlert = true }
            return
        }
        session = StudySession(
            title: mode.label,
            items: items,
            practice: mode == .practice || mode == .hard,
            quizKind: store.settings.quizKind,
            direction: mode == .verbs ? .kuToDe : store.settings.direction,
            store: store
        )
    }
}
