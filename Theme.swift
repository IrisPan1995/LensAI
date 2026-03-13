import SwiftUI

struct Theme {
    static let ink = Color(hex: "1A1A1A")
    static let ink2 = Color(hex: "222222")
    static let ink3 = Color(hex: "555555")
    static let ink4 = Color(hex: "777777")
    static let paper = Color(hex: "F8F6F3")
    static let paper2 = Color(hex: "F2EFE9")
    static let paper3 = Color(hex: "E8E4DD")
    static let accent = Color(hex: "2D7A6F")
    static let accent2 = Color(hex: "3ABFA8")
    static let alert = Color(hex: "C4564A")
    static let food = Color(hex: "C67B3C")
    static let sign = Color(hex: "4A7FB5")
    static let product = Color(hex: "7B5EA7")
    static let doc = Color(hex: "B86B4A")

    static func categoryColor(_ cat: String) -> Color {
        switch cat.lowercased() {
        case "food": return food; case "sign": return sign
        case "product": return product; case "document": return doc
        default: return ink3
        }
    }
    static func categoryEmoji(_ cat: String) -> String {
        switch cat.lowercased() {
        case "food": return "🍜"; case "sign": return "🚧"
        case "product": return "💊"; case "document": return "📄"
        default: return "📸"
        }
    }
}

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var i: UInt64 = 0; Scanner(string: h).scanHexInt64(&i)
        self.init(.sRGB,
                  red: Double((i >> 16) & 0xFF) / 255,
                  green: Double((i >> 8) & 0xFF) / 255,
                  blue: Double(i & 0xFF) / 255)
    }
}
