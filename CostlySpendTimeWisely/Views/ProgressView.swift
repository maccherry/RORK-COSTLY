import SwiftUI

struct LifeProgressView: View {
    let store: DataStore
    let healthKit: HealthKitService
    @State private var appeared: Bool = false
    @State private var animateProgress: Bool = false
    @State private var selectedPeriod: TimePeriod = .week
    @State private var showFallbackShareSheet: Bool = false
    @State private var fallbackShareImage: UIImage?

    private enum TimePeriod: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case quarter = "90 Days"
        case all = "All time"
    }

    private var totalGained: Int { store.totalMinutesGained }
    private var totalLost: Int { abs(store.totalMinutesLost) }
    private var netMinutes: Int { store.allTimeNetMinutes }
    private var todayNet: Int { store.todayNetMinutes + healthKit.healthMinutesBalance }

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

    private var periodEntries: [LogEntry] {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: .now) ?? .now
            return store.entries.filter { $0.timestamp >= start }
        case .month:
            let start = calendar.date(byAdding: .day, value: -30, to: .now) ?? .now
            return store.entries.filter { $0.timestamp >= start }
        case .quarter:
            let start = calendar.date(byAdding: .day, value: -90, to: .now) ?? .now
            return store.entries.filter { $0.timestamp >= start }
        case .all:
            return store.entries
        }
    }

    private var periodNet: Int {
        periodEntries.reduce(0) { $0 + $1.minutesDelta }
    }

    private var periodGained: Int {
        periodEntries.filter { $0.minutesDelta > 0 }.reduce(0) { $0 + $1.minutesDelta }
    }

    private var periodLost: Int {
        abs(periodEntries.filter { $0.minutesDelta < 0 }.reduce(0) { $0 + $1.minutesDelta })
    }

    private var periodLogged: Int {
        periodEntries.count
    }

    private var progressFraction: Double {
        let total = Double(periodGained + periodLost)
        guard total > 0 else { return 0.5 }
        return Double(periodGained) / total
    }

    private var weeklyData: [(day: String, net: Int)] {
        let calendar = Calendar.current
        let today = Date.now
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 2), to: today) ?? today
        let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: startOfWeek) ?? today
            let dayEntries = store.entries.filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            let net = dayEntries.reduce(0) { $0 + $1.minutesDelta }
            return (dayLetters[offset], net)
        }
    }

    var body: some View {
        ZStack {
            GlassTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header
                        .padding(.top, 8)
                        .premiumStagger(appeared: appeared, index: 0)

                    summaryCards
                        .premiumStagger(appeared: appeared, index: 1)

                    periodPicker
                        .premiumStagger(appeared: appeared, index: 2)

                    progressRing
                        .premiumStagger(appeared: appeared, index: 3)

                    if healthKit.isAuthorized {
                        healthDashboard
                            .premiumStagger(appeared: appeared, index: 4)
                    }

                    weeklyChart
                        .premiumStagger(appeared: appeared, index: 5)

                    milestones
                        .premiumStagger(appeared: appeared, index: 6)

                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) { appeared = true }
            withAnimation(.spring(response: 1.4, dampingFraction: 0.7).delay(0.3)) { animateProgress = true }
        }
        .sheet(isPresented: $showFallbackShareSheet) {
            if let image = fallbackShareImage {
                ShareSheet(items: [image])
            }
        }
    }

    private var header: some View {
        HStack(alignment: .bottom) {
            Text("Progress")
                .font(.satoshi(.bold, size: 28))
                .foregroundStyle(GlassTheme.textPrimary)
            Spacer()
            if streakDays > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
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

    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryRingCard(
                icon: "scalemass",
                ringProgress: min(Double(periodLogged) / max(Double(periodLogged), 10.0), 1.0),
                ringColor: GlassTheme.textPrimary,
                title: "Net Minutes",
                value: formatNet(periodNet),
                valueColor: GlassTheme.minuteColor(periodNet)
            )

            summaryRingCard(
                icon: "apple.meditate",
                ringProgress: progressFraction,
                ringColor: GlassTheme.accent,
                title: "Activities",
                value: "\(periodLogged) logged",
                valueColor: GlassTheme.textPrimary
            )
        }
    }

    private func summaryRingCard(
        icon: String,
        ringProgress: Double,
        ringColor: Color,
        title: String,
        value: String,
        valueColor: Color
    ) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(GlassTheme.separator.opacity(0.5), lineWidth: 4)
                    .frame(width: 64, height: 64)

                Circle()
                    .trim(from: 0, to: animateProgress ? ringProgress : 0)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))

                Image(systemName: icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(GlassTheme.textPrimary)
            }

            Text(title)
                .font(.satoshi(.regular, size: 12))
                .foregroundStyle(GlassTheme.textTertiary)

            Text(value)
                .font(.satoshi(.bold, size: 16))
                .foregroundStyle(valueColor)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 20)
    }

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.satoshi(.bold, size: 13))
                        .foregroundStyle(selectedPeriod == period ? GlassTheme.textPrimary : GlassTheme.textTertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Group {
                                if selectedPeriod == period {
                                    Capsule()
                                        .fill(.white)
                                        .shadow(color: Color.black.opacity(0.06), radius: 4, y: 2)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(GlassTheme.separator.opacity(0.3), in: Capsule())
        .sensoryFeedback(.selection, trigger: selectedPeriod)
    }

    private var progressRing: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Balance")
                    .font(.satoshi(.bold, size: 18))
                    .foregroundStyle(GlassTheme.textPrimary)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(periodNet >= 0 ? GlassTheme.positive : GlassTheme.negative)
                        .frame(width: 6, height: 6)
                    Text("\(Int(progressFraction * 100))% positive")
                        .font(.satoshi(.medium, size: 12))
                        .foregroundStyle(GlassTheme.textTertiary)
                }
            }

            HStack(spacing: 0) {
                let gainedFraction = CGFloat(periodGained) / max(CGFloat(periodGained + periodLost), 1)
                let lostFraction = 1.0 - gainedFraction

                if periodGained > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GlassTheme.positive.opacity(0.15))
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(GlassTheme.positive)
                                .frame(width: animateProgress ? nil : 0)
                        }
                        .frame(height: 8)
                        .frame(maxWidth: .infinity)
                        .layoutPriority(Double(gainedFraction))
                }

                if periodLost > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(GlassTheme.negative.opacity(animateProgress ? 0.25 : 0))
                        .frame(height: 8)
                        .frame(maxWidth: .infinity)
                        .layoutPriority(Double(lostFraction))
                        .padding(.leading, 3)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("+\(periodGained)")
                        .font(.satoshi(.bold, size: 20))
                        .foregroundStyle(GlassTheme.positive)
                        .monospacedDigit()
                    Text("gained")
                        .font(.satoshi(.regular, size: 11))
                        .foregroundStyle(GlassTheme.textTertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("−\(periodLost)")
                        .font(.satoshi(.bold, size: 20))
                        .foregroundStyle(GlassTheme.negative)
                        .monospacedDigit()
                    Text("lost")
                        .font(.satoshi(.regular, size: 11))
                        .foregroundStyle(GlassTheme.textTertiary)
                }
            }

            if periodNet != 0 {
                HStack(spacing: 6) {
                    Image(systemName: periodNet > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text(periodNet > 0
                         ? "You're trending positive. Keep it up!"
                         : "Small changes add up. You've got this.")
                        .font(.satoshi(.medium, size: 12))
                }
                .foregroundStyle(periodNet > 0 ? GlassTheme.positive : GlassTheme.textTertiary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    (periodNet > 0 ? GlassTheme.positive : GlassTheme.textTertiary).opacity(0.06),
                    in: .rect(cornerRadius: 10)
                )
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }

    private var healthDashboard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Today's Health")
                .font(.satoshi(.bold, size: 18))
                .foregroundStyle(GlassTheme.textPrimary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                healthTile(
                    icon: "figure.walk",
                    value: "\(healthKit.stepCount)",
                    label: "Steps",
                    goal: 10000,
                    current: Double(healthKit.stepCount),
                    color: GlassTheme.accent
                )
                healthTile(
                    icon: "flame.fill",
                    value: "\(healthKit.activeMinutes) min",
                    label: "Active Minutes",
                    goal: 30,
                    current: Double(healthKit.activeMinutes),
                    color: GlassTheme.positive
                )
                healthTile(
                    icon: "bolt.fill",
                    value: "\(healthKit.caloriesBurned)",
                    label: "Calories Burned",
                    goal: 500,
                    current: Double(healthKit.caloriesBurned),
                    color: Color(red: 1.0, green: 0.55, blue: 0.2)
                )
                healthTile(
                    icon: "bed.double.fill",
                    value: healthKit.sleepHours > 0 ? String(format: "%.1f hrs", healthKit.sleepHours) : "—",
                    label: "Sleep",
                    goal: 8,
                    current: healthKit.sleepHours,
                    color: Color(red: 0.4, green: 0.55, blue: 0.85)
                )
            }
        }
    }

    private func healthTile(
        icon: String,
        value: String,
        label: String,
        goal: Double,
        current: Double,
        color: Color
    ) -> some View {
        let progress = min(current / max(goal, 1), 1.0)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 30, height: 30)
                    .background(color.opacity(0.1), in: .rect(cornerRadius: 8))
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.satoshi(.medium, size: 11))
                    .foregroundStyle(GlassTheme.textTertiary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.satoshi(.bold, size: 20))
                    .foregroundStyle(GlassTheme.textPrimary)
                    .monospacedDigit()

                Text(label)
                    .font(.satoshi(.regular, size: 11))
                    .foregroundStyle(GlassTheme.textTertiary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(GlassTheme.separator.opacity(0.4))
                    Capsule()
                        .fill(color)
                        .frame(width: animateProgress ? geo.size.width * progress : 0)
                }
            }
            .frame(height: 4)
        }
        .padding(14)
        .glassCard(cornerRadius: 16)
    }

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.satoshi(.bold, size: 18))
                    .foregroundStyle(GlassTheme.textPrimary)
                Spacer()
                Text(formatNet(store.weekNetMinutes))
                    .font(.satoshi(.bold, size: 14))
                    .foregroundStyle(GlassTheme.minuteColor(store.weekNetMinutes))
                    .monospacedDigit()
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(weeklyData.enumerated()), id: \.offset) { _, data in
                    VStack(spacing: 6) {
                        Spacer()

                        let maxVal = max(weeklyData.map { abs($0.net) }.max() ?? 1, 1)
                        let barHeight = max(CGFloat(abs(data.net)) / CGFloat(maxVal) * 56, 4)
                        let isPositive = data.net >= 0

                        RoundedRectangle(cornerRadius: 4)
                            .fill(isPositive ? GlassTheme.accent : GlassTheme.separator)
                            .frame(height: animateProgress ? barHeight : 4)

                        Text(data.day)
                            .font(.satoshi(.medium, size: 10))
                            .foregroundStyle(GlassTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90)
        }
        .padding(20)
        .glassCard(cornerRadius: 20)
    }

    private var milestones: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Milestones")
                .font(.satoshi(.bold, size: 18))
                .foregroundStyle(GlassTheme.textPrimary)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                milestoneRow(title: "First Log", detail: "Log your first activity", achieved: !store.entries.isEmpty, isLast: false)
                milestoneRow(title: "3-Day Streak", detail: "3 consecutive positive days", achieved: streakDays >= 3, isLast: false)
                milestoneRow(title: "100 Minutes", detail: "Accumulate 100+ positive minutes", achieved: totalGained >= 100, isLast: false)
                milestoneRow(title: "Week Warrior", detail: "7 consecutive positive days", achieved: streakDays >= 7, isLast: true)
            }
            .glassCard(cornerRadius: 18)
        }
    }

    private func milestoneRow(title: String, detail: String, achieved: Bool, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(achieved ? GlassTheme.accent : GlassTheme.separator.opacity(0.5))
                        .frame(width: 24, height: 24)
                    if achieved {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.satoshi(.medium, size: 14))
                        .foregroundStyle(achieved ? GlassTheme.textPrimary : GlassTheme.textTertiary)
                    Text(detail)
                        .font(.satoshi(.regular, size: 11))
                        .foregroundStyle(GlassTheme.textTertiary)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)

            if !isLast {
                Rectangle()
                    .fill(GlassTheme.separator.opacity(0.5))
                    .frame(height: 0.5)
                    .padding(.leading, 56)
            }
        }
    }

    private func formatNet(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        if value < 0 { return "\(value)" }
        return "0"
    }

    private func formatLargeMinutes(_ minutes: Int) -> String {
        let years = minutes / 525960
        let remainingMonths = (minutes % 525960) / 43830
        return "\(years)y \(remainingMonths)m"
    }
}
