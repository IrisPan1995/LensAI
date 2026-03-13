import SwiftUI
import SwiftData
import Combine
import Foundation

struct ScanResult: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String = ""
    var zhName: String = ""
    var subtitle: String = ""
    var category: String = ""
    var what: String = ""
    var context: String = ""
    var tips: String = ""
    var commonAllergens: String = ""
    var imageData: Data?
    var timestamp: Date = Date()
    var isFood: Bool { category.lowercased() == "food" }
}

@Model class HistoryItem {
    var scanId: UUID = UUID()
    var title: String = ""
    var zhName: String = ""
    var subtitle: String = ""
    var category: String = ""
    var what: String = ""
    var context: String = ""
    var tips: String = ""
    var commonAllergens: String = ""
    var imageData: Data?
    var timestamp: Date = Date()

    init(from r: ScanResult) {
        scanId = r.id; title = r.title; zhName = r.zhName; subtitle = r.subtitle
        category = r.category; what = r.what; context = r.context; tips = r.tips
        commonAllergens = r.commonAllergens; imageData = r.imageData; timestamp = r.timestamp
    }
    var asScanResult: ScanResult {
        var r = ScanResult(); r.id = scanId; r.title = title; r.zhName = zhName
        r.subtitle = subtitle; r.category = category; r.what = what; r.context = context
        r.tips = tips; r.commonAllergens = commonAllergens; r.imageData = imageData
        r.timestamp = timestamp; return r
    }
}

class ChefConfirmation: ObservableObject {
    @Published var allergens: [String: AllergenState] = [:]
    @Published var spiceLevel: SpiceLevel?
    @Published var dietary: Set<String> = []
    @Published var customAnswers: Set<String> = []
    @Published var staffNote: String = ""
    var hasData: Bool { !allergens.isEmpty || spiceLevel != nil || !dietary.isEmpty || !customAnswers.isEmpty || !staffNote.isEmpty }
    func reset() { allergens = [:]; spiceLevel = nil; dietary = []; customAnswers = []; staffNote = "" }
    var containsList: [Allergen] { Allergen.all.filter { allergens[$0.id] == .contains } }
    var safeList: [Allergen] { Allergen.all.filter { allergens[$0.id] == .doesNotContain } }
    var dietaryList: [DietaryItem] { DietaryItem.all.filter { dietary.contains($0.id) } }
    var customList: [CustomQuestion] { CustomQuestion.all.filter { customAnswers.contains($0.id) } }
}

enum AllergenState { case contains, doesNotContain }

struct Allergen: Identifiable {
    let id: String; let zh: String; let en: String; let emoji: String; var sub: String? = nil
    static let all: [Allergen] = [
        Allergen(id: "peanut", zh: "花生", en: "Peanut", emoji: "🥜"),
        Allergen(id: "treenut", zh: "坚果类", en: "Tree Nuts", emoji: "🌰", sub: "核桃/腰果/杏仁"),
        Allergen(id: "shellfish", zh: "甲壳类", en: "Shellfish", emoji: "🦐", sub: "虾/蟹/龙虾"),
        Allergen(id: "fish", zh: "鱼类", en: "Fish", emoji: "🐟"),
        Allergen(id: "egg", zh: "鸡蛋", en: "Egg", emoji: "🥚"),
        Allergen(id: "milk", zh: "牛奶/乳制品", en: "Dairy", emoji: "🥛"),
        Allergen(id: "soy", zh: "大豆", en: "Soy", emoji: "🫘"),
        Allergen(id: "wheat", zh: "小麦/面筋", en: "Wheat/Gluten", emoji: "🌾"),
        Allergen(id: "sesame", zh: "芝麻", en: "Sesame", emoji: "🫗"),
        Allergen(id: "celery", zh: "芹菜", en: "Celery", emoji: "🥬"),
        Allergen(id: "mustard", zh: "芥末", en: "Mustard", emoji: "🟡"),
        Allergen(id: "sulfite", zh: "亚硫酸盐", en: "Sulfites", emoji: "🧪", sub: "常见于酒/干果"),
    ]
}

enum SpiceLevel: String, CaseIterable, Identifiable {
    case none, mild, medium, hot, extreme
    var id: String { rawValue }
    var zh: String { switch self { case .none:"不辣"; case .mild:"微辣"; case .medium:"中辣"; case .hot:"辣"; case .extreme:"特辣" } }
    var en: String { switch self { case .none:"No spice"; case .mild:"Mild"; case .medium:"Medium"; case .hot:"Hot"; case .extreme:"Extra hot" } }
    var icon: String { switch self { case .none:"❄️"; case .mild:"🌶️"; case .medium:"🌶️🌶️"; case .hot:"🌶️🌶️🌶️"; case .extreme:"🔥" } }
    var color: Color { switch self { case .none:Color(hex:"4A7FB5"); case .mild:Color(hex:"2D7A6F"); case .medium:Color(hex:"C67B3C"); case .hot:Color(hex:"C4564A"); case .extreme:Color(hex:"8B2020") } }
}

struct DietaryItem: Identifiable {
    let id: String; let zh: String; let en: String; let emoji: String
    static let all: [DietaryItem] = [
        DietaryItem(id: "pork", zh: "含猪肉", en: "Contains pork", emoji: "🐷"),
        DietaryItem(id: "beef", zh: "含牛肉", en: "Contains beef", emoji: "🐄"),
        DietaryItem(id: "lard", zh: "用猪油炒", en: "Cooked in lard", emoji: "🫙"),
        DietaryItem(id: "alcohol", zh: "含酒精", en: "Contains alcohol", emoji: "🍺"),
        DietaryItem(id: "msg", zh: "含味精", en: "Contains MSG", emoji: "🧂"),
        DietaryItem(id: "cilantro", zh: "含香菜", en: "Contains cilantro", emoji: "🌿"),
        DietaryItem(id: "sichuan", zh: "含花椒（麻）", en: "Sichuan peppercorn", emoji: "⚡"),
        DietaryItem(id: "sugar", zh: "偏甜", en: "Sweet", emoji: "🍬"),
    ]
}

struct CustomQuestion: Identifiable {
    let id: String; let zh: String; let en: String
    static let all: [CustomQuestion] = [
        CustomQuestion(id: "removable", zh: "可以去掉某些食材吗？", en: "Can ingredients be removed?"),
        CustomQuestion(id: "less_oil", zh: "可以少油少盐吗？", en: "Less oil / less salt?"),
        CustomQuestion(id: "half", zh: "可以做半份吗？", en: "Half portion available?"),
    ]
}
