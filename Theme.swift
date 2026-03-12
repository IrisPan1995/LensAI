import SwiftUI

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design Tokens

enum Theme {
    static let accent    = Color(hex: "2D7A6F")
    static let accent2   = Color(hex: "3ABFA8")
    static let alert     = Color(hex: "C4564A")
    static let paper     = Color(hex: "F8F6F3")
    static let paper3    = Color(hex: "E8E4DD")
    static let ink       = Color(hex: "1A1A1A")
    static let ink2      = Color(hex: "222222")
    static let ink3      = Color(hex: "555555")
    static let ink4      = Color(hex: "777777")

    static let food      = Color(hex: "C67B3C")
    static let sign      = Color(hex: "4A7FB5")
    static let product   = Color(hex: "7B5EA7")
    static let document  = Color(hex: "B86B4A")

    static let allergenGray = Color(hex: "C8C4BD")

    static func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "food":     return food
        case "sign":     return sign
        case "product":  return product
        case "document": return document
        default:         return ink3
        }
    }

    static func categoryEmoji(_ category: String) -> String {
        switch category.lowercased() {
        case "food":     return "🍜"
        case "sign":     return "🚇"
        case "product":  return "💊"
        case "document": return "📄"
        case "place":    return "📍"
        default:         return "📷"
        }
    }
}
