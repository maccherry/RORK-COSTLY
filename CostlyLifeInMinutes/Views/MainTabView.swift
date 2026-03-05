import SwiftUI

struct MainTabView: View {
    let store: DataStore
    let healthKit: HealthKitService
    @State private var selectedTab: Int = 0
    @State private var showLogSheet: Bool = false
    @State private var previousTab: Int = 0

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

    var body: some View {
        ZStack(alignment: .bottom) {
            GlassTheme.bgPrimary.ignoresSafeArea()

            Group {
                switch selectedTab {
                case 0:
                    HomeView(store: store, healthKit: healthKit)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: previousTab > 0 ? -30 : 0)),
                            removal: .opacity.combined(with: .offset(x: previousTab < selectedTab ? -30 : 30))
                        ))
                case 1:
                    LifeProgressView(store: store, healthKit: healthKit)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: previousTab < 1 ? 30 : -30)),
                            removal: .opacity.combined(with: .offset(x: previousTab < selectedTab ? -30 : 30))
                        ))
                case 2:
                    ProfileView(store: store, healthKit: healthKit)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: 30)),
                            removal: .opacity.combined(with: .offset(x: 30))
                        ))
                default:
                    HomeView(store: store, healthKit: healthKit)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedTab)

            floatingTabBar

            plusButton
        }
        .fullScreenCover(isPresented: $showLogSheet) {
            LogActivityView(store: store, costlyAge: costlyAge)
        }
    }

    private var plusButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    showLogSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(
                            Circle()
                                .fill(GlassTheme.textPrimary)
                                .shadow(color: Color.black.opacity(0.15), radius: 12, y: 6)
                                .shadow(color: Color.black.opacity(0.08), radius: 2, y: 1)
                        )
                }
                .buttonStyle(PremiumButtonStyle(scale: 0.88, opacity: 0.9))
                .sensoryFeedback(.impact(weight: .heavy, intensity: 0.7), trigger: showLogSheet)
                .padding(.trailing, 20)
                .padding(.bottom, 86)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var floatingTabBar: some View {
        HStack(spacing: 4) {
            tabItem(icon: "house", filledIcon: "house.fill", label: "Home", tag: 0)

            tabItem(icon: "chart.bar", filledIcon: "chart.bar.fill", label: "Progress", tag: 1)

            tabItem(icon: "gearshape", filledIcon: "gearshape.fill", label: "Settings", tag: 2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThickMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 20, y: 8)
                .shadow(color: Color.black.opacity(0.03), radius: 2, y: 0)
        )
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
        )
        .padding(.horizontal, 40)
        .padding(.bottom, 8)
    }

    private func tabItem(icon: String, filledIcon: String, label: String, tag: Int) -> some View {
        Button {
            previousTab = selectedTab
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tag
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: selectedTab == tag ? filledIcon : icon)
                    .font(.system(size: 16, weight: .medium))
                    .contentTransition(.symbolEffect(.replace.downUp.byLayer))

                if selectedTab == tag {
                    Text(label)
                        .font(.satoshi(.bold, size: 11))
                        .lineLimit(1)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.8)),
                            removal: .opacity.combined(with: .scale(scale: 0.8))
                        ))
                }
            }
            .foregroundStyle(selectedTab == tag ? .white : GlassTheme.textTertiary)
            .padding(.horizontal, selectedTab == tag ? 14 : 12)
            .padding(.vertical, 10)
            .background(
                Group {
                    if selectedTab == tag {
                        Capsule()
                            .fill(GlassTheme.textPrimary)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
                    }
                }
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedTab)
        }
        .buttonStyle(PremiumButtonStyle(scale: 0.9, opacity: 0.7))
        .sensoryFeedback(.impact(weight: .light, intensity: 0.4), trigger: selectedTab)
    }
}
