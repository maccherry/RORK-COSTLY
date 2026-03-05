import Foundation

nonisolated struct Activity: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let icon: String
    let minutesDelta: Int
    let category: ActivityCategory

    var isPositive: Bool { minutesDelta >= 0 }
    var formattedDelta: String {
        minutesDelta >= 0 ? "+\(minutesDelta)" : "\(minutesDelta)"
    }
}

nonisolated enum ActivityCategory: String, Codable, CaseIterable, Sendable {
    case substance = "Substances"
    case food = "Food & Drink"
    case exercise = "Exercise"
    case wellness = "Wellness"
    case sleep = "Sleep"
    case lifestyle = "Lifestyle"
}
