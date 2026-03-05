import Foundation
import Supabase

nonisolated struct SupabaseProfile: Codable, Sendable {
    let id: UUID
    let name: String
    let birthDate: Date
    let memberSince: Date
    let hasCompletedOnboarding: Bool
    let hasActiveSubscription: Bool
    let okxRedeemed: Bool
    let walletConnected: Bool
    let freeScansUsed: Int
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case birthDate = "birth_date"
        case memberSince = "member_since"
        case hasCompletedOnboarding = "has_completed_onboarding"
        case hasActiveSubscription = "has_active_subscription"
        case okxRedeemed = "okx_redeemed"
        case walletConnected = "wallet_connected"
        case freeScansUsed = "free_scans_used"
        case updatedAt = "updated_at"
    }
}

nonisolated struct SupabaseLogEntry: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let activityId: String
    let activityName: String
    let activityIcon: String
    let minutesDelta: Int
    let timestamp: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityId = "activity_id"
        case activityName = "activity_name"
        case activityIcon = "activity_icon"
        case minutesDelta = "minutes_delta"
        case timestamp
        case createdAt = "created_at"
    }
}

nonisolated enum AuthError: Error, Sendable {
    case invalidEmail
    case passwordTooShort
    case signUpFailed(String)
    case signInFailed(String)
    case signOutFailed(String)
}

@Observable
@MainActor
class SupabaseService {
    private(set) var isAuthenticated: Bool = false
    private(set) var userId: UUID?
    private(set) var userEmail: String?
    private(set) var isSyncing: Bool = false
    private(set) var isLoading: Bool = false

    private let client: SupabaseClient

    init() {
        let url = Config.EXPO_PUBLIC_SUPABASE_URL
        let key = Config.EXPO_PUBLIC_SUPABASE_ANON_KEY

        self.client = SupabaseClient(
            supabaseURL: URL(string: url.isEmpty ? "https://placeholder.supabase.co" : url)!,
            supabaseKey: key.isEmpty ? "placeholder" : key
        )
    }

    var isConfigured: Bool {
        !Config.EXPO_PUBLIC_SUPABASE_URL.isEmpty && !Config.EXPO_PUBLIC_SUPABASE_ANON_KEY.isEmpty
    }

    func checkExistingSession() async {
        guard isConfigured else { return }
        do {
            let session = try await client.auth.session
            userId = session.user.id
            userEmail = session.user.email
            isAuthenticated = true
        } catch {
            isAuthenticated = false
        }
    }

    func signUpWithEmail(email: String, password: String) async throws {
        guard isConfigured else { return }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.contains("@") && trimmed.contains(".") else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.passwordTooShort
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await client.auth.signUp(email: trimmed, password: password)
            userId = response.user.id
            userEmail = response.user.email
            if response.session != nil {
                isAuthenticated = true
            }
        } catch {
            throw AuthError.signUpFailed(error.localizedDescription)
        }
    }

    func signInWithEmail(email: String, password: String) async throws {
        guard isConfigured else { return }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await client.auth.signIn(email: trimmed, password: password)
            userId = session.user.id
            userEmail = session.user.email
            isAuthenticated = true
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    func signOut() async throws {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
            userId = nil
            userEmail = nil
        } catch {
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }

    func signInAnonymously() async {
        guard isConfigured else { return }
        do {
            let session = try await client.auth.signInAnonymously()
            userId = session.user.id
            isAuthenticated = true
        } catch {
            if let session = try? await client.auth.session {
                userId = session.user.id
                isAuthenticated = true
            }
        }
    }

    func syncProfile(_ profile: UserProfile) async {
        guard isAuthenticated, let userId else { return }
        isSyncing = true
        defer { isSyncing = false }

        let supaProfile = SupabaseProfile(
            id: userId,
            name: profile.name,
            birthDate: profile.birthDate,
            memberSince: profile.memberSince,
            hasCompletedOnboarding: profile.hasCompletedOnboarding,
            hasActiveSubscription: profile.hasActiveSubscription,
            okxRedeemed: profile.okxRedeemed,
            walletConnected: profile.walletConnected,
            freeScansUsed: profile.freeScansUsed,
            updatedAt: .now
        )

        do {
            try await client.from("profiles")
                .upsert(supaProfile)
                .execute()
        } catch {
            // silent fail, local data is source of truth
        }
    }

    func fetchProfile() async -> UserProfile? {
        guard isAuthenticated, let userId else { return nil }
        do {
            let response: SupabaseProfile = try await client.from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            return UserProfile(
                name: response.name,
                birthDate: response.birthDate,
                memberSince: response.memberSince,
                hasCompletedOnboarding: response.hasCompletedOnboarding,
                hasActiveSubscription: response.hasActiveSubscription,
                okxRedeemed: response.okxRedeemed,
                walletConnected: response.walletConnected,
                freeScansUsed: response.freeScansUsed
            )
        } catch {
            return nil
        }
    }

    func syncLogEntry(_ entry: LogEntry) async {
        guard isAuthenticated, let userId else { return }

        let supaEntry = SupabaseLogEntry(
            id: entry.id,
            userId: userId,
            activityId: entry.activityId,
            activityName: entry.activityName,
            activityIcon: entry.activityIcon,
            minutesDelta: entry.minutesDelta,
            timestamp: entry.timestamp,
            createdAt: .now
        )

        do {
            try await client.from("log_entries")
                .upsert(supaEntry)
                .execute()
        } catch {
            // silent fail
        }
    }

    func deleteLogEntry(_ entryId: UUID) async {
        guard isAuthenticated, let userId else { return }
        do {
            try await client.from("log_entries")
                .delete()
                .eq("id", value: entryId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
        } catch {
            // silent fail
        }
    }

    func fetchLogEntries() async -> [LogEntry] {
        guard isAuthenticated, let userId else { return [] }
        do {
            let response: [SupabaseLogEntry] = try await client.from("log_entries")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("timestamp", ascending: false)
                .execute()
                .value

            return response.map { entry in
                LogEntry(
                    id: entry.id,
                    activityId: entry.activityId,
                    activityName: entry.activityName,
                    activityIcon: entry.activityIcon,
                    minutesDelta: entry.minutesDelta,
                    timestamp: entry.timestamp
                )
            }
        } catch {
            return []
        }
    }
}
