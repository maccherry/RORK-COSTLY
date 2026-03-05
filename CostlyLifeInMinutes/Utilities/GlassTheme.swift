import SwiftUI

enum GlassTheme {
    static let positive = Color(red: 0.2, green: 0.75, blue: 0.5)
    static let negative = Color(red: 0.9, green: 0.32, blue: 0.35)
    static let neutral = Color(red: 0.55, green: 0.55, blue: 0.6)

    static let bgPrimary = Color(red: 0.945, green: 0.94, blue: 0.955)
    static let bgCard = Color.white
    static let bgCardSecondary = Color(red: 0.97, green: 0.965, blue: 0.975)
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.12)
    static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.45)
    static let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.65)
    static let separator = Color(red: 0.88, green: 0.88, blue: 0.9)
    static let accent = Color(red: 0.42, green: 0.35, blue: 0.65)

    static func minuteColor(_ value: Int) -> Color {
        if value > 0 { return positive }
        if value < 0 { return negative }
        return neutral
    }

    static func formatMinutes(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        if value < 0 { return "\(value)" }
        return "0"
    }
}
