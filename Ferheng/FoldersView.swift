import SwiftUI

enum FolderSheet: Identifiable {
    case newFolder(parent: UUID?)
    case editFolder(Folder)
    case newCard(folderID: UUID)
    case editCard(Card)
    case bulk(folderID: UUID?)
    case merge(parent: UUID?, preselected: Set<UUID>)
    case learn(LearnSetupRequest)

    var id: String {
        switch self {
        case .newFolder(let p): return "newFolder-\(p?.uuidString ?? "root")"
        case .editFolder(let f): return "editFolder-\(f.id)"
        case .newCard(let id): return "newCard-\(id)"
        case .editCard(let c): return "editCard-\(c.id)"
        case .bulk(let id): return "bulk-\(id?.uuidString ?? "none")"
        case .merge(let p, _): return "merge-\(p?.uuidString ?? "root")"
        case .learn(let r): return "learn-\(r.id)"
        }
    }
}

extension View {
    func folderSheets(_ sheet: Binding<FolderSheet?>) -> some View {
        self.sheet(item: sheet) { s in
            switch s {
            case .newFolder(let parent):
                FolderEditorView(folder: nil, parentID: parent)
            case .editFolder(let folder):
                FolderEditorView(folder: folder, parentID: folder.parentID)
            case .newCard(let folderID):
                CardEditorView(card: Card(folderID: folderID, kurdish: "", german: ""), isNew: true)
            case .editCard(let card):
                CardEditorView(card: card, isNew: false)
            case .bulk(let folderID):
                BulkAddView(folderID: folderID)
            case .merge(let parent, let preselected):
                MergeFoldersView(parentID: parent, preselected: preselected)
            case .learn(let request):
                LearnSetupView(request: request)
            }
        }
    }
}

// MARK: - Ordner-Übersicht

struct FoldersView: View {
    @Environment(AppStore.self) private var store
    @State private var sheet: FolderSheet?
    @State private var search = ""
    @State private var pendingDelete: Folder?

    var body: some View {
        NavigationStack {
            List {
                if search.trimmed.isEmpty {
                    let roots = store.children(of: nil)
                    if roots.isEmpty {
                        ContentUnavailableView {
                            Label("Noch keine Ordner", systemImage: "folder.badge.plus")
                        } description: {
                            Text("Erstelle deinen ersten Ordner, z. B. „Essen“ oder „Verben“.")
                        } actions: {
                            Button("Ordner erstellen") { sheet = .newFolder(parent: nil) }
                                .buttonStyle(.borderedProminent)
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        Section {
                            ForEach(roots) { folder in
                                NavigationLink(value: folder.id) {
                                    FolderRow(folder: folder)
                                }
                                .swipeActions {
                                    Button(role: .destructive) { pendingDelete = folder } label: {
                                        Label("Löschen", systemImage: "trash")
                                    }
                                    Button { sheet = .editFolder(folder) } label: {
                                        Label("Bearbeiten", systemImage: "pencil")
                                    }
                                    .tint(.orange)
                                }
                            }
                        } footer: {
                            Text("Tipp: Über ＋ → „Ordner zusammenfügen“ kannst du aus mehreren Ordnern einen neuen machen.")
                        }
                    }
                } else {
                    SearchResults(query: search) { sheet = .editCard($0) }
                }
            }
            .navigationTitle("Ordner")
            .searchable(text: $search, prompt: "Wörter suchen (Kurdisch oder Deutsch)")
            .navigationDestination(for: UUID.self) { id in
                FolderDetailView(folderID: id)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { sheet = .newFolder(parent: nil) } label: {
                            Label("Neuer Ordner", systemImage: "folder.badge.plus")
                        }
                        Button { sheet = .merge(parent: nil, preselected: []) } label: {
                            Label("Ordner zusammenfügen", systemImage: "square.stack.3d.up")
                        }
                        .disabled(store.folders.count < 2)
                        Button { sheet = .bulk(folderID: nil) } label: {
                            Label("Mehrere Wörter einfügen", systemImage: "text.badge.plus")
                        }
                        .disabled(store.folders.isEmpty)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .folderSheets($sheet)
            .deleteFolderDialog($pendingDelete)
        }
    }
}

struct SearchResults: View {
    @Environment(AppStore.self) private var store
    let query: String
    let onSelect: (Card) -> Void

    var body: some View {
        let q = AnswerChecker.fold(query.trimmed)
        let results = store.cards.filter {
            AnswerChecker.fold($0.kurdish).contains(q) || AnswerChecker.fold($0.german).contains(q)
        }
        if results.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            Section("\(results.count) Treffer") {
                ForEach(results) { card in
                    Button { onSelect(card) } label: {
                        CardRow(card: card, showFolder: true)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

extension View {
    func deleteFolderDialog(_ folder: Binding<Folder?>, onDeleted: @escaping () -> Void = {}) -> some View {
        modifier(DeleteFolderDialog(folder: folder, onDeleted: onDeleted))
    }
}

struct DeleteFolderDialog: ViewModifier {
    @Environment(AppStore.self) private var store
    @Binding var folder: Folder?
    let onDeleted: () -> Void

    func body(content: Content) -> some View {
        content.confirmationDialog(
            "„\(folder?.name ?? "")“ löschen?",
            isPresented: Binding(get: { folder != nil }, set: { if !$0 { folder = nil } }),
            titleVisibility: .visible
        ) {
            Button("Ordner & Inhalt löschen", role: .destructive) {
                if let f = folder {
                    store.deleteFolder(f.id)
                    onDeleted()
                }
                folder = nil
            }
            Button("Abbrechen", role: .cancel) { folder = nil }
        } message: {
            Text("Alle Wörter und Unterordner darin werden ebenfalls gelöscht.")
        }
    }
}

// MARK: - Zeilen

struct FolderRow: View {
    @Environment(AppStore.self) private var store
    let folder: Folder

    var body: some View {
        let all = store.allCards(in: folder.id)
        let subCount = store.children(of: folder.id).count
        let due = store.dueCount(in: all)
        HStack(spacing: 14) {
            FolderIcon(folder: folder)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(folder.name).font(.body.weight(.semibold)).lineLimit(1)
                    Spacer()
                    if due > 0 {
                        Text("\(due) fällig")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Theme.brand, in: Capsule())
                    }
                }
                Text(subtitle(words: all.count, subfolders: subCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !all.isEmpty {
                    MasteryBar(counts: store.masteryCounts(all), height: 5)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func subtitle(words: Int, subfolders: Int) -> String {
        var parts = ["\(words) \(words == 1 ? "Wort" : "Wörter")"]
        if subfolders > 0 { parts.append("\(subfolders) \(subfolders == 1 ? "Unterordner" : "Unterordner")") }
        if !folder.linkedIDs.isEmpty { parts.append("Sammlung aus \(folder.linkedIDs.count)") }
        return parts.joined(separator: " · ")
    }
}

struct CardRow: View {
    @Environment(AppStore.self) private var store
    let card: Card
    var showFolder = false

    var body: some View {
        let mastery = store.mastery(of: card)
        HStack(spacing: 12) {
            Circle()
                .fill(Theme.color(mastery))
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(card.kurdish).font(.body.weight(.semibold))
                    if card.gender != .none {
                        Text(card.gender.short)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(card.gender == .f ? Color.pink : Color.blue)
                    }
                }
                Text(card.german)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if showFolder, let f = store.folder(card.folderID) {
                    Text("\(f.emoji) \(f.name)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            if card.type == .verb && !card.filledForms.isEmpty {
                Tag(text: "\(card.filledForms.count) Formen", color: .purple)
            } else {
                Image(systemName: card.type.icon)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Ordner-Detail

struct FolderDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let folderID: UUID
    @State private var sheet: FolderSheet?
    @State private var pendingDelete: Folder?

    var body: some View {
        Group {
            if let folder = store.folder(folderID) {
                content(folder)
            } else {
                ContentUnavailableView("Ordner nicht gefunden", systemImage: "folder")
            }
        }
        .folderSheets($sheet)
        .deleteFolderDialog($pendingDelete) { dismiss() }
    }

    private func content(_ folder: Folder) -> some View {
        let all = store.allCards(in: folder.id)
        let direct = store.directCards(in: folder.id)
        let subfolders = store.children(of: folder.id)
        let linked = folder.linkedIDs.compactMap { store.folder($0) }

        return List {
            Section {
                header(folder, all: all)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if !subfolders.isEmpty {
                Section("Unterordner") {
                    ForEach(subfolders) { sub in
                        NavigationLink(value: sub.id) { FolderRow(folder: sub) }
                            .swipeActions {
                                Button(role: .destructive) { pendingDelete = sub } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                    }
                }
            }

            if !linked.isEmpty {
                Section {
                    ForEach(linked) { l in
                        NavigationLink(value: l.id) { FolderRow(folder: l) }
                            .swipeActions {
                                Button { store.unlink(l.id, from: folder.id) } label: {
                                    Label("Lösen", systemImage: "link.badge.plus")
                                }
                                .tint(.orange)
                            }
                    }
                } header: {
                    Text("Verknüpfte Ordner")
                } footer: {
                    Text("Die Wörter dieser Ordner gehören auch zu dieser Sammlung. Der Lernfortschritt ist geteilt.")
                }
            }

            Section {
                if direct.isEmpty {
                    Button {
                        sheet = .newCard(folderID: folder.id)
                    } label: {
                        Label("Erstes Wort hinzufügen", systemImage: "plus")
                    }
                } else {
                    ForEach(direct) { card in
                        Button { sheet = .editCard(card) } label: { CardRow(card: card) }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button(role: .destructive) { store.deleteCard(card.id) } label: {
                                    Label("Löschen", systemImage: "trash")
                                }
                            }
                    }
                }
            } header: {
                Text("Wörter in diesem Ordner (\(direct.count))")
            } footer: {
                if all.count > direct.count {
                    Text("+ \(all.count - direct.count) weitere Wörter aus Unter- und verknüpften Ordnern werden beim Lernen mit abgefragt.")
                }
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button { sheet = .newCard(folderID: folder.id) } label: {
                        Label("Wort hinzufügen", systemImage: "plus")
                    }
                    Button { sheet = .bulk(folderID: folder.id) } label: {
                        Label("Mehrere Wörter einfügen", systemImage: "text.badge.plus")
                    }
                    Button { sheet = .newFolder(parent: folder.id) } label: {
                        Label("Unterordner erstellen", systemImage: "folder.badge.plus")
                    }
                    Divider()
                    Button { sheet = .editFolder(folder) } label: {
                        Label("Ordner bearbeiten", systemImage: "pencil")
                    }
                    Button { sheet = .merge(parent: folder.parentID, preselected: [folder.id]) } label: {
                        Label("Mit anderen zusammenfügen", systemImage: "square.stack.3d.up")
                    }
                    Divider()
                    Button(role: .destructive) { pendingDelete = folder } label: {
                        Label("Ordner löschen", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private func header(_ folder: Folder, all: [Card]) -> some View {
        let counts = store.masteryCounts(all)
        let path = store.path(to: folder.id).dropLast()
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                FolderIcon(folder: folder, size: 60)
                VStack(alignment: .leading, spacing: 4) {
                    if !path.isEmpty {
                        Text(path.map(\.name).joined(separator: " › "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Text(folder.name).font(.title2.bold())
                    Text("\(all.count) Wörter · \(store.dueCount(in: all)) fällig")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if !all.isEmpty {
                MasteryBar(counts: counts, height: 10)
                MasteryLegend(counts: counts)
            }
            HStack(spacing: 10) {
                Button {
                    sheet = .learn(LearnSetupRequest(title: folder.name, folderID: folder.id))
                } label: {
                    Label("Lernen", systemImage: "play.fill")
                }
                .buttonStyle(GradientButtonStyle())
                .disabled(all.isEmpty)

                Button {
                    sheet = .newCard(folderID: folder.id)
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 54, height: 54)
                        .background(Theme.brand.opacity(0.13), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.brand)
            }
        }
        .cardStyle(padding: 18)
        .padding(.vertical, 6)
    }
}
