import SwiftUI
import AVFoundation

struct LogActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mode: LogMode = .camera
    @State private var searchText: String = ""
    @State private var scannedActivity: Activity?
    @State private var showConfirmation: Bool = false
    @State private var loggedActivityName: String?
    @State private var appeared: Bool = false
    @State private var shutterScale: CGFloat = 1.0
    let store: DataStore

    private var filteredActivities: [Activity] {
        ActivityDatabase.search(searchText)
    }

    private var groupedActivities: [(category: ActivityCategory, activities: [Activity])] {
        if searchText.isEmpty {
            return ActivityDatabase.byCategory()
        } else {
            let filtered = filteredActivities
            return ActivityCategory.allCases.compactMap { category in
                let activities = filtered.filter { $0.category == category }
                return activities.isEmpty ? nil : (category, activities)
            }
        }
    }

    var body: some View {
        ZStack {
            GlassTheme.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                modeToggle
                    .padding(.top, 8)

                switch mode {
                case .camera:
                    cameraContent
                case .manual:
                    manualContent
                }
            }

            if showConfirmation, let activity = scannedActivity {
                scanResultOverlay(activity: activity)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }

            if let name = loggedActivityName {
                VStack {
                    Spacer()
                    Text("\(name) logged")
                        .font(.satoshi(.medium, size: 14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(GlassTheme.textPrimary)
                        .clipShape(Capsule())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 24)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: loggedActivityName)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: showConfirmation)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { appeared = true }
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(GlassTheme.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
            }
            .buttonStyle(PremiumButtonStyle(scale: 0.88, opacity: 0.7))
            .sensoryFeedback(.impact(weight: .light, intensity: 0.3), trigger: false)

            Spacer()

            Text("LOG ACTIVITY")
                .font(.satoshi(.bold, size: 10))
                .foregroundStyle(GlassTheme.textTertiary)
                .tracking(2)

            Spacer()

            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var modeToggle: some View {
        HStack(spacing: 2) {
            modeButton(title: "Camera", icon: "camera", isSelected: mode == .camera) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { mode = .camera }
            }
            modeButton(title: "Manual", icon: "list.bullet", isSelected: mode == .manual) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { mode = .manual }
            }
        }
        .padding(3)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.5), lineWidth: 0.5))
        .padding(.horizontal, 60)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.3), trigger: mode)
    }

    private func modeButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(title)
                    .font(.satoshi(.medium, size: 12))
            }
            .foregroundStyle(isSelected ? .white : GlassTheme.textTertiary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? GlassTheme.textPrimary : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(PremiumPillButtonStyle())
    }

    private var cameraContent: some View {
        VStack(spacing: 0) {
            Spacer()

            CameraProxyView()
                .padding(.horizontal, 16)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.97)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

            Spacer()

            Text("Point camera at food, drinks, or items")
                .font(.satoshi(.regular, size: 13))
                .foregroundStyle(GlassTheme.textTertiary)
                .padding(.bottom, 16)

            Button {
                let sampleActivities = ["coffee", "cigarette", "salad", "fast_food", "green_tea", "soda"]
                if let randomId = sampleActivities.randomElement(),
                   let activity = ActivityDatabase.activity(for: randomId) {
                    scannedActivity = activity
                    showConfirmation = true
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(GlassTheme.textPrimary.opacity(0.2), lineWidth: 3)
                        .frame(width: 78, height: 78)

                    Circle()
                        .fill(GlassTheme.textPrimary)
                        .frame(width: 64, height: 64)
                        .scaleEffect(shutterScale)
                }
            }
            .buttonStyle(PremiumButtonStyle(scale: 0.92, opacity: 0.9))
            .sensoryFeedback(.impact(weight: .heavy, intensity: 0.8), trigger: showConfirmation)
            .padding(.bottom, 36)
        }
    }

    private var manualContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                ForEach(Array(groupedActivities.enumerated()), id: \.element.category) { sectionIndex, group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.category.rawValue.uppercased())
                            .font(.satoshi(.bold, size: 9))
                            .foregroundStyle(GlassTheme.textTertiary)
                            .tracking(1.5)
                            .padding(.horizontal, 16)

                        VStack(spacing: 0) {
                            ForEach(Array(group.activities.enumerated()), id: \.element.id) { index, activity in
                                Button {
                                    store.logActivity(activity)
                                    loggedActivityName = activity.name
                                    Task {
                                        try? await Task.sleep(for: .seconds(0.6))
                                        dismiss()
                                    }
                                } label: {
                                    activityRow(activity)
                                }
                                .buttonStyle(PremiumButtonStyle(scale: 0.98, opacity: 0.8))
                                .sensoryFeedback(activity.isPositive ? .success : .warning, trigger: loggedActivityName)

                                if index < group.activities.count - 1 {
                                    Rectangle()
                                        .fill(GlassTheme.separator.opacity(0.5))
                                        .frame(height: 0.5)
                                        .padding(.leading, 56)
                                }
                            }
                        }
                        .glassCard(cornerRadius: 14)
                        .padding(.horizontal, 16)
                    }
                    .premiumStagger(appeared: appeared, index: sectionIndex, baseDelay: 0.06)
                }
            }
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(GlassTheme.textTertiary)

            TextField("", text: $searchText, prompt: Text("Search activities...").foregroundStyle(GlassTheme.textTertiary))
                .font(.satoshi(.regular, size: 15))
                .foregroundStyle(GlassTheme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .glassCard(cornerRadius: 14)
    }

    private func activityRow(_ activity: Activity) -> some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(GlassTheme.textSecondary)
                .frame(width: 32, height: 32)
                .background(GlassTheme.bgPrimary)
                .clipShape(.rect(cornerRadius: 8))

            Text(activity.name)
                .font(.satoshi(.regular, size: 14))
                .foregroundStyle(GlassTheme.textPrimary)

            Spacer()

            Text("\(activity.formattedDelta) min")
                .font(.satoshi(.medium, size: 14))
                .foregroundStyle(activity.isPositive ? GlassTheme.positive : GlassTheme.negative)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func scanResultOverlay(activity: Activity) -> some View {
        VStack {
            Spacer()

            VStack(spacing: 18) {
                HStack {
                    Text("DETECTED")
                        .font(.satoshi(.bold, size: 9))
                        .foregroundStyle(GlassTheme.textTertiary)
                        .tracking(1.5)
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showConfirmation = false }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(GlassTheme.textTertiary)
                    }
                    .buttonStyle(PremiumButtonStyle(scale: 0.85, opacity: 0.6))
                }

                HStack(spacing: 14) {
                    Image(systemName: activity.icon)
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(GlassTheme.textSecondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(activity.name)
                            .font(.satoshi(.medium, size: 18))
                            .foregroundStyle(GlassTheme.textPrimary)

                        Text("\(activity.formattedDelta) minutes")
                            .font(.satoshi(.light, size: 26))
                            .foregroundStyle(activity.isPositive ? GlassTheme.positive : GlassTheme.negative)
                    }
                    Spacer()
                }

                Button {
                    store.logActivity(activity)
                    Task {
                        try? await Task.sleep(for: .seconds(0.4))
                        dismiss()
                    }
                } label: {
                    Text("Log This")
                        .font(.satoshi(.bold, size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(GlassTheme.textPrimary)
                        .clipShape(.rect(cornerRadius: 14))
                }
                .buttonStyle(PremiumCTAButtonStyle())
                .sensoryFeedback(activity.isPositive ? .success : .warning, trigger: store.entries.count)
            }
            .padding(22)
            .glassCard(cornerRadius: 22)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
}

nonisolated enum LogMode: Sendable {
    case camera
    case manual
}

struct CameraProxyView: View {
    var body: some View {
        Group {
            #if targetEnvironment(simulator)
            CameraUnavailablePlaceholder()
            #else
            if AVCaptureDevice.default(for: .video) != nil {
                CameraUnavailablePlaceholder()
            } else {
                CameraUnavailablePlaceholder()
            }
            #endif
        }
    }
}

struct CameraUnavailablePlaceholder: View {
    @State private var pulse: Bool = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(GlassTheme.textTertiary.opacity(pulse ? 0.5 : 0.25))
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulse)

            Text("Camera Preview")
                .font(.satoshi(.medium, size: 18))
                .foregroundStyle(GlassTheme.textSecondary)

            Text("Install this app on your device\nvia the Rork App to use the camera.")
                .font(.satoshi(.regular, size: 13))
                .foregroundStyle(GlassTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .glassCard(cornerRadius: 18)
        .onAppear { pulse = true }
    }
}
