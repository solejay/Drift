import JWT
import Vapor

struct DriftJWTPayload: JWTPayload, Authenticatable {
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case expiration = "exp"
        case issuedAt = "iat"
        case userId = "user_id"
    }

    var subject: SubjectClaim
    var expiration: ExpirationClaim
    var issuedAt: IssuedAtClaim
    var userId: UUID

    init(userId: UUID) {
        self.subject = SubjectClaim(value: userId.uuidString)
        self.userId = userId
        self.issuedAt = IssuedAtClaim(value: Date())
        // Access token expires in 1 hour
        self.expiration = ExpirationClaim(value: Date().addingTimeInterval(3600))
    }

    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
    }
}

// MARK: - Token Generation

extension Application {
    func generateAccessToken(for user: User) throws -> String {
        guard let userId = user.id else {
            throw Abort(.internalServerError, reason: "User ID unavailable")
        }
        let payload = DriftJWTPayload(userId: userId)
        return try jwt.signers.sign(payload)
    }

    func generateRefreshToken() -> String {
        // Generate a random 256-bit token
        let bytes = [UInt8].random(count: 32)
        return Data(bytes).base64EncodedString()
    }
}
