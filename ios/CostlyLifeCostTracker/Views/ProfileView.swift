import SwiftUI

struct ProfileView: View {
    let store: DataStore
    let healthKit: HealthKitService
    @State private var showPaywall: Bool = false
    @State private var appeared: Bool = false
    @State private var showSignOutAlert: Bool = false

    var body: some View {
        ZStack {
            GlassTheme.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                        .padding(.top, 16)
                        .premiumStagger(appeared: appeared, index: 0)

                    accountCard
                        .premiumStagger(appeared: appeared, index: 1)

                    preferencesCard
                        .premiumStagger(appeared: appeared, index: 2)

                    supportCard
                        .premiumStagger(appeared: appeared, index: 3)

                    footer
                        .premiumStagger(appeared: appeared, index: 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
            .scrollIndicators(.hidden)
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(store: store)
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await store.supabase.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { appeared = true }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [GlassTheme.bgPrimary, Color.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 0.5)
                    )

                Text(String(store.profile.name.prefix(1)).uppercased())
                    .font(.satoshi(.light, size: 28))
                    .foregroundStyle(GlassTheme.textSecondary)
            }

            VStack(spacing: 4) {
                Text(store.profile.name)
                    .font(.satoshi(.bold, size: 22))
                    .foregroundStyle(GlassTheme.textPrimary)

                Text("Member since \(store.profile.memberSince, format: .dateTime.month(.wide).year())")
                    .font(.satoshi(.regular, size: 12))
                    .foregroundStyle(GlassTheme.textTertiary)
            }
        }
    }

    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("ACCOUNT")

            VStack(spacing: 0) {
                if let email = store.supabase.userEmail {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                            .font(.system(size: 13))
                            .foregroundStyle(GlassTheme.accent)
                            .frame(width: 24)

                        Text(email)
                            .font(.satoshi(.regular, size: 14))
                            .foregroundStyle(GlassTheme.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text("Signed In")
                            .font(.satoshi(.regular, size: 12))
                            .foregroundStyle(GlassTheme.positive)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    divider
                }
                settingsRow(icon: "crown", label: "Subscription", detail: store.profile.hasActiveSubscription ? "Active" : "Free") {
                    showPaywall = true
                }
                divider
                settingsRow(icon: "arrow.clockwise", label: "Restore Purchases", detail: nil) {
                    store.setSubscriptionActive(true)
                }
                divider
                settingsRow(icon: "rectangle.portrait.and.arrow.right", label: "Sign Out", detail: nil) {
                    showSignOutAlert = true
                }
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("PREFERENCES")

            VStack(spacing: 0) {
                settingsRow(icon: "heart.text.clipboard", label: "Health Access", detail: healthKit.isAuthorized ? "Connected" : "Off") {
                    Task { await healthKit.requestAuthorization() }
                }
                divider
                settingsRow(icon: "bell", label: "Notifications", detail: "On") { }
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("SUPPORT")

            VStack(spacing: 0) {
                settingsRow(icon: "questionmark.circle", label: "Help Center", detail: nil) { }
                divider
                settingsRow(icon: "doc.text", label: "Terms of Service", detail: nil) { }
                divider
                settingsRow(icon: "hand.raised", label: "Privacy Policy", detail: nil) { }
            }
            .glassCard(cornerRadius: 14)
        }
    }

    private func settingsRow(icon: String, label: String, detail: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(GlassTheme.accent)
                    .frame(width: 24)

                Text(label)
                    .font(.satoshi(.regular, size: 14))
                    .foregroundStyle(GlassTheme.textPrimary)

                Spacer()

                if let detail {
                    Text(detail)
                        .font(.satoshi(.regular, size: 12))
                        .foregroundStyle(GlassTheme.textTertiary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(GlassTheme.textTertiary.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(PremiumButtonStyle(scale: 0.98, opacity: 0.8))
    }

    private var divider: some View {
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

    private var footer: some View {
        VStack(spacing: 3) {
            Text("Costly")
                .font(.satoshi(.light, size: 13))
                .foregroundStyle(GlassTheme.textTertiary.opacity(0.5))
            Text("Version 1.0.0")
                .font(.satoshi(.regular, size: 10))
                .foregroundStyle(GlassTheme.textTertiary.opacity(0.3))
        }
        .padding(.top, 8)
    }
}
