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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    navBar
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .premiumStagger(appeared: appeared, index: 0)

                    daySelector
                        .padding(.horizontal, 20)
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

    private var navBar: some View {
        HStack(spacing: 12) {
            Text("Costly")
                .font(.satoshi(.bold, size: 24))
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.2))
                    .symbolEffect(.pulse, options: .repeating, value: store.todayEntries.count)
                Text("\(store.todayEntries.count)")
                    .font(.satoshi(.bold, size: 13))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.06))
            .clipShape(Capsule())
        }
    }

    private var daySelector: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedDay = 0 }
            } label: {
                VStack(spacing: 4) {
                    Text("Today")
                        .font(.satoshi(.bold, size: 15))
                        .foregroundStyle(selectedDay == 0 ? .white : .white.opacity(0.3))
                    if selectedDay == 0 {
                        Circle()
                            .fill(.white)
                            .frame(width: 4, height: 4)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(PremiumButtonStyle(scale: 0.95, opacity: 0.7))
            .sensoryFeedback(.impact(weight: .light, intensity: 0.3), trigger: selectedDay)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedDay = 1 }
            } label: {
                Text("This Week")
                    .font(.satoshi(.medium, size: 15))
                    .foregroundStyle(selectedDay == 1 ? .white : .white.opacity(0.3))
            }
            .buttonStyle(PremiumButtonStyle(scale: 0.95, opacity: 0.7))
            .sensoryFeedback(.impact(weight: .light, intensity: 0.3), trigger: selectedDay)

            Spacer()
        }
    }

    private var heroCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BIOLOGICAL")
                        .font(.satoshi(.bold, size: 9))
                        .foregroundStyle(.white.opacity(0.2))
                        .tracking(1.5)

                    Text(String(format: "%.1f", bioAge))
                        .font(.satoshi(.light, size: 48))
                        .foregroundStyle(.white)
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
                    .fill(.white.opacity(0.06))
                    .frame(width: 0.5, height: 70)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("COSTLY AGE")
                        .font(.satoshi(.bold, size: 9))
                        .foregroundStyle(.white.opacity(0.2))
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
                    .fill(.white.opacity(0.04))
                    .frame(height: 4)

                GeometryReader { geo in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [GlassTheme.negative, .white.opacity(0.3), GlassTheme.positive],
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
                .foregroundStyle(.white.opacity(0.2))
            }
        }
        .padding(20)
        .premiumCardStyle()
        .scaleEffect(heroScale)
    }

    private var statCards: some View {
        HStack(spacing: 8) {
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
                color: .white,
                icon: "list.bullet"
            )
        }
    }

    private func statCard(value: String, label: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.satoshi(.bold, size: 22))
                .foregroundStyle(color)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(label)
                .font(.satoshi(.regular, size: 11))
                .foregroundStyle(.white.opacity(0.3))
                .lineLimit(1)

            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.1))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.03))
                .clipShape(Circle())
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCardStyle(cornerRadius: 16)
    }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("HEALTH")
                .font(.satoshi(.bold, size: 9))
                .foregroundStyle(.white.opacity(0.2))
                .tracking(1.5)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                healthMetricCard(icon: "figure.walk", value: "\(healthKit.stepCount)", label: "Steps", color: .white.opacity(0.5))
                healthMetricCard(icon: "point.bottomleft.forward.to.point.topright.scurvepath", value: String(format: "%.1f km", healthKit.distanceKm), label: "Distance", color: .white.opacity(0.5))
                healthMetricCard(icon: "flame.fill", value: "\(healthKit.activeMinutes)", label: "Activity Min", color: GlassTheme.positive)
                healthMetricCard(icon: "bolt.fill", value: "\(healthKit.caloriesBurned)", label: "Calories", color: Color(red: 1.0, green: 0.55, blue: 0.2))
                if healthKit.sleepHours > 0 {
                    healthMetricCard(icon: "bed.double.fill", value: String(format: "%.1f hrs", healthKit.sleepHours), label: "Sleep", color: healthKit.sleepHours >= 7 ? GlassTheme.positive : GlassTheme.negative)
                }
                if healthKit.heartRate > 0 {
                    healthMetricCard(icon: "heart.fill", value: "\(Int(healthKit.heartRate))", label: "BPM", color: Color(red: 0.95, green: 0.35, blue: 0.4))
                }
            }
        }
    }

    private func healthMetricCard(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 30, height: 30)
                .background(color.opacity(0.08))
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.satoshi(.bold, size: 15))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                Text(label)
                    .font(.satoshi(.regular, size: 10))
                    .foregroundStyle(.white.opacity(0.25))
            }

            Spacer()
        }
        .padding(12)
        .premiumCardStyle(cornerRadius: 14)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recently logged")
                    .font(.satoshi(.bold, size: 18))
                    .foregroundStyle(.white)

                Spacer()

                if !store.todayEntries.isEmpty {
                    Text("\(store.todayEntries.count) today")
                        .font(.satoshi(.regular, size: 12))
                        .foregroundStyle(.white.opacity(0.25))
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
                                .fill(.white.opacity(0.03))
                                .frame(height: 0.5)
                                .padding(.leading, 56)
                        }
                    }
                }
                .premiumCardStyle(cornerRadius: 16)
            }
        }
    }

    private var emptyLogState: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.08))

            Text("Log your first activity")
                .font(.satoshi(.regular, size: 14))
                .foregroundStyle(.white.opacity(0.18))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .premiumCardStyle(cornerRadius: 16)
    }

    private func entryRow(entry: LogEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.activityIcon)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(.white.opacity(0.35))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.03))
                .clipShape(.rect(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.activityName)
                    .font(.satoshi(.medium, size: 14))
                    .foregroundStyle(.white.opacity(0.85))
                Text(entry.timestamp, style: .time)
                    .font(.satoshi(.regular, size: 11))
                    .foregroundStyle(.white.opacity(0.2))
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

    private var ageTintColor: Color {
        if ageDelta >= 1.0 { return GlassTheme.positive }
        if ageDelta <= -1.0 { return GlassTheme.negative }
        return Color(white: 0.4)
    }
}
