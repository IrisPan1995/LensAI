import SwiftUI
import SwiftData

struct HomeView: View {
    let onScan: () -> Void
    let onSelect: (ScanResult) -> Void
    @Query(sort: \HistoryItem.timestamp, order: .reverse) private var history: [HistoryItem]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Good morning").font(.subheadline).foregroundStyle(Theme.ink3)
                        Text("What do you see?").font(.system(size: 28, weight: .regular, design: .serif))
                    }.padding(.horizontal, 28).padding(.top, 8)

                    Button(action: onScan) {
                        HStack(spacing: 13) {
                            Circle().fill(Theme.accent).frame(width: 42, height: 42)
                                .overlay(Image(systemName: "camera.viewfinder").foregroundStyle(.white))
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Scan something").font(.headline).foregroundStyle(.white)
                                Text("Photo or camera").font(.caption).foregroundStyle(.white.opacity(0.65))
                            }
                            Spacer()
                            Image(systemName: "arrow.right").foregroundStyle(.white.opacity(0.4))
                        }.padding(20).background(Theme.ink).cornerRadius(20)
                    }.padding(.horizontal, 24).padding(.top, 22).padding(.bottom, 24)

                    if !history.isEmpty {
                        HStack {
                            Text("RECENT").font(.caption).fontWeight(.semibold).tracking(2).foregroundStyle(Theme.ink4)
                            Spacer()
                        }.padding(.horizontal, 28).padding(.bottom, 12)

                        ForEach(history.prefix(3)) { item in
                            Button { onSelect(item.asScanResult) } label: {
                                HStack(spacing: 13) {
                                    RoundedRectangle(cornerRadius: 11).fill(Theme.categoryColor(item.category).opacity(0.08))
                                        .frame(width: 42, height: 42)
                                        .overlay(Text(Theme.categoryEmoji(item.category)).font(.title3))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title).font(.subheadline).fontWeight(.semibold).foregroundStyle(Theme.ink).lineLimit(1)
                                        Text(item.subtitle).font(.caption).foregroundStyle(Theme.ink3).lineLimit(1)
                                    }
                                    Spacer()
                                }.padding(15).background(Theme.paper).cornerRadius(14)
                            }.padding(.horizontal, 24).padding(.bottom, 9)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("TIPS").font(.caption2).fontWeight(.semibold).tracking(2).foregroundStyle(Theme.ink4)
                        Label("Snap menus for dish context", systemImage: "camera").font(.subheadline).foregroundStyle(Theme.ink3)
                        Label("Scan Chinese text for meaning", systemImage: "character.textbox").font(.subheadline).foregroundStyle(Theme.ink3)
                        Label("Scan medicine for dosage", systemImage: "pills").font(.subheadline).foregroundStyle(Theme.ink3)
                    }.padding(16).overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.paper3))
                    .padding(.horizontal, 24).padding(.top, 22)
                }.padding(.bottom, 32)
            }.background(Color.white)
        }
    }
}
