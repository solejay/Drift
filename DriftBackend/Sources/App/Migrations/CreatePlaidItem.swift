import Fluent

struct CreatePlaidItem: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("plaid_items")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("plaid_item_id", .string, .required)
            .field("access_token", .string, .required)
            .field("institution_id", .string)
            .field("institution_name", .string)
            .field("cursor", .string)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "plaid_item_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("plaid_items").delete()
    }
}
