import SwiftUI
import SwiftData

struct ResultView: View {
    let image: UIImage?
    let result: ScanResult
    var onAskChef: () -> Void
    var onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var saved = false

    private var isFood: Bool {
        result.category.lowercased() == "food"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let img = image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(16)
                    }

                    // Title section
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(Theme.categoryEmoji(result.category))
                                .font(.title2)
                            Text(result.category.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.categoryColor(result.category))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.categoryColor(result.category).opacity(0.12))
                                .cornerRadius(6)
                        }

                        Text(result.title)
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(Theme.ink)

                        if !result.zhName.isEmpty {
                            Text(result.zhName)
                                .font(.title3)
                                .foregroundColor(Theme.ink3)
                        }

                        if !result.subtitle.isEmpty {
                            Text(result.subtitle)
                                .font(.subheadline)
                                .foregroundColor(Theme.ink4)
                        }
                    }

                    resultSection(label: "WHAT IT IS", text: result.what)
                    resultSection(label: "CULTURAL CONTEXT", text: result.context)
                    resultSection(label: "PRACTICAL TIPS", text: result.tips)

                    // Empty result hint
                    if result.what.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        && result.context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        && result.tips.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(spacing: 8) {
                            Text("No details available")
                                .font(.subheadline)
                                .foregroundColor(Theme.ink3)
                            Text("Try scanning again with clearer text")
                                .font(.caption)
                                .foregroundColor(Theme.ink4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }

                    // Allergen Warning (food only)
                    if isFood && !result.commonAllergens.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ALLERGEN WARNING")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.alert)
                                .tracking(1)

                            HStack(alignment: .top, spacing: 12) {
                                Rectangle()
                                    .fill(Theme.alert)
                                    .frame(width: 3)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Common allergens: \(result.commonAllergens.joined(separator: ", "))")
                                        .font(.subheadline)
                                        .foregroundColor(Theme.ink)

                                    Text("General info — actual ingredients vary by restaurant")
                                        .font(.caption)
                                        .foregroundColor(Theme.ink4)
                                        .italic()
                                }
                            }
                            .padding(12)
                            .background(Theme.alert.opacity(0.06))
                            .cornerRadius(12)
                        }
                    }

                    // Ask the Chef (food only)
                    if isFood {
                        Button(action: onAskChef) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ask the Chef")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("递给服务员 → Hand to staff →")
                                        .font(.caption)
                                        .foregroundColor(Theme.accent2)
                                }
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Theme.accent2)
                            }
                            .padding(16)
                            .background(Theme.ink2)
                            .cornerRadius(14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    // Save button
                    Button {
                        saveToHistory()
                    } label: {
                        HStack {
                            Image(systemName: saved ? "checkmark.circle.fill" : "square.and.arrow.down")
                            Text(saved ? "Saved" : "Save to History")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(saved ? Theme.accent : Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(saved ? Theme.accent.opacity(0.1) : Theme.paper3)
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(saved)

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Theme.paper)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(Theme.accent)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func resultSection(label: String, text: String) -> some View {
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.accent)
                    .tracking(1)

                Text(text)
                    .font(.body)
                    .foregroundColor(Theme.ink)
                    .lineSpacing(4)
            }
        }
    }

    private func saveToHistory() {
        let item = HistoryItem(
            title: result.title,
            zhName: result.zhName,
            subtitle: result.subtitle,
            category: result.category,
            what: result.what,
            context: result.context,
            tips: result.tips,
            commonAllergens: result.commonAllergens,
            imageData: image?.jpegData(compressionQuality: 0.6)
        )
        modelContext.insert(item)
        withAnimation { saved = true }
    }
}

// MARK: - History Result View

struct HistoryResultView: View {
    let item: HistoryItem
    @Environment(\.dismiss) private var dismiss

    private var result: ScanResult {
        ScanResult(
            title: item.title,
            zhName: item.zhName,
            subtitle: item.subtitle,
            category: item.category,
            what: item.what,
            context: item.context,
            tips: item.tips,
            commonAllergens: item.commonAllergens
        )
    }

    private var image: UIImage? {
        if let data = item.imageData { return UIImage(data: data) }
        return nil
    }

    var body: some View {
        ResultView(
            image: image,
            result: result,
            onAskChef: {},
            onDismiss: { dismiss() }
        )
    }
}
