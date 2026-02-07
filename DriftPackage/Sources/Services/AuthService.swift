import Foundation
import Core

/// Service for authentication operations
@MainActor
public final class AuthService: ObservableObject {
    public static let shared = AuthService()

    @Published public private(set) var currentUser: UserDTO?
    @Published public private(set) var isAuthenticated = false
    @Published public private(set) var isLoading = false

    private let api: APIClient
    private let keychain: KeychainService

    public init(
        api: APIClient = .shared,
        keychain: KeychainService = .shared
    ) {
        self.api = api
        self.keychain = keychain
    }

    // MARK: - Authentication State

    /// Restore authentication state from stored tokens
    public func restoreSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let accessToken = try await keychain.get(.accessToken),
                  let refreshToken = try await keychain.get(.refreshToken) else {
                return
            }

            await api.setTokens(access: accessToken, refresh: refreshToken)

            // Restore cached user profile
            if let userData = try await keychain.getData(.userProfile) {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                currentUser = try? decoder.decode(UserDTO.self, from: userData)
            }

            isAuthenticated = true

            // If cached user is missing, fetch from API
            if currentUser == nil {
                await fetchUserProfile()
            }
        } catch {
            // Tokens invalid or missing
            await clearSession()
        }
    }

    /// Fetch user profile from the API and cache it
    public func fetchUserProfile() async {
        do {
            let user: UserDTO = try await api.get("/api/v1/user/profile")
            currentUser = user
            await persistUser(user)
        } catch {
            // Profile fetch failed; non-fatal, user data just won't display
        }
    }

    // MARK: - Registration

    public func register(
        email: String,
        password: String,
        displayName: String? = nil
    ) async throws {
        isLoading = true
        defer { isLoading = false }

        let deviceId = try await keychain.getOrCreateDeviceId()

        let request = RegisterRequest(
            email: email,
            password: password,
            displayName: displayName,
            timezone: TimeZone.current.identifier
        )

        let response: RegisterResponse = try await api.post("/api/v1/auth/register", body: request)

        // Store tokens
        try await keychain.save(response.accessToken, for: .accessToken)
        try await keychain.save(response.refreshToken, for: .refreshToken)

        await api.setTokens(access: response.accessToken, refresh: response.refreshToken)

        currentUser = response.user
        await persistUser(response.user)
        isAuthenticated = true
    }

    // MARK: - Login

    public func login(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let deviceId = try await keychain.getOrCreateDeviceId()

        let request = LoginRequest(
            email: email,
            password: password,
            deviceId: deviceId
        )

        let response: LoginResponse = try await api.post("/api/v1/auth/login", body: request)

        // Store tokens
        try await keychain.save(response.accessToken, for: .accessToken)
        try await keychain.save(response.refreshToken, for: .refreshToken)

        await api.setTokens(access: response.accessToken, refresh: response.refreshToken)

        currentUser = response.user
        await persistUser(response.user)
        isAuthenticated = true
    }

    // MARK: - Logout

    public func logout(allDevices: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let refreshToken = try await keychain.get(.refreshToken)
            let request = LogoutRequest(refreshToken: refreshToken, allDevices: allDevices)
            let _: EmptyResponse = try await api.post("/api/v1/auth/logout", body: request)
        } catch {
            // Logout failed on server, but still clear local state
        }

        await clearSession()
    }

    // MARK: - Mock Support

    /// Set authentication state for mock/testing mode
    public func setMockAuthenticated(_ authenticated: Bool) {
        isAuthenticated = authenticated
        if authenticated {
            currentUser = UserDTO(
                id: UUID(),
                email: "test@example.com",
                displayName: "Test User",
                timezone: TimeZone.current.identifier,
                createdAt: Date()
            )
        } else {
            currentUser = nil
        }
    }

    // MARK: - Private Helpers

    private func persistUser(_ user: UserDTO) async {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        if let data = try? encoder.encode(user) {
            try? await keychain.saveData(data, for: .userProfile)
        }
    }

    private func clearSession() async {
        try? await keychain.deleteAll()
        await api.clearTokens()
        currentUser = nil
        isAuthenticated = false
    }
}

// MARK: - Empty Response

private struct EmptyResponse: Decodable {}
