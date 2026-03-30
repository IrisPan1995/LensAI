import SwiftUI
import SwiftData

@main
struct VoyaApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: HistoryItem.self)
    }
}

// MARK: - Active Sheet Enum

enum ActiveSheet: Identifiable {
    case scanResult
    case historyDetail(HistoryItem)

    var id: String {
        switch self {
        case .scanResult: return "scanResult"
        case .historyDetail(let item): return "history-\(item.id)"
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @State private var selectedTab = 0

    // Result state
    @State private var resultImage: UIImage?
    @State private var scanResult: ScanResult = .placeholder

    // Sheet management — single source of truth
    @State private var activeSheet: ActiveSheet?

    // Ask the Chef state
    @State private var showChef = false
    @StateObject private var chefConfirmation = ChefConfirmation()

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView(
                    selectedTab: $selectedTab,
                    onSelectHistory: { item in
                        activeSheet = .historyDetail(item)
                    }
                )
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(0)

                // Only create ScannerView when Scan tab is selected
                Group {
                    if selectedTab == 1 {
                        ScannerView { image, result in
                            resultImage = image
                            scanResult = result
                            activeSheet = .scanResult
                        }
                    } else {
                        Color(hex: "1A1A1A")
                    }
                }
                .tabItem {
                    Image(systemName: "camera.viewfinder")
                    Text("Scan")
                }
                .tag(1)

                HistoryView()
                    .tabItem {
                        Image(systemName: "clock")
                        Text("History")
                    }
                    .tag(2)
            }
            .tint(Theme.accent)
        }
        // Single sheet for all presentations
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .scanResult:
                ResultView(
                    image: resultImage,
                    result: scanResult,
                    onAskChef: {
                        chefConfirmation.reset()
                        activeSheet = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showChef = true
                        }
                    },
                    onDismiss: {
                        activeSheet = nil
                    }
                )
            case .historyDetail(let item):
                HistoryResultView(item: item)
            }
        }
        // fullScreenCover on a separate layer
        .fullScreenCover(isPresented: $showChef) {
            AskTheChefFlow(
                dishName: scanResult.title,
                dishZhName: scanResult.zhName,
                confirmation: chefConfirmation,
                onClose: {
                    showChef = false
                }
            )
        }
    }
}
