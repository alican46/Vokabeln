import SwiftUI

@main
struct FerhengApp: App {
    @State private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(Theme.brand)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.save() }
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var showWelcome = false

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Heute", systemImage: "sun.max.fill") }
            FoldersView()
                .tabItem { Label("Ordner", systemImage: "folder.fill") }
            StatsView()
                .tabItem { Label("Statistik", systemImage: "chart.bar.fill") }
            GrammarView()
                .tabItem { Label("Grammatik", systemImage: "book.fill") }
            SettingsView()
                .tabItem { Label("Mehr", systemImage: "gearshape.fill") }
        }
        .onAppear {
            if !store.hasOnboarded && store.folders.isEmpty { showWelcome = true }
        }
        .sheet(isPresented: $showWelcome) {
            WelcomeView()
                .interactiveDismissDisabled()
        }
    }
}

struct WelcomeView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(Theme.sunGradient).frame(width: 120, height: 120)
                    .shadow(color: Theme.sun.opacity(0.5), radius: 24)
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)
            }
            VStack(spacing: 8) {
                Text("Bi xêr hatî!")
                    .font(.largeTitle.bold())
                Text("Willkommen bei Ferheng – deinem Kurdisch-Trainer.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 14) {
                feature("folder.fill", "Ordner & Unterordner", "Sortiere deine Wörter nach Themen – und füge Ordner zusammen.")
                feature("brain.head.profile", "Lernt mit dir mit", "Schwere Wörter kommen öfter, leichte seltener.")
                feature("bolt.fill", "Verb-Trainer", "Präsensstamm, Präsens, Vergangenheit, Imperativ & Futur.")
            }
            .padding(.horizontal)
            Spacer()
            VStack(spacing: 12) {
                Button("Mit Beispielvokabeln starten") {
                    store.loadStarterPack()
                    dismiss()
                }
                .buttonStyle(GradientButtonStyle())
                Button("Leer starten") {
                    store.hasOnboarded = true
                    store.save()
                    dismiss()
                }
                .buttonStyle(SoftButtonStyle())
            }
        }
        .padding(24)
    }

    private func feature(_ icon: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.brand)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}
