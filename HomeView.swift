import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \HistoryItem.date, order: .reverse) private var history: [HistoryItem]
    @Binding var selectedTab: Int
    var onSelectHistory: (HistoryItem) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Greeting
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome to")
                        .font(.title3)
                        .foregroundColor(Theme.ink3)
                    Text("LensAI")
                        .font(.system(size: 40, weight: .bold, design: .serif))
                        .foregroundColor(Theme.ink)
                    Text("Point. Shoot. Understand China.")
                        .font(.subheadline)
                        .foregroundColor(Theme.ink4)
                }
                .padding(.top, 20)

                // Scan CTA
                Button {
                    selectedTab = 1
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 52, height: 52)
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scan something")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Point at any Chinese text, menu, or sign")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(20)
                    .background(Theme.ink2)
                    .cornerRadius(16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                // Recent scans
                if !history.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("RECENT SCANS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.ink4)
                            .tracking(1)

                        ForEach(history.prefix(3)) { item in
                            Button {
                                onSelectHistory(item)
                            } label: {
                                HStack(spacing: 12) {
                                    Text(Theme.categoryEmoji(item.category))
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(Theme.categoryColor(item.category).opacity(0.15))
                                        .cornerRadius(10)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(Theme.ink)
                                            .lineLimit(1)
                                        Text(item.subtitle)
                                            .font(.caption)
                                            .foregroundColor(Theme.ink3)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Text(item.date.relativeString)
                                        .font(.caption2)
                                        .foregroundColor(Theme.ink4)
                                }
                                .padding(12)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Tips
                VStack(alignment: .leading, spacing: 12) {
                    Text("TIPS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.ink4)
                        .tracking(1)

                    TipCard(emoji: "🍜", title: "Restaurant Menus",
                            text: "Scan any dish name for taste profile, ingredients, and how to order.")
                    TipCard(emoji: "🚇", title: "Signs & Notices",
                            text: "Point at subway signs, warnings, or notices to understand what to do.")
                    TipCard(emoji: "💊", title: "Medicine & Products",
                            text: "Scan medicine boxes or product labels for usage instructions.")
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 20)
        }
        .background(Theme.paper)
    }
}

// MARK: - Tip Card

private struct TipCard: View {
    let emoji: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(emoji)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.ink)
                Text(text)
                    .font(.caption)
                    .foregroundColor(Theme.ink3)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Relative Date

extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}
