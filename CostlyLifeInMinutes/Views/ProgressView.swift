import SwiftUI

struct LifeProgressView: View {
    let store: DataStore
    let healthKit: HealthKitService
    @State private var appeared: Bool = false
    @State private var animateProgress: Bool = false
    @State private var showShareSheet: Bool = false
    @State private var shareImage: UIImage?

    private var totalGained: Int { store.totalMinutesGained }
    private var totalLost: Int { abs(store.totalMinutesLost) }
    private var netMinutes: Int { store.allTimeNetMinutes }
    private var todayNet: Int { store.todayNetMinutes + healthKit.healthMinutesBalance }

    private var bioAge: Double {
        store.profile.biologicalAge(netMinutes: store.allTimeNetMinutes + healthKit.healthMinutesBalance)
    }

    private var costlyAge: Double {
        if healthKit.isAuthorized {
            return store.profile.costlyAge(
                netMinutes: store.allTimeNetMinutes,
                healthMinutes: healthKit.healthMinutesBalance,
                steps: healthKit.stepCount,
                sleepHours: healthKit.sleepHours,
                activeMinutes: healthKit.activeMinutes
            )
        }
        return store.profile.baselineCostlyAge
    }

    private var streakDays: Int {
        var count = 0
        let calendar = Calendar.current
        var checkDate = Date.now
        for _ in 0..<365 {
            let dayEntries = store.entries.filter { calendar.isDate($0.timestamp, inSameDayAs: checkDate) }
            let dayNet = dayEntries.reduce(0) { $0 + $1.minutesDelta }
            if dayNet > 0 {
                count += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return count
    }

    private var weeklyData: [(day: String, gained: Int, lost: Int)] {
        let calendar = Calendar.current
        let today = Date.now
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 2), to: today) ?? today
        let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) ?? today
            let dayEntries = store.entries.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            let gained = dayEntries.filter { $0.minutesDelta > 0 }.reduce(0) { $0 + $1.minutesDelta }
            let lost = abs(dayEntries.filter { $0.minutesDelta < 0 }.reduce(0) { $0 + $1.minutesDelta })
            return (dayLetters[offset], gained, lost)
        }
    }

    private var progressFraction: Double {
        let total = Double(totalGained + totalLost)
        guard total > 0 else { return 0.5 }
        return Double(totalGained) / total
    }

    var body: some View {
        ZStack {
            GlassTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                        .padding(.top, 12)
                        .premiumStagger(appeared: appeared, index: 0)

                    ageCard
                        .premiumStagger(appeared: appeared, index: 1)

                    mainProgressRing
                        .premiumStagger(appeared: appeared, index: 2)

                    netBalanceBar
                        .premiumStagger(appeared: appeared, index: 3)

                    if healthKit.isAuthorized {
                        healthCard
                            .premiumStagger(appeared: appeared, index: 4)
                    }

                    weeklyChart
                        .premiumStagger(appeared: appeared, index: 5)

                    lifeStatsCard
                        .premiumStagger(appeared: appeared, index: 6)

                    milestoneSection
                        .premiumStagger(appeared: appeared, index: 7)

                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { appeared = true }
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7).delay(0.3)) { animateProgress = true }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Progress")
                    .font(.satoshi(.bold, size: 28))
                    .foregroundStyle(GlassTheme.textPrimary)
                Text("Your life in minutes")
                    .font(.satoshi(.regular, size: 13))
                    .foregroundStyle(GlassTheme.textTertiary)
            }
            Spacer()

            if streakDays > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.2))
                    Text("\(streakDays)d streak")
                        .font(.satoshi(.bold, size: 12))
                        .foregroundStyle(GlassTheme.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 4)
    }

    private var ageCard: some View {
        HStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("CHRONOLOGICAL")
                    .font(.satoshi(.bold, size: 8))
                    .foregroundStyle(GlassTheme.textTertiary)
                    .tracking(1)
                Text(String(format: "%.1f", store.profile.preciseAge))
                    .font(.satoshi(.light, size: 30))
                    .foregroundStyle(GlassTheme.textSecondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(GlassTheme.separator)
                .frame(width: 0.5, height: 48)

            VStack(spacing: 6) {
                Text("BIOLOGICAL")
                    .font(.satoshi(.bold, size: 8))
                    .foregroundStyle(GlassTheme.textTertiary)
                    .tracking(1)
                Text(String(format: "%.1f", bioAge))
                    .font(.satoshi(.light, size: 30))
                    .foregroundStyle(bioAge <= store.profile.preciseAge ? GlassTheme.positive : GlassTheme.negative)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 22)
        .glassCard(cornerRadius: 18)
    }

    private var mainProgressRing: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(GlassTheme.separator.opacity(0.3), lineWidth: 10)
                    .frame(width: 200, height: 200)

                Circle()
                    .trim(from: 0, to: animateProgress ? progressFraction : 0)
                    .stroke(
                        AngularGradient(
                            colors: [
                                GlassTheme.positive.opacity(0.4),
                                GlassTheme.positive,
                                GlassTheme.positive.opacity(0.8)
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: animateProgress ? progressFraction : 1, to: 1)
                    .stroke(
                        AngularGradient(
                            colors: [
                                GlassTheme.negative.opacity(0.4),
                                GlassTheme.negative,
                                GlassTheme.negative.opacity(0.8)
                            ],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text(GlassTheme.formatMinutes(netMinutes))
                        .font(.satoshi(.light, size: 48))
                        .foregroundStyle(GlassTheme.minuteColor(netMinutes))
                        .contentTransition(.numericText())
                        .monospacedDigit()

                    Text("NET MINUTES")
                        .font(.satoshi(.bold, size: 8))
                        .foregroundStyle(GlassTheme.textTertiary)
                        .tracking(2)
                }
            }

            HStack(spacing: 28) {
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Circle().fill(GlassTheme.positive).frame(width: 6, height: 6)
                        Text("+\(totalGained)")
                            .font(.satoshi(.bold, size: 16))
                            .foregroundStyle(GlassTheme.positive)
                            .monospacedDigit()
                    }
                    Text("Gained")
                        .font(.satoshi(.regular, size: 10))
                        .foregroundStyle(GlassTheme.textTertiary)
                }

                Rectangle()
                    .fill(GlassTheme.separator)
                    .frame(width: 1, height: 28)

                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Circle().fill(GlassTheme.negative).frame(width: 6, height: 6)
                        Text("-\(totalLost)")
                            .font(.satoshi(.bold, size: 16))
                            .foregroundStyle(GlassTheme.negative)
                            .monospacedDigit()
                    }
                    Text("Lost")
                        .font(.satoshi(.regular, size: 10))
                        .foregroundStyle(GlassTheme.textTertiary)
                }
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private var netBalanceBar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TODAY'S BALANCE")
                    .font(.satoshi(.bold, size: 9))
                    .foregroundStyle(GlassTheme.textTertiary)
                    .tracking(1.5)
                Spacer()
                Text(GlassTheme.formatMinutes(todayNet))
                    .font(.satoshi(.bold, size: 18))
                    .foregroundStyle(GlassTheme.minuteColor(todayNet))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            GeometryReader { geometry in
                let width = geometry.size.width
                let todayGained = store.todayEntries.filter { $0.minutesDelta > 0 }.reduce(0) { $0 + $1.minutesDelta }
                let todayLostAbs = abs(store.todayEntries.filter { $0.minutesDelta < 0 }.reduce(0) { $0 + $1.minutesDelta })
                let healthBonus = max(healthKit.healthMinutesBalance, 0)
                let effectiveGained = todayGained + healthBonus
                let total = max(effectiveGained + todayLostAbs, 1)
                let gainedWidth = CGFloat(effectiveGained) / CGFloat(total) * width

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(GlassTheme.negative.opacity(0.2))
                        .frame(height: 8)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [GlassTheme.positive.opacity(0.6), GlassTheme.positive],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animateProgress ? max(gainedWidth, 4) : 0, height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Label("Gained", systemImage: "arrow.up.right")
                    .font(.satoshi(.regular, size: 10))
                    .foregroundStyle(GlassTheme.positive)
                Spacer()
                Label("Lost", systemImage: "arrow.down.right")
                    .font(.satoshi(.regular, size: 10))
                    .foregroundStyle(GlassTheme.negative)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("HEALTH DATA")

            VStack(spacing: 0) {
                infoRow(icon: "figure.walk", label: "Steps Today", value: "\(healthKit.stepCount)", color: GlassTheme.accent)
                infoDivider
                infoRow(icon: "flame.fill", label: "Active Minutes", value: "\(healthKit.activeMinutes) min", color: GlassTheme.positive)
                if healthKit.sleepHours > 0 {
                    infoDivider
                    infoRow(icon: "bed.double.fill", label: "Sleep", value: String(format: "%.1f hrs", healthKit.sleepHours), color: healthKit.sleepHours >= 7 ? GlassTheme.positive : GlassTheme.negative)
                }
                if healthKit.heartRate > 0 {
                    infoDivider
                    infoRow(icon: "heart.fill", label: "Heart Rate", value: "\(Int(healthKit.heartRate)) bpm", color: Color(red: 0.9, green: 0.35, blue: 0.4))
                }
                infoDivider
                infoRow(icon: "plus.circle.fill", label: "Health Bonus", value: GlassTheme.formatMinutes(healthKit.healthMinutesBalance) + " min", color: GlassTheme.minuteColor(healthKit.healthMinutesBalance))
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("THIS WEEK")
                    .font(.satoshi(.bold, size: 9))
                    .foregroundStyle(GlassTheme.textTertiary)
                    .tracking(1.5)
                Spacer()
                Text(GlassTheme.formatMinutes(store.weekNetMinutes))
                    .font(.satoshi(.bold, size: 14))
                    .foregroundStyle(GlassTheme.minuteColor(store.weekNetMinutes))
                    .monospacedDigit()
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 4) {
                        Spacer()

                        let maxVal = max(weeklyData.map { max($0.gained, $0.lost) }.max() ?? 1, 1)

                        if data.gained > 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [GlassTheme.positive.opacity(0.3), GlassTheme.positive.opacity(0.7)],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: animateProgress ? max(CGFloat(data.gained) / CGFloat(maxVal) * 60, 4) : 0)
                        }

                        if data.lost > 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [GlassTheme.negative.opacity(0.3), GlassTheme.negative.opacity(0.7)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: animateProgress ? max(CGFloat(data.lost) / CGFloat(maxVal) * 60, 4) : 0)
                        }

                        if data.gained == 0 && data.lost == 0 {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(GlassTheme.separator.opacity(0.3))
                                .frame(height: 4)
                        }

                        Text(data.day)
                            .font(.satoshi(.medium, size: 10))
                            .foregroundStyle(GlassTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }

    private var lifeStatsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("LIFE STATS")

            VStack(spacing: 0) {
                infoRow(icon: "arrow.up", label: "Minutes Gained", value: "+\(store.totalMinutesGained)", color: GlassTheme.positive)
                infoDivider
                infoRow(icon: "arrow.down", label: "Minutes Lost", value: "\(store.totalMinutesLost)", color: GlassTheme.negative)
                infoDivider
                infoRow(icon: "equal", label: "Net Balance", value: formatSigned(store.allTimeNetMinutes), color: GlassTheme.minuteColor(store.allTimeNetMinutes))
                infoDivider

                let days = Double(store.allTimeNetMinutes) / 1440.0
                infoRow(
                    icon: "calendar",
                    label: days >= 0 ? "Days Added" : "Days Removed",
                    value: String(format: "%+.1f", days),
                    color: GlassTheme.minuteColor(store.allTimeNetMinutes)
                )
                infoDivider

                let remaining = store.profile.estimatedLifeMinutesRemaining
                infoRow(icon: "hourglass", label: "Est. Life Remaining", value: formatLargeMinutes(remaining), color: GlassTheme.textSecondary)
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var milestoneSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("MILESTONES")
                .font(.satoshi(.bold, size: 9))
                .foregroundStyle(GlassTheme.textTertiary)
                .tracking(1.5)

            VStack(spacing: 0) {
                milestoneRow(
                    icon: "star",
                    title: "First Log",
                    detail: "Log your first activity",
                    achieved: !store.entries.isEmpty,
                    isLast: false
                )
                milestoneRow(
                    icon: "flame",
                    title: "3-Day Streak",
                    detail: "3 consecutive positive days",
                    achieved: streakDays >= 3,
                    isLast: false
                )
                milestoneRow(
                    icon: "trophy",
                    title: "100 Minutes Gained",
                    detail: "Accumulate 100+ positive minutes",
                    achieved: totalGained >= 100,
                    isLast: false
                )
                milestoneRow(
                    icon: "bolt.shield",
                    title: "Week Warrior",
                    detail: "7 consecutive positive days",
                    achieved: streakDays >= 7,
                    isLast: true
                )
            }
            .glassCard(cornerRadius: 16)
        }
    }

    private func infoRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.satoshi(.regular, size: 13))
                .foregroundStyle(GlassTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.satoshi(.medium, size: 14))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var infoDivider: some View {
        Rectangle()
            .fill(GlassTheme.separator.opacity(0.5))
            .frame(height: 0.5)
            .padding(.leading, 48)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.satoshi(.bold, size: 9))
            .foregroundStyle(GlassTheme.textTertiary)
            .tracking(1.5)
    }

    private func milestoneRow(icon: String, title: String, detail: String, achieved: Bool, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: achieved ? "\(icon).fill" : icon)
                    .font(.system(size: 14, weight: achieved ? .medium : .light))
                    .foregroundStyle(achieved ? GlassTheme.accent : GlassTheme.textTertiary.opacity(0.4))
                    .frame(width: 32, height: 32)
                    .background(achieved ? GlassTheme.accent.opacity(0.08) : GlassTheme.separator.opacity(0.15))
                    .clipShape(.rect(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.satoshi(.medium, size: 14))
                        .foregroundStyle(achieved ? GlassTheme.textPrimary : GlassTheme.textTertiary)
                    Text(detail)
                        .font(.satoshi(.regular, size: 11))
                        .foregroundStyle(GlassTheme.textTertiary)
                }

                Spacer()

                if achieved {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(GlassTheme.positive)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)

            if !isLast {
                Rectangle()
                    .fill(GlassTheme.separator.opacity(0.5))
                    .frame(height: 0.5)
                    .padding(.leading, 58)
            }
        }
    }

    private func formatSigned(_ value: Int) -> String {
        value >= 0 ? "+\(value)" : "\(value)"
    }

    private func formatLargeMinutes(_ minutes: Int) -> String {
        let years = minutes / 525960
        let remainingMonths = (minutes % 525960) / 43830
        return "\(years)y \(remainingMonths)m"
    }
}
