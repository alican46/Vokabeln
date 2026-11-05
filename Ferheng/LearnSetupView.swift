import SwiftUI

struct LearnSetupRequest: Identifiable {
    let id = UUID()
    let title: String
    let folderID: UUID?
}

struct LearnSetupView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let request: LearnSetupRequest

    @State private var mode: LearnMode = .smart
    @State private var quizKind: QuizKind = .mixed
    @State private var direction: Direction = .mixed
    @State private var size: Int = 20
    @State private var session: StudySession?
    @State private var loaded = false

    private var scope: [Card] {
        if let id = request.folderID { return store.allCards(in: id) }
        return store.cards
    }

    private func available(_ m: LearnMode) -> Int {
        switch m {
        case .smart:
            let fresh = min(store.newCount(in: scope), max(0, store.settings.newPerDay - store.todayStat.newCards))
            return store.dueCount(in: scope) + fresh
        case .hard: return store.hardItems(in: scope).count
        case .practice: return scope.count
        case .verbs: return store.verbItems(scope).count
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    section("Was möchtest du lernen?") {
                        VStack(spacing: 10) {
                            ForEach(LearnMode.allCases) { m in modeRow(m) }
                        }
                    }

                    section("Abfrageart") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(QuizKind.allCases) { k in
                                Button {
                                    quizKind = k
                                } label: {
                                    Label(k.label, systemImage: k.icon)
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .foregroundStyle(quizKind == k ? Color.white : Color.primary)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(quizKind == k ? AnyShapeStyle(Theme.brandGradient) : AnyShapeStyle(Color(.secondarySystemGroupedBackground)))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if mode != .verbs {
                        section("Richtung") {
                            Picker("Richtung", selection: $direction) {
                                Text("KU → DE").tag(Direction.kuToDe)
                                Text("DE → KU").tag(Direction.deToKu)
                                Text("Gemischt").tag(Direction.mixed)
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    section("Anzahl") {
                        Stepper(value: $size, in: 5...100, step: 5) {
                            Text("\(size) Abfragen").font(.body.weight(.medium))
                        }
                        .padding(14)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                Button {
                    start()
                } label: {
                    Label(available(mode) == 0 ? "Nichts zu lernen" : "Los geht's", systemImage: "play.fill")
                }
                .buttonStyle(GradientButtonStyle(gradient: mode == .verbs ? Theme.verbGradient : mode == .hard ? Theme.hardGradient : Theme.brandGradient))
                .disabled(available(mode) == 0)
                .opacity(available(mode) == 0 ? 0.5 : 1)
                .padding()
                .background(.bar)
            }
            .navigationTitle(request.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                quizKind = store.settings.quizKind
                direction = store.settings.direction
                size = store.settings.sessionSize
            }
        }
        .fullScreenCover(item: $session) { s in
            SessionView(session: s) { session = nil }
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
    }

    private func modeRow(_ m: LearnMode) -> some View {
        let selected = mode == m
        let gradient: LinearGradient = m == .verbs ? Theme.verbGradient : m == .hard ? Theme.hardGradient : m == .practice ? Theme.sunGradient : Theme.brandGradient
        return Button {
            withAnimation(.easeOut(duration: 0.15)) { mode = m }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: m.icon)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(m.label).font(.body.weight(.semibold))
                    Text(m.subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(available(m))")
                    .font(.subheadline.bold())
                    .foregroundStyle(.secondary)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? Theme.brand : Color(.tertiaryLabel))
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? Theme.brand : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func start() {
        store.settings.quizKind = quizKind
        store.settings.direction = direction
        store.settings.sessionSize = size
        store.save()
        let items = store.buildSession(scope: scope, mode: mode, size: size)
        guard !items.isEmpty else { return }
        session = StudySession(
            title: mode.label,
            items: items,
            practice: mode == .practice || mode == .hard,
            quizKind: quizKind,
            direction: mode == .verbs ? .kuToDe : direction,
            store: store
        )
    }
}
