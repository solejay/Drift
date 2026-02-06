import Fluent
import Vapor
import Crypto

final class RefreshToken: Model, Content, @unchecked Sendable {
    static let schema = "refresh_tokens"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "token_hash")
    var tokenHash: String

    @Field(key: "device_id")
    var deviceId: String?

    @Field(key: "is_revoked")
    var isRevoked: Bool

    @Field(key: "expires_at")
    var expiresAt: Date

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Field(key: "last_used_at")
    var lastUsedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        tokenHash: String,
        deviceId: String? = nil,
        expiresAt: Date
    ) {
        self.id = id
        self.$user.id = userID
        self.tokenHash = tokenHash
        self.deviceId = deviceId
        self.isRevoked = false
        self.expiresAt = expiresAt
    }

    var isValid: Bool {
        !isRevoked && expiresAt > Date()
    }

    /// Hash a refresh token using SHA-256 for fast, safe lookup.
    /// SHA-256 is appropriate here because refresh tokens are high-entropy
    /// random values (not user-chosen passwords), so brute-force is infeasible.
    static func hash(_ token: String) -> String {
        SHA256.hash(data: Data(token.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
}
