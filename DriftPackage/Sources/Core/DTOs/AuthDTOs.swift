import Foundation

// MARK: - Registration

public struct RegisterRequest: Codable, Sendable {
    public let email: String
    public let password: String
    public let displayName: String?
    public let timezone: String?

    public init(
        email: String,
        password: String,
        displayName: String? = nil,
        timezone: String? = nil
    ) {
        self.email = email
        self.password = password
        self.displayName = displayName
        self.timezone = timezone
    }
}

public struct RegisterResponse: Codable, Sendable {
    public let user: UserDTO
    public let accessToken: String
    public let refreshToken: String

    public init(user: UserDTO, accessToken: String, refreshToken: String) {
        self.user = user
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

// MARK: - Login

public struct LoginRequest: Codable, Sendable {
    public let email: String
    public let password: String
    public let deviceId: String?

    public init(email: String, password: String, deviceId: String? = nil) {
        self.email = email
        self.password = password
        self.deviceId = deviceId
    }
}

public struct LoginResponse: Codable, Sendable {
    public let user: UserDTO
    public let accessToken: String
    public let refreshToken: String

    public init(user: UserDTO, accessToken: String, refreshToken: String) {
        self.user = user
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

// MARK: - Token Refresh

public struct RefreshTokenRequest: Codable, Sendable {
    public let refreshToken: String

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

public struct RefreshTokenResponse: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String?

    public init(accessToken: String, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

// MARK: - User

public struct UserDTO: Codable, Sendable, Identifiable {
    public let id: UUID
    public let email: String
    public let displayName: String?
    public let timezone: String?
    public let createdAt: Date

    public init(
        id: UUID,
        email: String,
        displayName: String? = nil,
        timezone: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.timezone = timezone
        self.createdAt = createdAt
    }
}

// MARK: - Logout

public struct LogoutRequest: Codable, Sendable {
    public let refreshToken: String?
    public let allDevices: Bool

    public init(refreshToken: String? = nil, allDevices: Bool = false) {
        self.refreshToken = refreshToken
        self.allDevices = allDevices
    }
}
