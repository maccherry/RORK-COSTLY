import Foundation

nonisolated struct LogEntry: Identifiable, Codable, Sendable {
    let id: UUID
    let activityId: String
    let activityName: String
    let activityIcon: String
    let minutesDelta: Int
    let timestamp: Date

    init(activity: Activity, timestamp: Date = .now) {
        self.id = UUID()
        self.activityId = activity.id
        self.activityName = activity.name
        self.activityIcon = activity.icon
        self.minutesDelta = activity.minutesDelta
        self.timestamp = timestamp
    }

    init(id: UUID, activityId: String, activityName: String, activityIcon: String, minutesDelta: Int, timestamp: Date) {
        self.id = id
        self.activityId = activityId
        self.activityName = activityName
        self.activityIcon = activityIcon
        self.minutesDelta = minutesDelta
        self.timestamp = timestamp
    }

    var isPositive: Bool { minutesDelta >= 0 }
    var formattedDelta: String {
        minutesDelta >= 0 ? "+\(minutesDelta)" : "\(minutesDelta)"
    }
}
