import SwiftUI
import SwiftData

struct ResultView: View {
    let result: ScanResult
    let onAskChef: () -> Void
    @Environment(\.modelContext) private var ctx
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let data = result.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui).resizable().aspectRatio(contentMode: .fill)
                        .frame(height: 170).cornerRadius(16).clipped()
                        .padding(.horizontal, 20).padding(.bottom, 16)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.category.uppercased()).font(.caption2).fontWeight(.bold).tracking(3)
                        .foregroundStyle(Theme.categoryColor(result.category))
                    Text(result.title).font(.system(size: 26, weight: .regular, design: .serif))
                    Text("\(result.zhName) — \(result.subtitle)").font(.subheadline).foregroundStyle(Theme.ink3).italic()
                }.padding(.horizontal, 28).padding(.bottom, 14)

                Divider().padding(.horizontal, 28)
                sec("What It Is", result.what)
                Divider().padding(.horizontal, 28)
                sec("Context", result.context)
                Divider().padding(.horizontal, 28)
                sec("Tips", result.tips)

                if !result.commonAllergens.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("⚠️ Common Allergens").font(.caption).fontWeight(.heavy).foregroundStyle(Theme.alert)
                        Text(result.commonAllergens).font(.subheadline).foregroundStyle(Color(hex: "9B3A30")).lineSpacing(3)
                        Text("General info — varies by restaurant.").font(.caption).foregroundStyle(Theme.ink4).italic()
                    }.padding(14).background(Theme.alert.opacity(0.06)).cornerRadius(12)
                    .overlay(alignment: .leading) { Rectangle().fill(Theme.alert).frame(width: 3) }.cornerRadius(12)
                    .padding(.horizontal, 20).padding(.top, 4)
                }

                if result.isFood {
                    Button(action: onAskChef) {
                        VStack(spacing: 6) {
                            HStack(spacing: 12) {
                                Text("🧑‍🍳").font(.title)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ask the Chef").font(.headline)
                                    Text("让店员确认过敏原与口味").font(.caption).opacity(0.7)
                                }; Spacer()
                            }
                            Text("递给服务员 → Hand to staff →").font(.subheadline).fontWeight(.bold).foregroundStyle(Theme.accent2).padding(.top, 8)
                        }.foregroundStyle(.white).padding(18)
                        .background(LinearGradient(colors: [Theme.ink, Color(hex: "2D2D2D")], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(16)
                    }.padding(.horizontal, 20).padding(.top, 8)
                }

                Button {
                    ctx.insert(HistoryItem(from: result)); try? ctx.save(); saved = true
                } label: {
                    Label(saved ? "Saved ✓" : "Save to History", systemImage: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(saved ? Theme.accent : Theme.ink3)
                        .frame(maxWidth: .infinity).padding(14).background(Theme.paper).cornerRadius(12)
                }.disabled(saved).padding(.horizontal, 20).padding(.top, 10).padding(.bottom, 32)
            }
        }.navigationTitle("").navigationBarTitleDisplayMode(.inline)
    }

    private func sec(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased()).font(.caption2).fontWeight(.bold).tracking(3).foregroundStyle(Theme.accent)
            Text(text).font(.subheadline).foregroundStyle(Theme.ink2).lineSpacing(4)
        }.padding(.horizontal, 28).padding(.vertical, 16)
    }
}
