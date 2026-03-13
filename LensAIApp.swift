import SwiftUI
import SwiftData

@main
struct LensAIApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: HistoryItem.self)
    }
}

struct RootView: View {
    @State private var tab = 1
    @State private var scanResult: ScanResult?
    @State private var showResult = false
    @State private var showChef = false
    @StateObject private var chef = ChefConfirmation()

    var body: some View {
        TabView(selection: $tab) {
            HomeView(onScan: { tab = 1 }, onSelect: { r in scanResult = r; showResult = true })
                .tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            ScannerView { r in scanResult = r; showResult = true }
                .tabItem { Label("Scan", systemImage: "camera.viewfinder") }.tag(1)
            HistoryView { r in scanResult = r; showResult = true }
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }.tag(2)
        }
        .tint(Theme.accent)
        .sheet(isPresented: $showResult) {
            if let r = scanResult {
                NavigationStack {
                    ResultView(result: r, onAskChef: {
                        chef.reset(); showResult = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showChef = true }
                    })
                }.presentationDragIndicator(.visible)
            }
        }
        .fullScreenCover(isPresented: $showChef) {
            if let r = scanResult {
                AskTheChefFlow(result: r, chef: chef) { showChef = false }
            }
        }
    }
}
