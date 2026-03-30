import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Scan Result (API Response)

struct ScanResult: Codable {
    let title: String
    let zhName: String
    let subtitle: String
    let category: String
    let what: String
    let context: String
    let tips: String
    let commonAllergens: [String]

    static let placeholder = ScanResult(
        title: "", zhName: "", subtitle: "", category: "Other",
        what: "", context: "", tips: "", commonAllergens: []
    )
}

// MARK: - History Item (SwiftData)

@Model
final class HistoryItem {
    var id: UUID
    var title: String
    var zhName: String
    var subtitle: String
    var category: String
    var what: String
    var context: String
    var tips: String
    var commonAllergens: [String]
    @Attribute(.externalStorage) var imageData: Data?
    var date: Date

    init(
        title: String,
        zhName: String,
        subtitle: String,
        category: String,
        what: String,
        context: String,
        tips: String,
        commonAllergens: [String],
        imageData: Data?,
        date: Date = .now
    ) {
        self.id = UUID()
        self.title = title
        self.zhName = zhName
        self.subtitle = subtitle
        self.category = category
        self.what = what
        self.context = context
        self.tips = tips
        self.commonAllergens = commonAllergens
        self.imageData = imageData
        self.date = date
    }
}

// MARK: - Allergen System

enum AllergenState: Int, Codable {
    case unknown = 0
    case contains = 1
    case doesNotContain = 2

    mutating func toggle() {
        switch self {
        case .unknown:        self = .contains
        case .contains:       self = .doesNotContain
        case .doesNotContain: self = .unknown
        }
    }
}

struct Allergen: Identifiable {
    let id: Int
    let name: String
    let zhName: String
    let emoji: String

    static let all: [Allergen] = [
        Allergen(id: 0,  name: "Peanut",          zhName: "花生",             emoji: "🥜"),
        Allergen(id: 1,  name: "Tree Nuts",        zhName: "坚果类（核桃/腰果/杏仁）", emoji: "🌰"),
        Allergen(id: 2,  name: "Shellfish",         zhName: "甲壳类（虾/蟹/龙虾）",  emoji: "🦐"),
        Allergen(id: 3,  name: "Fish",              zhName: "鱼类",             emoji: "🐟"),
        Allergen(id: 4,  name: "Egg",               zhName: "鸡蛋",             emoji: "🥚"),
        Allergen(id: 5,  name: "Milk / Dairy",      zhName: "牛奶/乳制品",        emoji: "🥛"),
        Allergen(id: 6,  name: "Soy",               zhName: "大豆",             emoji: "🫘"),
        Allergen(id: 7,  name: "Wheat / Gluten",    zhName: "小麦/面筋",         emoji: "🌾"),
        Allergen(id: 8,  name: "Sesame",            zhName: "芝麻",             emoji: "🫗"),
        Allergen(id: 9,  name: "Celery",            zhName: "芹菜",             emoji: "🥬"),
        Allergen(id: 10, name: "Mustard",           zhName: "芥末",             emoji: "🟡"),
        Allergen(id: 11, name: "Sulfites",          zhName: "亚硫酸盐（常见于酒/干果）", emoji: "🧪"),
    ]
}

// MARK: - Spice Level

enum SpiceLevel: Int, CaseIterable, Identifiable {
    case none = 0, mild, medium, hot, extreme

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .none:    return "不辣"
        case .mild:    return "微辣"
        case .medium:  return "中辣"
        case .hot:     return "辣"
        case .extreme: return "特辣"
        }
    }

    var englishLabel: String {
        switch self {
        case .none:    return "Not Spicy"
        case .mild:    return "Mild"
        case .medium:  return "Medium"
        case .hot:     return "Hot"
        case .extreme: return "Extra Hot"
        }
    }

    var emoji: String {
        switch self {
        case .none:    return "❄️"
        case .mild:    return "🌶️"
        case .medium:  return "🌶️🌶️"
        case .hot:     return "🌶️🌶️🌶️"
        case .extreme: return "🔥"
        }
    }

    var color: Color {
        switch self {
        case .none:    return Color(hex: "4A7FB5")
        case .mild:    return Color(hex: "2D7A6F")
        case .medium:  return Color(hex: "C67B3C")
        case .hot:     return Color(hex: "C4564A")
        case .extreme: return Color(hex: "8B2020")
        }
    }
}

// MARK: - Dietary Item

struct DietaryItem: Identifiable {
    let id: Int
    let name: String
    let zhName: String
    let emoji: String

    static let all: [DietaryItem] = [
        DietaryItem(id: 0, name: "Pork",              zhName: "含猪肉",   emoji: "🐷"),
        DietaryItem(id: 1, name: "Beef",              zhName: "含牛肉",   emoji: "🐄"),
        DietaryItem(id: 2, name: "Cooked in Lard",    zhName: "用猪油炒", emoji: "🫙"),
        DietaryItem(id: 3, name: "Alcohol",           zhName: "含酒精",   emoji: "🍺"),
        DietaryItem(id: 4, name: "MSG",               zhName: "含味精",   emoji: "🧂"),
        DietaryItem(id: 5, name: "Cilantro",          zhName: "含香菜",   emoji: "🌿"),
        DietaryItem(id: 6, name: "Sichuan Peppercorn",zhName: "含花椒（麻）", emoji: "⚡"),
        DietaryItem(id: 7, name: "Sweet",             zhName: "偏甜",     emoji: "🍬"),
    ]
}

// MARK: - Custom Question

struct CustomQuestion: Identifiable {
    let id: Int
    let zhText: String
    let enText: String
    var answer: Bool?

    static func defaults() -> [CustomQuestion] {
        [
            CustomQuestion(id: 0, zhText: "可以去掉某些食材吗？", enText: "Can some ingredients be removed?", answer: nil),
            CustomQuestion(id: 1, zhText: "可以少油少盐吗？",     enText: "Can it be made with less oil/salt?", answer: nil),
            CustomQuestion(id: 2, zhText: "可以做半份吗？",       enText: "Can I get a half portion?", answer: nil),
        ]
    }
}

// MARK: - Chef Confirmation (ObservableObject)

class ChefConfirmation: ObservableObject {
    @Published var allergenStates: [AllergenState]
    @Published var selectedSpice: SpiceLevel?
    @Published var dietarySelected: Set<Int>
    @Published var customQuestions: [CustomQuestion]
    @Published var freeNote: String

    @Published var allergenDone: Bool = false
    @Published var spiceDone: Bool = false
    @Published var dietaryDone: Bool = false
    @Published var customDone: Bool = false

    init() {
        self.allergenStates = Array(repeating: .unknown, count: Allergen.all.count)
        self.selectedSpice = nil
        self.dietarySelected = []
        self.customQuestions = CustomQuestion.defaults()
        self.freeNote = ""
    }

    func reset() {
        allergenStates = Array(repeating: .unknown, count: Allergen.all.count)
        selectedSpice = nil
        dietarySelected = []
        customQuestions = CustomQuestion.defaults()
        freeNote = ""
        allergenDone = false
        spiceDone = false
        dietaryDone = false
        customDone = false
    }
}
