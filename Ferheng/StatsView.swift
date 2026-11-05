import SwiftUI
import Charts

struct StatsView: View {
    @Environment(AppStore.self) private var store

    private struct DayPoint: Identifiable {
        let id = UUID()
        let date: Date
        let kind: String
        let count: Int
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    overview
                    activityChart
                    masteryCard
                    wordList(title: "Fällt dir schwer", icon: "flame.fill", color: Theme.color(.hard), items: hardest)
                    wordList(title: "Sofort gewusst", icon: "bolt.heart.fill", color: .blue, items: easiest)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistik")
        }
    }

    private var totals: (reviews: Int, correct: Int) {
        var reviews = 0
        var correct = 0
        for stat in store.log.values {
            reviews += stat.reviews
            correct += stat.correct
        }
        return (reviews: reviews, correct: correct)
    }

    private var overview: some View {
        let t = totals
        let accuracy = t.reviews == 0 ? 0 : Int(Double(t.correct) / Double(t.reviews) * 100)
        let tomorrow = Calendar.current.startOfDay(for: Date()).addingTimeInterval(2 * SRS.day)
        let dueTomorrow = store.vocabItems(store.cards).filter {
            let s = store.state($0.key)
            return s.seen > 0 && s.due < tomorrow
        }.count
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            tile("\(store.streak)", "Tage in Folge", "flame.fill", .orange)
            tile("\(store.cards.count)", "Wörter gesamt", "character.book.closed.fill", Theme.brand)
            tile("\(t.reviews)", "Abfragen gesamt", "checkmark.circle.fill", .blue)
            tile("\(accuracy) %", "Trefferquote", "target", .green)
            tile("\(store.todayStat.reviews)", "Heute geübt", "sun.max.fill", Theme.sun)
            tile("\(dueTomorrow)", "Fällig bis morgen", "calendar", .purple)
        }
    }

    private func tile(_ value: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.headline)
            Text(value)
                .font(.title2.bold())
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 14)
    }

    private var activityChart: some View {
        let points: [DayPoint] = (0..<14).reversed().flatMap { offset -> [DayPoint] in
            let date = Calendar.current.startOfDay(for: Day.date(daysAgo: offset))
            let stat = store.log[Day.key(date)] ?? DayStat()
            return [
                DayPoint(date: date, kind: "Richtig", count: stat.correct),
                DayPoint(date: date, kind: "Falsch", count: stat.reviews - stat.correct)
            ]
        }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Letzte 14 Tage").font(.headline)
            Chart(points) { p in
                BarMark(
                    x: .value("Tag", p.date, unit: .day),
                    y: .value("Abfragen", p.count)
                )
                .foregroundStyle(by: .value("Ergebnis", p.kind))
                .cornerRadius(4)
            }
            .chartForegroundStyleScale(["Richtig": Theme.brand, "Falsch": Theme.color(.hard)])
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(.defaultDigits))
                }
            }
            .frame(height: 180)
        }
        .cardStyle()
    }

    private var masteryCard: some View {
        let counts = store.masteryCounts(store.cards)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Wie gut sitzen deine Wörter?").font(.headline)
            if store.cards.isEmpty {
                Text("Noch keine Wörter vorhanden.").foregroundStyle(.secondary)
            } else {
                Chart(Mastery.allCases) { m in
                    SectorMark(
                        angle: .value("Anzahl", counts[m] ?? 0),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .foregroundStyle(Theme.color(m))
                    .cornerRadius(4)
                }
                .frame(height: 170)
                .overlay {
                    VStack(spacing: 0) {
                        let learned = (counts[.mastered] ?? 0) + (counts[.easy] ?? 0)
                        Text("\(learned)").font(.title.bold())
                        Text("sitzen gut").font(.caption).foregroundStyle(.secondary)
                    }
                }
                MasteryLegend(counts: counts)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var hardest: [StudyItem] {
        store.hardItems(in: store.cards)
            .sorted { SRS.difficulty(store.state($0.key)) > SRS.difficulty(store.state($1.key)) }
            .prefix(10)
            .map { $0 }
    }

    private var easiest: [StudyItem] {
        store.vocabItems(store.cards)
            .filter { let s = store.state($0.key); return s.seen > 0 && (s.firstEasy || (s.wrong == 0 && s.seen >= 2)) }
            .sorted { store.state($0.key).seen > store.state($1.key).seen }
            .prefix(10)
            .map { $0 }
    }

    @ViewBuilder
    private func wordList(title: String, icon: String, color: Color, items: [StudyItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(color)
                ForEach(items) { item in
                    if let card = store.card(item.cardID) {
                        let s = store.state(item.key)
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.form.map { "\(card.kurdish) · \($0.label)" } ?? card.kurdish)
                                    .font(.subheadline.weight(.semibold))
                                Text(item.form.map { card.form($0) } ?? card.german)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(s.correct)/\(s.seen)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        if item.id != items.last?.id { Divider() }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }
}
