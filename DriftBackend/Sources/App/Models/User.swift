import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Field(key: "display_name")
    var displayName: String?

    @Field(key: "timezone")
    var timezone: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Children(for: \.$user)
    var refreshTokens: [RefreshToken]

    @Children(for: \.$user)
    var plaidItems: [PlaidItem]

    @Children(for: \.$user)
    var accounts: [Account]

    init() {}

    init(
        id: UUID? = nil,
        email: String,
        passwordHash: String,
        displayName: String? = nil,
        timezone: String? = nil
    ) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.displayName = displayName
        self.timezone = timezone
    }
}

// MARK: - ModelAuthenticatable

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

// MARK: - DTO Conversion

extension User {
    func toDTO() -> UserDTO {
        UserDTO(
            id: id!,
            email: email,
            displayName: displayName,
            timezone: timezone,
            createdAt: createdAt ?? Date()
        )
    }
}

// MARK: - User DTO

struct UserDTO: Content {
    let id: UUID
    let email: String
    let displayName: String?
    let timezone: String?
    let createdAt: Date
}
