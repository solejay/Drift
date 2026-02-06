import Fluent
import Vapor

final class PlaidItem: Model, Content, @unchecked Sendable {
    static let schema = "plaid_items"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "plaid_item_id")
    var plaidItemId: String

    // SECURITY NOTE: In production, Plaid access tokens should be encrypted at rest.
    // Use application-level AES-256 encryption with a key from PLAID_ENCRYPTION_KEY env var,
    // or rely on database-level encryption (e.g., PostgreSQL TDE, AWS RDS encryption).
    @Field(key: "access_token")
    var accessToken: String

    @Field(key: "institution_id")
    var institutionId: String?

    @Field(key: "institution_name")
    var institutionName: String?

    @Field(key: "cursor")
    var cursor: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    @Children(for: \.$plaidItem)
    var accounts: [Account]

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        plaidItemId: String,
        accessToken: String,
        institutionId: String? = nil,
        institutionName: String? = nil
    ) {
        self.id = id
        self.$user.id = userID
        self.plaidItemId = plaidItemId
        self.accessToken = accessToken
        self.institutionId = institutionId
        self.institutionName = institutionName
        self.cursor = nil
    }
}
