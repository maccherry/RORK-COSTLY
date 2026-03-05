import Foundation
import SwiftUI

@Observable
@MainActor
class DataStore {
    var profile: UserProfile
    var entries: [LogEntry]

    private let profileKey = "costly_user_profile"
    private let entriesKey = "costly_log_entries"

    init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = UserProfile()
        }

        if let data = UserDefaults.standard.data(forKey: entriesKey),
           let decoded = try? JSONDecoder().decode([LogEntry].self, from: data) {
            self.entries = decoded
        } else {
            self.entries = []
        }
    }

    func logActivity(_ activity: Activity) {
        let entry = LogEntry(activity: activity)
        entries.insert(entry, at: 0)
        saveEntries()
    }

    func deleteEntry(_ entry: LogEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }

    func completeOnboarding(name: String, birthDate: Date) {
        profile.name = name
        profile.birthDate = birthDate
        profile.hasCompletedOnboarding = true
        profile.memberSince = .now
        saveProfile()
    }

    func setSubscriptionActive(_ active: Bool) {
        profile.hasActiveSubscription = active
        saveProfile()
    }

    func redeemOKX() {
        profile.okxRedeemed = true
        profile.hasActiveSubscription = true
        saveProfile()
    }

    func useFreeScan() {
        profile.freeScansUsed += 1
        saveProfile()
    }

    func connectWallet() {
        profile.walletConnected = true
        saveProfile()
    }

    var todayEntries: [LogEntry] {
        entries.filter { Calendar.current.isDateInToday($0.timestamp) }
    }

    var todayNetMinutes: Int {
        todayEntries.reduce(0) { $0 + $1.minutesDelta }
    }

    var weekEntries: [LogEntry] {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
        return entries.filter { $0.timestamp >= weekAgo }
    }

    var weekNetMinutes: Int {
        weekEntries.reduce(0) { $0 + $1.minutesDelta }
    }

    var allTimeNetMinutes: Int {
        entries.reduce(0) { $0 + $1.minutesDelta }
    }

    var totalMinutesGained: Int {
        entries.filter { $0.minutesDelta > 0 }.reduce(0) { $0 + $1.minutesDelta }
    }

    var totalMinutesLost: Int {
        entries.filter { $0.minutesDelta < 0 }.reduce(0) { $0 + $1.minutesDelta }
    }

    var usdcBalance: Double {
        let positiveMinutes = max(allTimeNetMinutes, 0)
        return Double(positiveMinutes) * 0.01
    }

    private func saveProfile() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }

    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: entriesKey)
        }
    }
}
