import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \HistoryItem.date, order: .reverse) private var allItems: [HistoryItem]
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var selectedItem: HistoryItem?

    private let categories = ["All", "Food", "Sign", "Product", "Document"]

    private var filteredItems: [HistoryItem] {
        allItems.filter { item in
            let matchesCategory = selectedCategory == "All" || item.category.lowercased() == selectedCategory.lowercased()
            let matchesSearch = searchText.isEmpty
                || item.title.localizedCaseInsensitiveContains(searchText)
                || item.zhName.localizedCaseInsensitiveContains(searchText)
                || item.subtitle.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.ink4)
                    TextField("Search scans...", text: $searchText)
                        .font(.subheadline)
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Category pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = cat
                                }
                            } label: {
                                Text(cat)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedCategory == cat ? .white : Theme.ink3)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == cat ? Theme.ink2 : Theme.paper3)
                                    .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }

                // List
                if filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Text("📷")
                            .font(.system(size: 48))
                        Text("No scans yet")
                            .font(.headline)
                            .foregroundColor(Theme.ink3)
                        Text("Scan something to see it here")
                            .font(.subheadline)
                            .foregroundColor(Theme.ink4)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredItems) { item in
                                Button {
                                    selectedItem = item
                                } label: {
                                    historyRow(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 80)
                    }
                }
            }
            .background(Theme.paper)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedItem) { item in
                HistoryResultView(item: item)
            }
        }
    }

    private func historyRow(_ item: HistoryItem) -> some View {
        HStack(spacing: 12) {
            Text(Theme.categoryEmoji(item.category))
                .font(.title3)
                .frame(width: 40, height: 40)
                .background(Theme.categoryColor(item.category).opacity(0.12))
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
        .contentShape(Rectangle())
    }
}
