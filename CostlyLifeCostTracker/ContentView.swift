import SwiftUI

struct ContentView: View {
    @State private var store = DataStore()
    @State private var healthKit = HealthKitService()
    @State private var showSplash: Bool = true
    @State private var showAuth: Bool = false
    @State private var showOnboarding: Bool = false
    @State private var showPaywall: Bool = false
    @State private var checkingSession: Bool = true

    var body: some View {
        ZStack {
            GlassTheme.bgPrimary.ignoresSafeArea()

            if showSplash {
                SplashView {
                    Task {
                        await store.supabase.checkExistingSession()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            showSplash = false
                            checkingSession = false
                            if !store.supabase.isAuthenticated {
                                showAuth = true
                            } else if !store.profile.hasCompletedOnboarding {
                                showOnboarding = true
                            } else if !store.profile.hasActiveSubscription {
                                showPaywall = true
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else if showAuth {
                AuthView(store: store, onAuthenticated: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        showAuth = false
                        if !store.profile.hasCompletedOnboarding {
                            showOnboarding = true
                        } else if !store.profile.hasActiveSubscription {
                            showPaywall = true
                        }
                    }
                    Task { await store.initializeSupabase() }
                })
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 8)),
                    removal: .opacity
                ))
            } else if showOnboarding {
                OnboardingView(store: store, onComplete: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        showOnboarding = false
                    }
                    Task { await healthKit.requestAuthorization() }
                })
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 8)),
                    removal: .opacity
                ))
            } else {
                MainTabView(store: store, healthKit: healthKit)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity
                    ))
                    .task {
                        await healthKit.requestAuthorization()
                        await store.initializeSupabase()
                    }
            }
        }
        .preferredColorScheme(.light)
        .environment(healthKit)
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(store: store, allowDismiss: false, onSubscribe: {
                showPaywall = false
            })
        }
    }
}
