import SwiftUI

struct HomeView: View {
    let store: DataStore
    let healthKit: HealthKitService
    @State private var appeared: Bool = false
    @State private var pulseRing: Bool = false
    @State private var selectedDay: Int = 0
    @State private var heroScale: CGFloat = 0.96
    @State private var ringProgress: CGFloat = 0

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

    private var chronoAge: Double {
        store.profile.preciseAge
    }

    private var ageDelta: Double {
        chronoAge - bioAge
    }

    private var costlyDelta: Double {
        chronoAge - costlyAge
    }

    private var totalNetMinutes: Int {
        store.todayNetMinutes + healthKit.healthMinutesBalance
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }

    var body: some View {
        ZStack {
            GlassTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    greetingHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .premiumStagger(appeared: appeared, index: 0)

                    weekStrip
                        .premiumStagger(appeared: appeared, index: 1)

                    heroCard
                        .padding(.horizontal, 16)
                        .premiumStagger(appeared: appeared, index: 2)

                    statCards
                        .padding(.horizontal, 16)
                        .premiumStagger(appeared: appeared, index: 3)

                    if healthKit.isAuthorized {
                        healthSection
                            .padding(.horizontal, 16)
                            .premiumStagger(appeared: appeared, index: 4)
                    }

                    recentSection
                        .padding(.horizontal, 16)
                        .premiumStagger(appeared: appeared, index: 5)

                    Spacer().frame(height: 90)
                }
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                appeared = true
                heroScale = 1.0
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulseRing = true
            }
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7).delay(0.3)) {
                ringProgress = ageProgress
            }
        }
    }

    private var greetingHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.satoshi(.regular, size: 14))
                    .foregroundStyle(GlassTheme.textTertiary)

                Text(store.profile.name.isEmpty ? "Welcome" : store.profile.name)
                    .font(.satoshi(.bold, size: 28))
                    .foregroundStyle(GlassTheme.textPrimary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.2))
                    .symbolEffect(.pulse, options: .repeating, value: store.todayEntries.count)
                Text("\(store.todayEntries.count)")
                    .font(.satoshi(.bold, size: 13))
                    .foregroundStyle(GlassTheme.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
        }
    }

    private var weekStrip: some View {
        let calendar = Calendar.current
        let today = Date.now
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 2), to: today) ?? today
        let days = (0..<7).map { calendar.date(byAdding: .day, value: $0, to: startOfWeek) ?? today }
        let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]
        let todayIndex = days.firstIndex(where: { calendar.isDate($0, inSameDayAs: today) }) ?? 0
        let todayDayName = today.formatted(.dateTime.weekday(.wide))

        return VStack(spacing: 8) {
            HStack {
                Spacer()
                Text(todayDayName)
                    .font(.satoshi(.bold, size: 14))
                    .foregroundStyle(GlassTheme.textPrimary)
                Circle()
                    .fill(GlassTheme.accent)
                    .frame(width: 4, height: 4)
                    .offset(y: -1)
                Spacer()
            }

            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 6) {
                        Text(dayLetters[index])
                            .font(.satoshi(.medium, size: 11))
                            .foregroundStyle(GlassTheme.textTertiary)

                        let dayNum = calendar.component(.day, from: days[index])
                        Text("\(dayNum)")
                            .font(.satoshi(.bold, size: 13))
                            .foregroundStyle(index == todayIndex ? .white : GlassTheme.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(
                                Group {
                                    if index == todayIndex {
                                        Circle()
                                            .fill(GlassTheme.textPrimary)
                                    }
                                }
                            )
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
    }

    private var heroCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BIOLOGICAL")
                        .font(.satoshi(.bold, size: 9))
                        .foregroundStyle(GlassTheme.textTertiary)
                        .tracking(1.5)

                    Text(String(format: "%.1f", bioAge))
                        .font(.satoshi(.light, size: 48))
                        .foregroundStyle(GlassTheme.textPrimary)
                        .contentTransition(.numericText())
                        .monospacedDigit()

                    HStack(spacing: 3) {
                        Image(systemName: ageDelta >= 0 ? "arrow.down" : "arrow.up")
                            .font(.system(size: 9, weight: .bold))
                        Text(String(format: "%.1f yrs %@", abs(ageDelta), ageDelta >= 0 ? "younger" : "older"))
                            .font(.satoshi(.medium, size: 11))
                    }
                    .foregroundStyle(ageDelta >= 0 ? GlassTheme.positive : GlassTheme.negative)
                }

                Spacer()

                Rectangle()
                    .fill(GlassTheme.separator)
                    .frame(width: 0.5, height: 70)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("COSTLY AGE")
                        .font(.satoshi(.bold, size: 9))
                        .foregroundStyle(GlassTheme.textTertiary)
                        .tracking(1.5)

                    Text(String(format: "%.1f", costlyAge))
                        .font(.satoshi(.light, size: 48))
                        .foregroundStyle(costlyDelta >= 0 ? GlassTheme.positive : GlassTheme.negative)
                        .contentTransition(.numericText())
                        .monospacedDigit()

                    HStack(spacing: 3) {
                        Image(systemName: costlyDelta >= 0 ? "arrow.down" : "arrow.up")
                            .font(.system(size: 9, weight: .bold))
                        Text(costlyDelta >= 0 ? "improving" : "declining")
                            .font(.satoshi(.medium, size: 11))
                    }
                    .foregroundStyle(costlyDelta >= 0 ? GlassTheme.positive : GlassTheme.negative)
                }
            }

            Spacer().frame(height: 16)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(GlassTheme.bgPrimary)
                    .frame(height: 4)

                GeometryReader { geo in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [GlassTheme.negative.opacity(0.7), GlassTheme.neutral.opacity(0.3), GlassTheme.positive.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * ringProgress, height: 4)
                }
                .frame(height: 4)
            }

            if !healthKit.isAuthorized {
                Spacer().frame(height: 12)
                HStack(spacing: 6) {
                    Image(systemName: "heart.text.clipboard")
                        .font(.system(size: 11))
                    Text("Connect Health to refine your Costly Age")
                        .font(.satoshi(.regular, size: 11))
                }
                .foregroundStyle(GlassTheme.textTertiary)
            }
        }
        .padding(20)
        .glassCard()
        .scaleEffect(heroScale)
    }

    private var statCards: some View {
        HStack(spacing: 10) {
            statCard(
                value: selectedDay == 0
                    ? GlassTheme.formatMinutes(totalNetMinutes)
                    : GlassTheme.formatMinutes(store.weekNetMinutes),
                label: selectedDay == 0 ? "Minutes today" : "Minutes this week",
                color: selectedDay == 0
                    ? GlassTheme.minuteColor(totalNetMinutes)
                    : GlassTheme.minuteColor(store.weekNetMinutes),
                icon: "clock"
            )

            statCard(
                value: GlassTheme.formatMinutes(store.allTimeNetMinutes),
                label: "All time",
                color: GlassTheme.minuteColor(store.allTimeNetMinutes),
                icon: "chart.line.uptrend.xyaxis"
            )

            statCard(
                value: "\(store.todayEntries.count)",
                label: "Logged today",
                color: GlassTheme.textPrimary,
                icon: "list.bullet"
            )
        }
    }

    private func statCard(value: String, label: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(GlassTheme.accent.opacity(0.5))
                .frame(width: 34, height: 34)
                .background(GlassTheme.accent.opacity(0.06))
                .clipShape(.rect(cornerRadius: 10))

            Text(value)
                .font(.satoshi(.bold, size: 20))
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(label)
                .font(.satoshi(.regular, size: 10))
                .foregroundStyle(GlassTheme.textTertiary)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 16)
    }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wellness Overview")
                .font(.satoshi(.bold, size: 18))
                .foregroundStyle(GlassTheme.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                healthMetricCard(icon: "figure.walk", value: "\(healthKit.stepCount)", label: "Steps", color: GlassTheme.accent)
                healthMetricCard(icon: "flame.fill", value: "\(healthKit.activeMinutes)", label: "Activity Min", color: GlassTheme.positive)
                if healthKit.sleepHours > 0 {
                    healthMetricCard(icon: "bed.double.fill", value: String(format: "%.1f hrs", healthKit.sleepHours), label: "Sleep", color: Color(red: 0.4, green: 0.55, blue: 0.85))
                }
                if healthKit.heartRate > 0 {
                    healthMetricCard(icon: "heart.fill", value: "\(Int(healthKit.heartRate))", label: "BPM", color: Color(red: 0.9, green: 0.35, blue: 0.4))
                }
                healthMetricCard(icon: "point.bottomleft.forward.to.point.topright.scurvepath", value: String(format: "%.1f km", healthKit.distanceKm), label: "Distance", color: GlassTheme.textSecondary)
                healthMetricCard(icon: "bolt.fill", value: "\(healthKit.caloriesBurned)", label: "Calories", color: Color(red: 1.0, green: 0.55, blue: 0.2))
            }
        }
    }

    private func healthMetricCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.08))
                .clipShape(.rect(cornerRadius: 10))

            Text(label)
                .font(.satoshi(.medium, size: 12))
                .foregroundStyle(GlassTheme.textTertiary)

            Text(value)
                .font(.satoshi(.bold, size: 18))
                .foregroundStyle(GlassTheme.textPrimary)
                .monospacedDigit()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 16)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recently Logged")
                    .font(.satoshi(.bold, size: 18))
                    .foregroundStyle(GlassTheme.textPrimary)

                Spacer()

                if !store.todayEntries.isEmpty {
                    Text("See All")
                        .font(.satoshi(.medium, size: 13))
                        .foregroundStyle(GlassTheme.accent)
                }
            }

            if store.todayEntries.isEmpty {
                emptyLogState
            } else {
                VStack(spacing: 0) {
                    let displayEntries = selectedDay == 0 ? store.todayEntries : store.weekEntries
                    ForEach(Array(displayEntries.prefix(10).enumerated()), id: \.element.id) { index, entry in
                        entryRow(entry: entry)
                            .premiumStagger(appeared: appeared, index: index, baseDelay: 0.03)

                        if index < min(displayEntries.count, 10) - 1 {
                            Rectangle()
                                .fill(GlassTheme.separator.opacity(0.5))
                                .frame(height: 0.5)
                                .padding(.leading, 56)
                        }
                    }
                }
                .glassCard(cornerRadius: 16)
            }
        }
    }

    private var emptyLogState: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(GlassTheme.textTertiary.opacity(0.4))

            Text("Log your first activity")
                .font(.satoshi(.regular, size: 14))
                .foregroundStyle(GlassTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .glassCard(cornerRadius: 16)
    }

    private func entryRow(entry: LogEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.activityIcon)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(GlassTheme.textSecondary)
                .frame(width: 36, height: 36)
                .background(GlassTheme.bgPrimary)
                .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.activityName)
                    .font(.satoshi(.medium, size: 14))
                    .foregroundStyle(GlassTheme.textPrimary)
                Text(entry.timestamp, style: .time)
                    .font(.satoshi(.regular, size: 11))
                    .foregroundStyle(GlassTheme.textTertiary)
            }

            Spacer()

            Text("\(entry.formattedDelta) min")
                .font(.satoshi(.bold, size: 15))
                .foregroundStyle(entry.isPositive ? GlassTheme.positive : GlassTheme.negative)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var ageProgress: CGFloat {
        let normalized = min(max(bioAge / 100.0, 0), 1)
        return CGFloat(normalized)
    }
}
