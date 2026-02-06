import Fluent

struct CreateAccount: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("accounts")
            .id()
            .field("plaid_item_id", .uuid, .required, .references("plaid_items", "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("plaid_account_id", .string, .required)
            .field("name", .string, .required)
            .field("official_name", .string)
            .field("type", .string, .required)
            .field("subtype", .string)
            .field("mask", .string)
            .field("current_balance", .double)
            .field("available_balance", .double)
            .field("is_hidden", .bool, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "plaid_account_id")
            .create()

        // Index for faster user account lookups
        try await database.schema("accounts")
            .foreignKey("user_id", references: "users", "id")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("accounts").delete()
    }
}
