import Foundation

nonisolated struct UserProfile: Codable, Sendable {
    var name: String
    var birthDate: Date
    var memberSince: Date
    var hasCompletedOnboarding: Bool
    var hasActiveSubscription: Bool
    var okxRedeemed: Bool
    var walletConnected: Bool

    init(
        name: String = "",
        birthDate: Date = Date(timeIntervalSince1970: 631152000),
        memberSince: Date = .now,
        hasCompletedOnboarding: Bool = false,
        hasActiveSubscription: Bool = false,
        okxRedeemed: Bool = false,
        walletConnected: Bool = false
    ) {
        self.name = name
        self.birthDate = birthDate
        self.memberSince = memberSince
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasActiveSubscription = hasActiveSubscription
        self.okxRedeemed = okxRedeemed
        self.walletConnected = walletConnected
    }

    var estimatedLifeMinutesRemaining: Int {
        let averageLifeExpectancy: Double = 78.5
        let ageInYears = Calendar.current.dateComponents([.year], from: birthDate, to: .now).year ?? 30
        let remainingYears = max(averageLifeExpectancy - Double(ageInYears), 0)
        return Int(remainingYears * 365.25 * 24 * 60)
    }

    var ageInYears: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: .now).year ?? 30
    }

    var preciseAge: Double {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: birthDate, to: .now)
        let years = Double(components.year ?? 30)
        let months = Double(components.month ?? 0)
        let days = Double(components.day ?? 0)
        return years + (months / 12.0) + (days / 365.25)
    }

    func biologicalAge(netMinutes: Int) -> Double {
        let chronological = preciseAge
        let daysDelta = Double(netMinutes) / 1440.0
        let yearsDelta = daysDelta / 365.25
        return max(chronological - yearsDelta, 0)
    }

    func costlyAge(netMinutes: Int, healthMinutes: Int, steps: Int, sleepHours: Double, activeMinutes: Int) -> Double {
        let chronological = preciseAge
        var modifier: Double = 0

        let netDays = Double(netMinutes) / 1440.0
        modifier -= netDays / 365.25

        let healthDays = Double(healthMinutes) / 1440.0
        modifier -= healthDays / 365.25

        if steps >= 10000 {
            modifier -= 0.003
        } else if steps >= 7000 {
            modifier -= 0.001
        } else if steps < 3000 && steps > 0 {
            modifier += 0.001
        }

        if sleepHours >= 7.0 && sleepHours <= 9.0 {
            modifier -= 0.002
        } else if sleepHours > 0 && sleepHours < 5.5 {
            modifier += 0.003
        }

        if activeMinutes >= 30 {
            modifier -= 0.002
        }

        return max(chronological + modifier, 0)
    }

    var baselineCostlyAge: Double {
        return preciseAge + 0.3
    }
}
