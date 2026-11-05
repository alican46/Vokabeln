import SwiftUI

// MARK: - Ordner-Auswahl

struct FolderPicker: View {
    @Environment(AppStore.self) private var store
    let title: String
    @Binding var selection: UUID?

    var body: some View {
        Picker(title, selection: $selection) {
            Text("Bitte wählen").tag(UUID?.none)
            ForEach(store.flatFolders()) { entry in
                Text(String(repeating: "   ", count: entry.depth) + "\(entry.folder.emoji) \(entry.folder.name)")
                    .tag(UUID?.some(entry.folder.id))
            }
        }
    }
}

// MARK: - Wort bearbeiten

struct CardEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let isNew: Bool
    @State private var draft: Card
    @State private var folderSelection: UUID?
    @State private var confirmDelete = false
    @State private var addedCount = 0
    @FocusState private var focus: Field?

    enum Field: Hashable {
        case kurdish, german, plural, exampleKu, exampleDe, note
        case form(VerbForm)
        var isKurdish: Bool {
            switch self {
            case .kurdish, .plural, .exampleKu, .form: return true
            default: return false
            }
        }
    }

    init(card: Card, isNew: Bool) {
        self.isNew = isNew
        _draft = State(initialValue: card)
        _folderSelection = State(initialValue: card.folderID)
    }

    private var canSave: Bool {
        !draft.kurdish.trimmed.isEmpty && !draft.german.trimmed.isEmpty && folderSelection != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Kurdisch", text: $draft.kurdish)
                        .font(.title3.weight(.semibold))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .kurdish)
                    TextField("Deutsch", text: $draft.german)
                        .font(.title3)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .german)
                } footer: {
                    Text("Mehrere Bedeutungen mit „/“ trennen – beim Schreiben zählt dann jede davon als richtig.")
                }

                Section("Wortart") {
                    Picker("Wortart", selection: $draft.type.animation()) {
                        ForEach(WordType.allCases) { t in
                            Label(t.label, systemImage: t.icon).tag(t)
                        }
                    }
                    if draft.type == .noun {
                        Picker("Geschlecht", selection: $draft.gender) {
                            Text("–").tag(Gender.none)
                            Text("m").tag(Gender.m)
                            Text("f").tag(Gender.f)
                        }
                        .pickerStyle(.segmented)
                        TextField("Plural (optional)", text: $draft.plural)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focus, equals: .plural)
                    }
                }

                if draft.type == .verb {
                    Section {
                        Picker("Art", selection: $draft.transitivity) {
                            ForEach(Transitivity.allCases) { t in Text(t.label).tag(t) }
                        }
                        .pickerStyle(.segmented)
                        ForEach(VerbForm.allCases) { f in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(f.label).font(.caption).foregroundStyle(.secondary)
                                TextField(f.hint, text: formBinding(f))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .focused($focus, equals: .form(f))
                            }
                        }
                    } header: {
                        Text("Verbformen")
                    } footer: {
                        Text("Jede ausgefüllte Form wird im Verb-Trainer einzeln abgefragt. Leere Felder werden übersprungen.")
                    }
                }

                Section("Beispielsatz") {
                    TextField("Kurdisch", text: $draft.exampleKu, axis: .vertical)
                        .textInputAutocapitalization(.sentences)
                        .focused($focus, equals: .exampleKu)
                    TextField("Deutsch", text: $draft.exampleDe, axis: .vertical)
                        .focused($focus, equals: .exampleDe)
                }

                Section("Eselsbrücke / Notiz") {
                    TextField("z. B. „av“ klingt wie „Aqua“", text: $draft.note, axis: .vertical)
                        .focused($focus, equals: .note)
                }

                Section("Ordner") {
                    FolderPicker(title: "Ordner", selection: $folderSelection)
                }

                if !isNew {
                    progressSection
                    Section {
                        Button("Wort löschen", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(isNew ? "Neues Wort" : "Wort bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isNew && addedCount > 0 ? "Fertig" : "Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save(andNext: false) }
                        .disabled(!canSave)
                        .fontWeight(.bold)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    if focus?.isKurdish == true {
                        ForEach(["ê", "î", "û", "ç", "ş"], id: \.self) { ch in
                            Button(ch) { append(ch) }
                                .font(.title3)
                        }
                    }
                    Spacer()
                    if isNew {
                        Button("Nächstes") { save(andNext: true) }
                            .disabled(!canSave)
                    }
                }
            }
            .confirmationDialog("Wort löschen?", isPresented: $confirmDelete) {
                Button("Löschen", role: .destructive) {
                    store.deleteCard(draft.id)
                    dismiss()
                }
            }
            .onAppear {
                if isNew { focus = .kurdish }
            }
            .safeAreaInset(edge: .top) {
                if addedCount > 0 {
                    Text("✓ \(addedCount) \(addedCount == 1 ? "Wort" : "Wörter") hinzugefügt")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.green)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var progressSection: some View {
        let s = store.state("c:\(draft.id.uuidString)")
        let m = SRS.mastery(s)
        return Section("Lernstand") {
            HStack {
                Text("Status")
                Spacer()
                Tag(text: m.label, color: Theme.color(m))
            }
            if s.seen > 0 {
                LabeledContent("Abgefragt", value: "\(s.seen)×")
                LabeledContent("Richtig", value: "\(Int(Double(s.correct) / Double(max(1, s.seen)) * 100)) %")
                LabeledContent("Nächste Wiederholung", value: s.due <= Date() ? "jetzt" : s.due.formatted(date: .abbreviated, time: .omitted))
                Button("Lernstand zurücksetzen") { store.resetProgress(for: draft.id) }
            }
        }
    }

    private func formBinding(_ f: VerbForm) -> Binding<String> {
        Binding(
            get: { draft.forms[f.rawValue] ?? "" },
            set: { draft.forms[f.rawValue] = $0 }
        )
    }

    private func append(_ ch: String) {
        switch focus {
        case .kurdish: draft.kurdish += ch
        case .plural: draft.plural += ch
        case .exampleKu: draft.exampleKu += ch
        case .form(let f): draft.forms[f.rawValue, default: ""] += ch
        default: break
        }
    }

    private func save(andNext: Bool) {
        guard canSave, let folderID = folderSelection else { return }
        var card = draft
        card.folderID = folderID
        card.kurdish = card.kurdish.trimmed
        card.german = card.german.trimmed
        if card.type != .verb { card.forms = [:]; card.transitivity = .unknown }
        if card.type != .noun { card.gender = .none; card.plural = "" }
        store.upsert(card)
        if andNext {
            addedCount += 1
            draft = Card(folderID: folderID, kurdish: "", german: "", type: card.type)
            focus = .kurdish
        } else {
            dismiss()
        }
    }
}

// MARK: - Ordner bearbeiten

struct FolderEditorView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let folder: Folder?
    let parentID: UUID?
    @State private var name = ""
    @State private var emoji = "📁"
    @State private var colorName = "teal"

    private let emojis = ["📁", "👋", "🔢", "👨‍👩‍👧", "🏠", "⚡️", "🍎", "🍞", "🎨", "🐑", "🌄", "☀️",
                          "🗣️", "📚", "✈️", "💼", "🩺", "🎵", "⚽️", "❤️", "🕰️", "🌦️", "👕", "🚗"]

    init(folder: Folder?, parentID: UUID?) {
        self.folder = folder
        self.parentID = parentID
        _name = State(initialValue: folder?.name ?? "")
        _emoji = State(initialValue: folder?.emoji ?? "📁")
        _colorName = State(initialValue: folder?.colorName ?? "teal")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        FolderIcon(folder: Folder(name: name, emoji: emoji, colorName: colorName), size: 84)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                Section("Name") {
                    TextField("z. B. Essen & Trinken", text: $name)
                        .font(.title3)
                }
                if let parent = store.folder(parentID) {
                    Section("Liegt in") {
                        Text("\(parent.emoji) \(parent.name)")
                    }
                }
                Section("Symbol") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(emojis, id: \.self) { e in
                            Text(e)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(emoji == e ? Theme.color(colorName).opacity(0.25) : .clear,
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .onTapGesture { emoji = e }
                        }
                    }
                    .padding(.vertical, 4)
                    TextField("Eigenes Emoji", text: $emoji)
                }
                Section("Farbe") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(Theme.colorNames, id: \.self) { c in
                            Circle()
                                .fill(Theme.color(c))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .opacity(colorName == c ? 1 : 0)
                                )
                                .onTapGesture { colorName = c }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(folder == nil ? "Neuer Ordner" : "Ordner bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichern") { save() }
                        .disabled(name.trimmed.isEmpty)
                        .fontWeight(.bold)
                }
            }
        }
    }

    private func save() {
        let e = String(emoji.trimmed.prefix(1)).isEmpty ? "📁" : String(emoji.trimmed.prefix(1))
        if var f = folder {
            f.name = name.trimmed
            f.emoji = e
            f.colorName = colorName
            store.updateFolder(f)
        } else {
            store.addFolder(name: name.trimmed, emoji: e, colorName: colorName, parentID: parentID)
        }
        dismiss()
    }
}

// MARK: - Mehrere Wörter einfügen

struct BulkAddView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var folderID: UUID?
    @State private var type: WordType = .other
    @State private var text = ""
    @State private var result: Int?

    init(folderID: UUID?) {
        _folderID = State(initialValue: folderID)
    }

    private var parsedCount: Int {
        text.components(separatedBy: .newlines).filter { AppStore.splitLine($0.trimmed) != nil }.count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ziel") {
                    FolderPicker(title: "Ordner", selection: $folderID)
                    Picker("Wortart", selection: $type) {
                        ForEach(WordType.allCases) { Text($0.label).tag($0) }
                    }
                }
                Section {
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("av = Wasser\nnan = Brot\nmal = Haus")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        TextEditor(text: $text)
                            .frame(minHeight: 220)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    KurdishCharBar(text: $text)
                        .padding(.vertical, 4)
                } header: {
                    Text("Ein Wort pro Zeile")
                } footer: {
                    Text("Format: Kurdisch = Deutsch. Auch „;“, „-“ oder Tabulator funktionieren – praktisch zum Einfügen aus Excel oder Notizen.")
                }
            }
            .navigationTitle("Mehrere Wörter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("\(parsedCount) hinzufügen") {
                        guard let id = folderID else { return }
                        _ = store.bulkAdd(text: text, folderID: id, type: type)
                        dismiss()
                    }
                    .disabled(folderID == nil || parsedCount == 0)
                    .fontWeight(.bold)
                }
            }
        }
    }
}

// MARK: - Ordner zusammenfügen

struct MergeFoldersView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let parentID: UUID?
    @State private var selected: Set<UUID>
    @State private var name = ""
    @State private var emoji = "🗂️"
    @State private var mode: MergeMode = .link

    init(parentID: UUID?, preselected: Set<UUID>) {
        self.parentID = parentID
        _selected = State(initialValue: preselected)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(store.flatFolders()) { entry in
                        Button {
                            if selected.contains(entry.id) { selected.remove(entry.id) } else { selected.insert(entry.id) }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: selected.contains(entry.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selected.contains(entry.id) ? Theme.brand : Color(.tertiaryLabel))
                                Text(entry.folder.emoji)
                                Text(entry.folder.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("\(store.allCards(in: entry.id).count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, CGFloat(entry.depth) * 18)
                        }
                    }
                } header: {
                    Text("Ordner auswählen (\(selected.count))")
                }

                Section("Neuer Ordner") {
                    HStack {
                        TextField("🗂️", text: $emoji)
                            .frame(width: 44)
                        TextField("Name, z. B. „Prüfung Mai“", text: $name)
                    }
                }

                Section {
                    Picker("Art", selection: $mode) {
                        ForEach(MergeMode.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(mode.explanation)
                }
            }
            .navigationTitle("Zusammenfügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        let ordered = store.flatFolders().map(\.id).filter { selected.contains($0) }
                        store.merge(ordered, name: name.trimmed, emoji: String(emoji.trimmed.prefix(1)),
                                    colorName: "indigo", parentID: parentID, mode: mode)
                        dismiss()
                    }
                    .disabled(selected.count < 2 || name.trimmed.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
