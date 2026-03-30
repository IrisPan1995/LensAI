import SwiftUI
import Combine

// MARK: - Main Flow Container

struct AskTheChefFlow: View {
    let dishName: String
    let dishZhName: String
    @ObservedObject var confirmation: ChefConfirmation
    var onClose: () -> Void

    enum Step {
        case staffHome, allergens, spice, dietary, custom, done, userResult
    }

    @State private var step: Step = .staffHome

    var body: some View {
        Group {
            switch step {
            case .staffHome:
                StaffHomeView(
                    dishZhName: dishZhName,
                    confirmation: confirmation,
                    onClose: onClose,
                    onStep: { step = $0 }
                )
            case .allergens:
                AllergenCheckView(confirmation: confirmation) { step = .staffHome }
            case .spice:
                SpiceLevelView(confirmation: confirmation) { step = .staffHome }
            case .dietary:
                DietaryCheckView(confirmation: confirmation) { step = .staffHome }
            case .custom:
                CustomQuestionsView(confirmation: confirmation) { step = .staffHome }
            case .done:
                DoneView { step = .userResult }
            case .userResult:
                UserResultView(
                    dishName: dishName,
                    dishZhName: dishZhName,
                    confirmation: confirmation,
                    onClose: onClose
                )
            }
        }
        .animation(.easeInOut(duration: 0.25), value: step)
    }
}

// MARK: - Staff Home

private struct StaffHomeView: View {
    let dishZhName: String
    @ObservedObject var confirmation: ChefConfirmation
    var onClose: () -> Void
    var onStep: (AskTheChefFlow.Step) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Dark header
            VStack(spacing: 8) {
                HStack {
                    Button {
                        onClose()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .font(.subheadline)
                    }
                    Spacer()
                }

                Text(dishZhName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 8)
            }
            .padding(20)
            .padding(.top, 8)
            .background(Theme.ink2)

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("请帮忙确认以下信息 🙏")
                            .font(.headline)
                            .foregroundColor(Theme.ink)
                        Text("Please help confirm the following")
                            .font(.subheadline)
                            .foregroundColor(Theme.ink3)
                    }
                    .padding(.top, 20)

                    categoryCard(
                        emoji: "🚨", zhTitle: "过敏原确认", enTitle: "Allergen Check",
                        done: confirmation.allergenDone
                    ) { onStep(.allergens) }

                    categoryCard(
                        emoji: "🌶️", zhTitle: "辣度选择", enTitle: "Spice Level",
                        done: confirmation.spiceDone
                    ) { onStep(.spice) }

                    categoryCard(
                        emoji: "🥩", zhTitle: "食材确认", enTitle: "Dietary / Ingredients",
                        done: confirmation.dietaryDone
                    ) { onStep(.dietary) }

                    categoryCard(
                        emoji: "💬", zhTitle: "其他问题", enTitle: "Other Questions",
                        done: confirmation.customDone
                    ) { onStep(.custom) }

                    Button {
                        onStep(.done)
                    } label: {
                        Text("全部完成 ✓ Done")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Theme.accent)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Theme.paper)
    }

    private func categoryCard(emoji: String, zhTitle: String, enTitle: String, done: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(emoji)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(zhTitle)
                        .font(.headline)
                        .foregroundColor(Theme.ink)
                    Text(enTitle)
                        .font(.caption)
                        .foregroundColor(Theme.ink3)
                }
                Spacer()
                if done {
                    ZStack {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 28, height: 28)
                        Text("✓")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.ink4)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Allergen Check (3-state toggle)

private struct AllergenCheckView: View {
    @ObservedObject var confirmation: ChefConfirmation
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            chefSubHeader(title: "过敏原确认", subtitle: "Allergen Check", onBack: onBack)

            ScrollView {
                VStack(spacing: 16) {
                    Text("点一下 = 含有 ✓   再点 = 不含 ✗   不确定跳过")
                        .font(.caption)
                        .foregroundColor(Theme.ink3)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)

                    Text("Tap = contains ✓   Tap again = doesn't contain ✗   Skip if unsure")
                        .font(.caption2)
                        .foregroundColor(Theme.ink4)
                        .multilineTextAlignment(.center)

                    WrappingHStack(alignment: .leading, spacing: 10) {
                        ForEach(Allergen.all) { allergen in
                            let state = confirmation.allergenStates[allergen.id]
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    confirmation.allergenStates[allergen.id].toggle()
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(allergen.emoji)
                                        .font(.title2)
                                    Text(allergen.zhName)
                                        .font(.caption2)
                                        .foregroundColor(stateTextColor(state))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                    Text(allergen.name)
                                        .font(.caption2)
                                        .foregroundColor(stateTextColor(state).opacity(0.7))
                                        .lineLimit(1)
                                    Text(stateSymbol(state))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(stateColor(state))
                                }
                                .frame(width: 100, height: 110)
                                .background(stateBackground(state))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(stateColor(state).opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)

                    Button {
                        confirmation.allergenDone = true
                        onBack()
                    } label: {
                        Text("确认 · Confirm")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Theme.accent)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
        }
        .background(Theme.paper)
    }

    private func stateColor(_ state: AllergenState) -> Color {
        switch state {
        case .unknown:        return Theme.allergenGray
        case .contains:       return Theme.alert
        case .doesNotContain: return Theme.accent
        }
    }

    private func stateBackground(_ state: AllergenState) -> Color {
        switch state {
        case .unknown:        return Theme.allergenGray.opacity(0.15)
        case .contains:       return Theme.alert.opacity(0.1)
        case .doesNotContain: return Theme.accent.opacity(0.1)
        }
    }

    private func stateTextColor(_ state: AllergenState) -> Color {
        switch state {
        case .unknown:        return Theme.ink3
        case .contains:       return Theme.alert
        case .doesNotContain: return Theme.accent
        }
    }

    private func stateSymbol(_ state: AllergenState) -> String {
        switch state {
        case .unknown:        return "—"
        case .contains:       return "✓"
        case .doesNotContain: return "✗"
        }
    }
}

// MARK: - Spice Level (single select)

private struct SpiceLevelView: View {
    @ObservedObject var confirmation: ChefConfirmation
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            chefSubHeader(title: "辣度选择", subtitle: "Spice Level", onBack: onBack)

            ScrollView {
                VStack(spacing: 12) {
                    Text("请选择辣度 · Select spice level")
                        .font(.subheadline)
                        .foregroundColor(Theme.ink3)
                        .padding(.top, 20)

                    ForEach(SpiceLevel.allCases) { level in
                        let selected = confirmation.selectedSpice == level
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                confirmation.selectedSpice = level
                            }
                        } label: {
                            HStack {
                                Text(level.emoji)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.label)
                                        .font(.headline)
                                        .foregroundColor(selected ? level.color : Theme.ink)
                                    Text(level.englishLabel)
                                        .font(.caption)
                                        .foregroundColor(selected ? level.color.opacity(0.7) : Theme.ink3)
                                }
                                Spacer()
                                if selected {
                                    Text("✓")
                                        .font(.headline)
                                        .foregroundColor(level.color)
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(selected ? level.color : Color.clear, lineWidth: 2)
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        confirmation.spiceDone = true
                        onBack()
                    } label: {
                        Text("确认 · Confirm")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Theme.accent)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Theme.paper)
    }
}

// MARK: - Dietary Check (multi-select)

private struct DietaryCheckView: View {
    @ObservedObject var confirmation: ChefConfirmation
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            chefSubHeader(title: "食材确认", subtitle: "Dietary / Ingredients", onBack: onBack)

            ScrollView {
                VStack(spacing: 12) {
                    Text("请勾选包含的食材 · Select included items")
                        .font(.subheadline)
                        .foregroundColor(Theme.ink3)
                        .padding(.top, 20)

                    WrappingHStack(alignment: .leading, spacing: 10) {
                        ForEach(DietaryItem.all) { item in
                            let selected = confirmation.dietarySelected.contains(item.id)
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    if selected {
                                        confirmation.dietarySelected.remove(item.id)
                                    } else {
                                        confirmation.dietarySelected.insert(item.id)
                                    }
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Text(item.emoji)
                                        .font(.title2)
                                    Text(item.zhName)
                                        .font(.caption)
                                        .foregroundColor(selected ? Theme.sign : Theme.ink)
                                    Text(item.name)
                                        .font(.caption2)
                                        .foregroundColor(selected ? Theme.sign.opacity(0.7) : Theme.ink3)
                                        .lineLimit(1)
                                }
                                .frame(width: 100, height: 90)
                                .background(selected ? Theme.sign.opacity(0.1) : Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selected ? Theme.sign : Theme.allergenGray.opacity(0.3), lineWidth: selected ? 2 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)

                    Button {
                        confirmation.dietaryDone = true
                        onBack()
                    } label: {
                        Text("确认 · Confirm")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Theme.accent)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
        }
        .background(Theme.paper)
    }
}

// MARK: - Custom Questions

private struct CustomQuestionsView: View {
    @ObservedObject var confirmation: ChefConfirmation
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            chefSubHeader(title: "其他问题", subtitle: "Other Questions", onBack: onBack)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(confirmation.customQuestions.indices, id: \.self) { i in
                        let q = confirmation.customQuestions[i]
                        VStack(alignment: .leading, spacing: 8) {
                            Text(q.zhText)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(Theme.ink)
                            Text(q.enText)
                                .font(.caption)
                                .foregroundColor(Theme.ink3)

                            HStack(spacing: 12) {
                                yesNoButton(label: "是 Yes", selected: q.answer == true) {
                                    confirmation.customQuestions[i].answer = q.answer == true ? nil : true
                                }
                                yesNoButton(label: "否 No", selected: q.answer == false) {
                                    confirmation.customQuestions[i].answer = q.answer == false ? nil : false
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(14)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("备注 · Notes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Theme.ink)

                        TextField("其他需要说明的... Any other notes...", text: $confirmation.freeNote, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(Theme.paper3)
                            .cornerRadius(10)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(14)

                    Button {
                        confirmation.customDone = true
                        onBack()
                    } label: {
                        Text("确认 · Confirm")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Theme.accent)
                            .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .background(Theme.paper)
    }

    private func yesNoButton(label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(selected ? .white : Theme.ink3)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(selected ? Theme.accent : Theme.paper3)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Done Screen

private struct DoneView: View {
    var onViewResults: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("🙏")
                .font(.system(size: 72))
            Text("谢谢！")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            Text("Thank you!")
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            Text("请将手机还给客人 📱")
                .font(.headline)
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 8)
            Text("Please return the phone to the guest")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.4))

            Spacer()

            Button(action: onViewResults) {
                Text("View Results · 查看结果")
                    .font(.headline)
                    .foregroundColor(Theme.ink2)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.ink2)
    }
}

// MARK: - User Result

private struct UserResultView: View {
    let dishName: String
    let dishZhName: String
    @ObservedObject var confirmation: ChefConfirmation
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dishName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.ink)
                            Text(dishZhName)
                                .font(.headline)
                                .foregroundColor(Theme.ink3)
                        }
                        Spacer()
                        Text("CHEF CONFIRMED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.accent.opacity(0.12))
                            .cornerRadius(8)
                    }

                    let containsAllergens = Allergen.all.filter { confirmation.allergenStates[$0.id] == .contains }
                    let safeAllergens = Allergen.all.filter { confirmation.allergenStates[$0.id] == .doesNotContain }

                    if !containsAllergens.isEmpty {
                        sectionLabel("CONTAINS", color: Theme.alert)
                        ForEach(containsAllergens) { a in
                            allergenCard(a, state: .contains)
                        }
                    }

                    if !safeAllergens.isEmpty {
                        sectionLabel("DOES NOT CONTAIN", color: Theme.accent)
                        ForEach(safeAllergens) { a in
                            allergenCard(a, state: .doesNotContain)
                        }
                    }

                    if let spice = confirmation.selectedSpice {
                        sectionLabel("SPICE LEVEL", color: Theme.ink3)
                        HStack {
                            Text(spice.emoji)
                                .font(.title3)
                            Text("\(spice.label) · \(spice.englishLabel)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(spice.color)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(spice.color.opacity(0.1))
                        .cornerRadius(12)
                    }

                    let selectedDietary = DietaryItem.all.filter { confirmation.dietarySelected.contains($0.id) }
                    if !selectedDietary.isEmpty {
                        sectionLabel("INGREDIENTS", color: Theme.ink3)
                        ForEach(selectedDietary) { item in
                            HStack(spacing: 10) {
                                Text(item.emoji)
                                Text("\(item.zhName) · \(item.name)")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.ink)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                    }

                    let answered = confirmation.customQuestions.filter { $0.answer != nil }
                    if !answered.isEmpty {
                        sectionLabel("CUSTOM QUESTIONS", color: Theme.ink3)
                        ForEach(answered) { q in
                            HStack {
                                Text(q.enText)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.ink)
                                Spacer()
                                if q.answer == true {
                                    Text("Chef says OK ✓")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(Theme.accent)
                                } else {
                                    Text("Not available ✗")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(Theme.alert)
                                }
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                    }

                    if !confirmation.freeNote.isEmpty {
                        sectionLabel("CHEF'S NOTE", color: Theme.ink3)
                        Text(confirmation.freeNote)
                            .font(.subheadline)
                            .foregroundColor(Theme.ink)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.paper3)
                            .cornerRadius(10)
                    }

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .background(Theme.paper)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onClose()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("New scan")
                        }
                        .foregroundColor(Theme.accent)
                    }
                }
            }
        }
    }

    private func sectionLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(color)
            .tracking(1)
            .padding(.top, 4)
    }

    private func allergenCard(_ allergen: Allergen, state: AllergenState) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(state == .contains ? Theme.alert : Theme.accent)
                .frame(width: 3)

            Text(allergen.emoji)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(allergen.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(state == .contains ? Theme.alert : Theme.accent)
                Text(allergen.zhName)
                    .font(.caption)
                    .foregroundColor(Theme.ink3)
            }

            Spacer()

            Text(state == .contains ? "✓" : "✗")
                .font(.headline)
                .foregroundColor(state == .contains ? Theme.alert : Theme.accent)
        }
        .padding(12)
        .background(state == .contains ? Theme.alert.opacity(0.06) : Theme.accent.opacity(0.06))
        .cornerRadius(12)
    }
}

// MARK: - Shared Sub-Header

private func chefSubHeader(title: String, subtitle: String, onBack: @escaping () -> Void) -> some View {
    VStack(spacing: 4) {
        HStack {
            Button {
                onBack()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("返回")
                }
                .foregroundColor(.white.opacity(0.85))
                .font(.subheadline)
            }
            Spacer()
        }

        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
        Text(subtitle)
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.7))
    }
    .padding(20)
    .padding(.top, 8)
    .frame(maxWidth: .infinity)
    .background(Theme.ink2)
}

// MARK: - WrappingHStack (Custom Layout)

struct WrappingHStack: Layout {
    var alignment: HorizontalAlignment = .leading
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private struct LayoutResult {
        var positions: [CGPoint]
        var size: CGSize
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            maxX = max(maxX, currentX - spacing)
            rowHeight = max(rowHeight, size.height)
        }

        return LayoutResult(
            positions: positions,
            size: CGSize(width: maxX, height: currentY + rowHeight)
        )
    }
}
