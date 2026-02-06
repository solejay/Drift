import Fluent

struct CreateRefreshToken: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("refresh_tokens")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("token_hash", .string, .required)
            .field("device_id", .string)
            .field("is_revoked", .bool, .required)
            .field("expires_at", .datetime, .required)
            .field("created_at", .datetime)
            .field("last_used_at", .datetime)
            .create()

        // Index for faster token lookups
        try await database.schema("refresh_tokens")
            .unique(on: "token_hash")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("refresh_tokens").delete()
    }
}
