import SwiftUI
import Combine

struct AskTheChefFlow: View {
    let result: ScanResult
    @ObservedObject var chef: ChefConfirmation
    let onDone: () -> Void
    @State private var step = 0

    var body: some View {
        switch step {
        case 1: allergenPage
        case 2: spicePage
        case 3: dietaryPage
        case 4: customPage
        case 5: donePage
        case 6: userResultPage
        default: staffHomePage
        }
    }

    private var staffHomePage: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                VStack(spacing: 4) {
                    Text("外国客人想了解").foregroundStyle(.white.opacity(0.7)).padding(.top, 28)
                    Text(result.zhName).font(.largeTitle).fontWeight(.bold).foregroundStyle(.white)
                    Text(result.title).font(.subheadline).foregroundStyle(.white.opacity(0.6))
                }.frame(maxWidth: .infinity).padding(.vertical, 24)
                bk(.white.opacity(0.85), "返回") { onDone() }.padding(.top, 20).padding(.leading, 20)
            }.background(Theme.ink)
            VStack(spacing: 0) {
                Text("请帮忙确认以下信息 🙏").font(.headline).padding(.top, 20).padding(.bottom, 4)
                Text("Please help confirm").font(.subheadline).foregroundStyle(Theme.ink3).padding(.bottom, 18)
                mRow("⚠️", "过敏原确认", "Allergen", !chef.allergens.isEmpty) { step = 1 }
                mRow("🌶️", "辣度选择", "Spice", chef.spiceLevel != nil) { step = 2 }
                mRow("🥩", "食材确认", "Dietary", !chef.dietary.isEmpty) { step = 3 }
                mRow("💬", "其他问题", "Other", !chef.customAnswers.isEmpty || !chef.staffNote.isEmpty) { step = 4 }
                Button { step = 5 } label: { Text("全部完成 ✓ Done").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity).padding(15).background(Theme.accent).cornerRadius(14) }.padding(.top, 16)
            }.padding(.horizontal, 24)
            Spacer()
        }.background(Theme.paper)
    }

    private func mRow(_ icon: String, _ zh: String, _ en: String, _ done: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(icon).font(.title2).frame(width: 38)
                VStack(alignment: .leading, spacing: 2) { Text(zh).font(.body).fontWeight(.bold).foregroundStyle(Theme.ink); Text(en).font(.subheadline).foregroundStyle(Theme.ink3) }
                Spacer()
                if done { Circle().fill(Theme.accent).frame(width: 28, height: 28).overlay(Text("✓").font(.caption).fontWeight(.heavy).foregroundStyle(.white)) }
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Theme.ink4)
            }.padding(15).background(.white).cornerRadius(14).overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "DDD")))
        }.padding(.bottom, 9)
    }

    private var allergenPage: some View {
        VStack(spacing: 0) {
            pgH("⚠️ 这道菜含有以下食材吗？", "点一下=含有✓ 再点=不含✗", "1/4") { step = 0 }
            ScrollView { LazyVStack(spacing: 7) { ForEach(Allergen.all) { a in
                let st = chef.allergens[a.id]
                Button { switch st { case .contains: chef.allergens[a.id] = .doesNotContain; case .doesNotContain: chef.allergens.removeValue(forKey: a.id); case nil: chef.allergens[a.id] = .contains } } label: {
                    HStack(spacing: 11) {
                        Text(a.emoji).font(.title3).frame(width: 28)
                        VStack(alignment: .leading) { Text(a.zh).font(.body).fontWeight(.bold).foregroundStyle(Theme.ink); Text(a.en + (a.sub.map{" · \($0)"} ?? "")).font(.caption).foregroundStyle(Theme.ink3) }
                        Spacer()
                        RoundedRectangle(cornerRadius: 8).fill(st == .contains ? Theme.alert : st == .doesNotContain ? Theme.accent : Color(hex:"C8C4BD")).frame(width:34,height:34)
                            .overlay(Text(st == .contains ? "✓" : st == .doesNotContain ? "✗" : "—").font(.body).fontWeight(.heavy).foregroundStyle(st==nil ? Theme.ink4 : .white))
                    }.padding(13).background(st == .contains ? Theme.alert.opacity(0.08) : st == .doesNotContain ? Theme.accent.opacity(0.06) : .white).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius:12).stroke(st == .contains ? Theme.alert : st == .doesNotContain ? Theme.accent : Color(hex:"DDD"),lineWidth:1.5))
                }
            } }.padding(.horizontal, 24).padding(.bottom, 80) }
            cfm { step = 0 }
        }
    }

    private var spicePage: some View {
        VStack(spacing: 0) {
            pgH("🌶️ 客人想要什么辣度？", "What spice level?", "2/4") { step = 0 }
            VStack(spacing: 9) { ForEach(SpiceLevel.allCases) { s in
                Button { chef.spiceLevel = s } label: {
                    HStack(spacing:14) { Text(s.icon).font(.title2).frame(width:40)
                        VStack(alignment:.leading,spacing:2) { Text(s.zh).font(.title3).fontWeight(.heavy).foregroundStyle(chef.spiceLevel==s ? s.color : Theme.ink); Text(s.en).font(.subheadline).foregroundStyle(Theme.ink3) }
                        Spacer(); if chef.spiceLevel==s { Text("✓").font(.title3).fontWeight(.bold).foregroundStyle(s.color) }
                    }.padding(17).background(chef.spiceLevel==s ? s.color.opacity(0.09) : .white).cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius:14).stroke(chef.spiceLevel==s ? s.color : Color(hex:"DDD"),lineWidth:2))
                }
            } }.padding(.horizontal, 24); Spacer(); cfm { step = 0 }
        }
    }

    private var dietaryPage: some View {
        VStack(spacing: 0) {
            pgH("🥩 这道菜包含以下成分吗？", "请勾选含有的项目", "3/4") { step = 0 }
            ScrollView { LazyVStack(spacing: 7) { ForEach(DietaryItem.all) { d in
                let on = chef.dietary.contains(d.id)
                Button { if on { chef.dietary.remove(d.id) } else { chef.dietary.insert(d.id) } } label: {
                    HStack(spacing:11) { Text(d.emoji).font(.title3).frame(width:28)
                        VStack(alignment:.leading) { Text(d.zh).font(.body).fontWeight(.bold).foregroundStyle(Theme.ink); Text(d.en).font(.caption).foregroundStyle(Theme.ink3) }; Spacer()
                        RoundedRectangle(cornerRadius:8).fill(on ? Theme.sign : Color(hex:"C8C4BD")).frame(width:30,height:30)
                            .overlay(on ? Text("✓").font(.subheadline).fontWeight(.heavy).foregroundStyle(.white) : nil)
                    }.padding(14).background(on ? Theme.sign.opacity(0.06) : .white).cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius:12).stroke(on ? Theme.sign : Color(hex:"DDD"),lineWidth:1.5))
                }
            } }.padding(.horizontal, 24).padding(.bottom, 80) }
            cfm { step = 0 }
        }
    }

    private var customPage: some View {
        VStack(spacing: 0) {
            pgH("💬 其他问题", "Other requests", "4/4") { step = 0 }
            VStack(spacing: 10) {
                ForEach(CustomQuestion.all) { q in let on = chef.customAnswers.contains(q.id)
                    Button { if on { chef.customAnswers.remove(q.id) } else { chef.customAnswers.insert(q.id) } } label: {
                        HStack(spacing:14) { VStack(alignment:.leading,spacing:2) { Text(q.zh).font(.body).fontWeight(.bold).foregroundStyle(Theme.ink); Text(q.en).font(.subheadline).foregroundStyle(Theme.ink3) }; Spacer()
                            Text(on ? "可以 Yes" : "可以?").font(.subheadline).fontWeight(.bold).foregroundStyle(.white)
                                .padding(.horizontal,14).padding(.vertical,6).background(on ? Theme.accent : Color(hex:"C8C4BD")).cornerRadius(8)
                        }.padding(16).background(on ? Theme.accent.opacity(0.04) : .white).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius:12).stroke(on ? Theme.accent : Color(hex:"DDD"),lineWidth:1.5))
                    }
                }
                VStack(alignment:.leading,spacing:6) { Text("备注 · Note").font(.subheadline).fontWeight(.bold)
                    TextField("如有其他说明...", text: $chef.staffNote, axis: .vertical).lineLimit(3...6).font(.subheadline).padding(12).background(.white).cornerRadius(12).overlay(RoundedRectangle(cornerRadius:12).stroke(Color(hex:"DDD"),lineWidth:1.5))
                }.padding(.top, 8)
            }.padding(.horizontal, 24); Spacer(); cfm { step = 0 }
        }
    }

    private var donePage: some View {
        VStack(spacing: 8) { Spacer()
            Text("🙏").font(.system(size: 72))
            Text("谢谢！").font(.largeTitle).fontWeight(.heavy).foregroundStyle(.white).padding(.top, 12)
            Text("Thank you!").font(.title3).foregroundStyle(.white.opacity(0.8))
            Text("请将手机还给客人 📱").font(.subheadline).foregroundStyle(.white.opacity(0.6)).padding(.top, 4).padding(.bottom, 36)
            Button { step = 6 } label: { Text("View Results · 查看结果").font(.headline).foregroundStyle(.white).padding(.horizontal,48).padding(.vertical,14).background(Theme.accent).cornerRadius(14) }
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Theme.ink)
    }

    private var userResultPage: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("CHEF CONFIRMED").font(.caption2).fontWeight(.heavy).tracking(3).foregroundStyle(Theme.accent)
                    Text(result.title).font(.system(size: 22, weight: .regular, design: .serif)).padding(.bottom, 6)
                    if !chef.containsList.isEmpty { tBlock("⚠️ CONTAINS", chef.containsList.map{"\($0.emoji) \($0.en)"}, Theme.alert) }
                    if !chef.safeList.isEmpty { tBlock("✓ SAFE", chef.safeList.map{"\($0.emoji) \($0.en)"}, Theme.accent) }
                    if let s = chef.spiceLevel { HStack(spacing:12) { Text(s.icon).font(.title2); VStack(alignment:.leading) { Text("Spice: \(s.en)").font(.subheadline).fontWeight(.bold).foregroundStyle(s.color); Text(s.zh).font(.caption).foregroundStyle(Theme.ink3) } }.padding(14).frame(maxWidth:.infinity,alignment:.leading).background(s.color.opacity(0.07)).cornerRadius(12) }
                    if !chef.dietaryList.isEmpty { tBlock("Ingredients", chef.dietaryList.map{"\($0.emoji) \($0.en)"}, Theme.sign) }
                    if !chef.staffNote.isEmpty { VStack(alignment:.leading,spacing:6) { Text("Staff Note").font(.caption).fontWeight(.bold).foregroundStyle(Theme.ink4); Text(chef.staffNote).font(.subheadline).italic() }.padding(14).background(Theme.paper).cornerRadius(12) }
                }.padding(20)
            }.toolbar { ToolbarItem(placement: .topBarLeading) { bk(Theme.accent, "Done") { onDone() } } }
        }
    }

    private func tBlock(_ title: String, _ items: [String], _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption).fontWeight(.heavy).foregroundStyle(color)
            ForEach(items, id: \.self) { item in
                Text(item).font(.subheadline).fontWeight(.semibold).foregroundStyle(color == Theme.alert ? Color(hex:"9B3A30") : color == Theme.accent ? Color(hex:"1D5C53") : Theme.ink2)
                    .padding(.horizontal,10).padding(.vertical,5).background(color.opacity(0.1)).cornerRadius(8)
            }
        }.padding(14).frame(maxWidth:.infinity,alignment:.leading).background(color.opacity(0.05)).cornerRadius(12)
        .overlay(alignment:.leading) { Rectangle().fill(color).frame(width:4) }.cornerRadius(12)
    }

    private func bk(_ c: Color, _ l: String, a: @escaping () -> Void) -> some View {
        Button(action: a) { HStack(spacing:4) { Image(systemName:"chevron.left").font(.caption.weight(.bold)); Text(l).font(.subheadline.weight(.semibold)) }.foregroundStyle(c) }
    }
    private func pgH(_ t: String, _ s: String, _ n: String, back: @escaping () -> Void) -> some View {
        VStack(alignment:.leading,spacing:4) { HStack { bk(Theme.accent, "返回") { back() }; Spacer(); Text(n).font(.subheadline).foregroundStyle(Theme.ink4) }.padding(.top,16).padding(.bottom,4); Text(t).font(.title3).fontWeight(.heavy); Text(s).font(.subheadline).foregroundStyle(Theme.ink3) }.padding(.horizontal,24).padding(.bottom,6)
    }
    private func cfm(_ a: @escaping () -> Void) -> some View {
        Button(action: a) { Text("确认 · Confirm").font(.headline).foregroundStyle(.white).frame(maxWidth:.infinity).padding(15).background(Theme.ink).cornerRadius(14) }.padding(.horizontal,24).padding(.bottom,28).padding(.top,12)
    }
}
