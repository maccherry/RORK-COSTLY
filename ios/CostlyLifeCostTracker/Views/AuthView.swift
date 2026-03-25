import SwiftUI

struct AuthView: View {
    let store: DataStore
    var onAuthenticated: () -> Void

    @State private var isSignUp: Bool = false
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var appeared: Bool = false
    @State private var isPasswordVisible: Bool = false

    private var isFormValid: Bool {
        let emailValid = email.contains("@") && email.contains(".")
        let passwordValid = password.count >= 6
        if isSignUp {
            return emailValid && passwordValid && password == confirmPassword
        }
        return emailValid && passwordValid
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 80)

                    headerSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    Spacer().frame(height: 40)

                    formSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    Spacer().frame(height: 28)

                    actionButton
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                    Spacer().frame(height: 20)

                    toggleSection
                        .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.hidden)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Costly")
                .font(.satoshi(.light, size: 38))
                .foregroundStyle(GlassTheme.textPrimary)

            Text(isSignUp ? "Create your account" : "Welcome back")
                .font(.satoshi(.regular, size: 15))
                .foregroundStyle(GlassTheme.textTertiary)
        }
    }

    private var formSection: some View {
        VStack(spacing: 16) {
            if let errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 13))
                    Text(errorMessage)
                        .font(.satoshi(.regular, size: 13))
                }
                .foregroundStyle(GlassTheme.negative)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GlassTheme.negative.opacity(0.08))
                .clipShape(.rect(cornerRadius: 12))
            }

            if let successMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                    Text(successMessage)
                        .font(.satoshi(.regular, size: 13))
                }
                .foregroundStyle(GlassTheme.positive)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GlassTheme.positive.opacity(0.08))
                .clipShape(.rect(cornerRadius: 12))
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("EMAIL")
                    .font(.satoshi(.bold, size: 9))
                    .foregroundStyle(GlassTheme.textTertiary)
                    .tracking(1.5)

                TextField("", text: $email, prompt: Text("you@example.com").foregroundStyle(GlassTheme.textTertiary))
                    .font(.satoshi(.regular, size: 16))
                    .foregroundStyle(GlassTheme.textPrimary)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .glassCard(cornerRadius: 14)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("PASSWORD")
                    .font(.satoshi(.bold, size: 9))
                    .foregroundStyle(GlassTheme.textTertiary)
                    .tracking(1.5)

                HStack(spacing: 0) {
                    Group {
                        if isPasswordVisible {
                            TextField("", text: $password, prompt: Text("Min. 6 characters").foregroundStyle(GlassTheme.textTertiary))
                        } else {
                            SecureField("", text: $password, prompt: Text("Min. 6 characters").foregroundStyle(GlassTheme.textTertiary))
                        }
                    }
                    .font(.satoshi(.regular, size: 16))
                    .foregroundStyle(GlassTheme.textPrimary)
                    .textContentType(isSignUp ? .newPassword : .password)

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.system(size: 14))
                            .foregroundStyle(GlassTheme.textTertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .glassCard(cornerRadius: 14)
            }

            if isSignUp {
                VStack(alignment: .leading, spacing: 7) {
                    Text("CONFIRM PASSWORD")
                        .font(.satoshi(.bold, size: 9))
                        .foregroundStyle(GlassTheme.textTertiary)
                        .tracking(1.5)

                    SecureField("", text: $confirmPassword, prompt: Text("Re-enter password").foregroundStyle(GlassTheme.textTertiary))
                        .font(.satoshi(.regular, size: 16))
                        .foregroundStyle(GlassTheme.textPrimary)
                        .textContentType(.newPassword)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .glassCard(cornerRadius: 14)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isSignUp)
    }

    private var actionButton: some View {
        Button {
            Task { await performAuth() }
        } label: {
            Group {
                if store.supabase.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(.satoshi(.bold, size: 17))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isFormValid ? GlassTheme.textPrimary : GlassTheme.textPrimary.opacity(0.3))
            .clipShape(.rect(cornerRadius: 27))
        }
        .buttonStyle(PremiumCTAButtonStyle())
        .disabled(!isFormValid || store.supabase.isLoading)
        .sensoryFeedback(.impact(weight: .medium), trigger: store.supabase.isAuthenticated)
    }

    private var toggleSection: some View {
        HStack(spacing: 4) {
            Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                .font(.satoshi(.regular, size: 14))
                .foregroundStyle(GlassTheme.textTertiary)

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isSignUp.toggle()
                    errorMessage = nil
                    successMessage = nil
                }
            } label: {
                Text(isSignUp ? "Sign In" : "Sign Up")
                    .font(.satoshi(.bold, size: 14))
                    .foregroundStyle(GlassTheme.textPrimary)
            }
        }
    }

    private func performAuth() async {
        errorMessage = nil
        successMessage = nil

        if isSignUp {
            guard password == confirmPassword else {
                errorMessage = "Passwords don't match"
                return
            }
            do {
                try await store.supabase.signUpWithEmail(email: email, password: password)
                if store.supabase.isAuthenticated {
                    onAuthenticated()
                } else {
                    successMessage = "Check your email to confirm your account, then sign in."
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        isSignUp = false
                    }
                }
            } catch AuthError.invalidEmail {
                errorMessage = "Please enter a valid email address"
            } catch AuthError.passwordTooShort {
                errorMessage = "Password must be at least 6 characters"
            } catch AuthError.signUpFailed(let msg) {
                errorMessage = msg
            } catch {
                errorMessage = error.localizedDescription
            }
        } else {
            do {
                try await store.supabase.signInWithEmail(email: email, password: password)
                onAuthenticated()
            } catch AuthError.signInFailed(let msg) {
                errorMessage = msg
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
