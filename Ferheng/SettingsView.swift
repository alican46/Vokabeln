import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var exportURL: URL?
    @State private var importing = false
    @State private var message: String?
    @State private var confirmReset = false
    @State private var confirmStarter = false

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $store.settings.dailyGoal, in: 5...300, step: 5) {
                        LabeledContent("Tagesziel", value: "\(store.settings.dailyGoal) Abfragen")
                    }
                    Stepper(value: $store.settings.newPerDay, in: 0...100, step: 5) {
                        LabeledContent("Neue Wörter pro Tag", value: "\(store.settings.newPerDay)")
                    }
                    Stepper(value: $store.settings.sessionSize, in: 5...100, step: 5) {
                        LabeledContent("Abfragen pro Runde", value: "\(store.settings.sessionSize)")
                    }
                } header: {
                    Text("Lernziele")
                } footer: {
                    Text("Weniger neue Wörter pro Tag = weniger Stress bei den Wiederholungen. 10 ist ein guter Startwert.")
                }

                Section("Standard beim Lernen") {
                    Picker("Abfrageart", selection: $store.settings.quizKind) {
                        ForEach(QuizKind.allCases) { Text($0.label).tag($0) }
                    }
                    Picker("Richtung", selection: $store.settings.direction) {
                        ForEach(Direction.allCases) { Text($0.label).tag($0) }
                    }
                }

                Section {
                    Button {
                        exportURL = store.exportBackup()
                        if exportURL == nil { message = "Backup konnte nicht erstellt werden." }
                    } label: {
                        Label("Backup erstellen", systemImage: "square.and.arrow.up")
                    }
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Label("Backup-Datei teilen / sichern", systemImage: "doc.badge.arrow.up")
                        }
                    }
                    Button {
                        importing = true
                    } label: {
                        Label("Backup wiederherstellen", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Daten")
                } footer: {
                    Text("Deine Daten liegen nur auf diesem iPhone. Sichere ab und zu ein Backup, z. B. in iCloud Drive über „Teilen → In Dateien sichern“.")
                }

                Section {
                    Button {
                        confirmStarter = true
                    } label: {
                        Label("Beispielvokabeln hinzufügen", systemImage: "sparkles")
                    }
                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        Label("Alle Daten löschen", systemImage: "trash")
                    }
                }

                Section {
                    LabeledContent("App", value: "Ferheng 1.0")
                    LabeledContent("Sprache", value: "Kurmancî ↔ Deutsch")
                } footer: {
                    Text("„Ferheng“ heißt auf Kurdisch „Wörterbuch“.")
                }
            }
            .navigationTitle("Mehr")
            .onChange(of: store.settings) { _, _ in store.save() }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    do {
                        try store.importBackup(from: url)
                        message = "Backup wiederhergestellt ✓"
                    } catch {
                        message = "Die Datei konnte nicht gelesen werden."
                    }
                case .failure:
                    message = "Import abgebrochen."
                }
            }
            .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) {}
            }
            .confirmationDialog("Beispielvokabeln hinzufügen?", isPresented: $confirmStarter, titleVisibility: .visible) {
                Button("Hinzufügen") { store.loadStarterPack() }
            } message: {
                Text("Es wird ein Ordner „Kurmancî Grundlagen“ mit Unterordnern angelegt.")
            }
            .confirmationDialog("Wirklich alles löschen?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Alles löschen", role: .destructive) { store.resetAll() }
            } message: {
                Text("Alle Ordner, Wörter und dein Lernfortschritt werden gelöscht. Das kann nicht rückgängig gemacht werden.")
            }
        }
    }
}
