import Fluent

struct CreateDeviceToken: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("device_tokens")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("token", .string, .required)
            .field("platform", .string, .required)
            .field("created_at", .datetime)
            .create()

        // Index for faster token lookups
        try await database.schema("device_tokens")
            .unique(on: "token")
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.schema("device_tokens").delete()
    }
}
