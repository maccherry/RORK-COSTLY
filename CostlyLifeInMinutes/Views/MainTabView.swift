import SwiftUI

struct MainTabView: View {
    let store: DataStore
    let healthKit: HealthKitService
    @State private var selectedTab: Int = 0
    @State private var showLogSheet: Bool = false
    @State private var previousTab: Int = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            Group {
                switch selectedTab {
                case 0:
                    HomeView(store: store, healthKit: healthKit)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(x: previousTab > 0 ? -30 : 0)),
                            removal: .opacity.combined(with: .offset(x: previousTab < selectedTab ? -30 : 30))
                        ))
                case 1:
                    TimeBankView(store: store)
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

            bottomBar

            plusButton
        }
        .fullScreenCover(isPresented: $showLogSheet) {
            LogActivityView(store: store)
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
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(color: .white.opacity(0.06), radius: 16, y: 4)
                        .shadow(color: .white.opacity(0.03), radius: 32, y: 8)
                }
                .buttonStyle(PremiumButtonStyle(scale: 0.88, opacity: 0.9))
                .sensoryFeedback(.impact(weight: .heavy, intensity: 0.7), trigger: showLogSheet)
                .padding(.trailing, 20)
                .padding(.bottom, 78)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            tabItem(icon: "house", filledIcon: "house.fill", label: "Home", tag: 0)

            Spacer()

            tabItem(icon: "building.columns", filledIcon: "building.columns.fill", label: "Time Bank", tag: 1)

            Spacer()

            tabItem(icon: "person", filledIcon: "person.fill", label: "Profile", tag: 2)
        }
        .padding(.horizontal, 32)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .colorScheme(.dark)
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.08), .white.opacity(0.02)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 0.5)
                }
        )
    }

    private func tabItem(icon: String, filledIcon: String, label: String, tag: Int) -> some View {
        Button {
            previousTab = selectedTab
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tag
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tag ? filledIcon : icon)
                    .font(.system(size: 18))
                    .foregroundStyle(selectedTab == tag ? .white : .white.opacity(0.3))
                    .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                    .scaleEffect(selectedTab == tag ? 1.0 : 0.92)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)

                Text(label)
                    .font(.satoshi(.medium, size: 9))
                    .foregroundStyle(selectedTab == tag ? .white.opacity(0.9) : .white.opacity(0.25))
                    .animation(.easeOut(duration: 0.2), value: selectedTab)
            }
            .frame(width: 56)
        }
        .buttonStyle(PremiumButtonStyle(scale: 0.9, opacity: 0.7))
        .sensoryFeedback(.impact(weight: .light, intensity: 0.4), trigger: selectedTab)
    }
}
