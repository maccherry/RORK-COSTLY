import SwiftUI

enum GlassTheme {
    static let positive = Color(red: 0.45, green: 0.85, blue: 0.55)
    static let negative = Color(red: 0.95, green: 0.4, blue: 0.4)
    static let neutral = Color.white.opacity(0.35)

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
