import Fluent

struct CreateTransaction: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("transactions")
            .id()
            .field("account_id", .uuid, .required, .references("accounts", "id", onDelete: .cascade))
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("plaid_transaction_id", .string)
            .field("amount", .double, .required)
            .field("date", .datetime, .required)
            .field("merchant_name", .string, .required)
            .field("category", .string, .required)
            .field("description", .string)
            .field("is_pending", .bool, .required)
            .field("is_excluded", .bool, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()

        // Index for faster transaction queries
        try await database.schema("transactions")
            .unique(on: "plaid_transaction_id")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("transactions").delete()
    }
}
