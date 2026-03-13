import SwiftUI
import SwiftData

struct HistoryView: View {
    let onSelect: (ScanResult) -> Void
    @Query(sort: \HistoryItem.timestamp, order: .reverse) private var items: [HistoryItem]
    @State private var search = ""
    @State private var filter = "All"
    private let filters = ["All", "Food", "Sign", "Product", "Document"]

    private var filtered: [HistoryItem] {
        items.filter {
            (filter == "All" || $0.category.lowercased() == filter.lowercased()) &&
            (search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) || $0.zhName.localizedCaseInsensitiveContains(search))
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Theme.ink4)
                    TextField("Search scans...", text: $search).font(.subheadline)
                }.padding(12).background(Theme.paper).cornerRadius(12).padding(.horizontal, 24).padding(.bottom, 14)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(filters, id: \.self) { f in
                            Button { filter = f } label: {
                                Text(f).font(.caption).fontWeight(filter == f ? .bold : .medium)
                                    .foregroundStyle(filter == f ? .white : Theme.ink3)
                                    .padding(.horizontal, 14).padding(.vertical, 7)
                                    .background(filter == f ? Theme.ink : Theme.paper).cornerRadius(20)
                            }
                        }
                    }.padding(.horizontal, 24)
                }.padding(.bottom, 18)

                if filtered.isEmpty {
                    Spacer()
                    Text("No scans yet").font(.headline).foregroundStyle(Theme.ink3)
                    Text("Your history will appear here").font(.subheadline).foregroundStyle(Theme.ink4)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 7) {
                            ForEach(filtered) { item in
                                Button { onSelect(item.asScanResult) } label: {
                                    HStack(spacing: 13) {
                                        RoundedRectangle(cornerRadius: 12).fill(Theme.categoryColor(item.category).opacity(0.06))
                                            .frame(width: 46, height: 46)
                                            .overlay(Text(Theme.categoryEmoji(item.category)).font(.title3))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title).font(.subheadline).fontWeight(.semibold).foregroundStyle(Theme.ink).lineLimit(1)
                                            Text(item.subtitle).font(.caption).foregroundStyle(Theme.ink3).lineLimit(1)
                                        }; Spacer()
                                        Text(item.timestamp, style: .relative).font(.caption2).foregroundStyle(Theme.ink4)
                                    }.padding(15)
                                }
                            }
                        }.padding(.horizontal, 24)
                    }
                }
            }.navigationTitle("History").navigationBarTitleDisplayMode(.large)
        }
    }
}
