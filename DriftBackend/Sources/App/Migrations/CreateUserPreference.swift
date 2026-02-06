import Fluent

struct CreateUserPreference: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("user_preferences")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("notification_time", .string, .required)
            .field("selected_categories", .array(of: .string), .required)
            .field("notification_enabled", .bool, .required)
            .field("weekly_summary_enabled", .bool, .required)
            .field("daily_summary_enabled", .bool, .required)
            .field("timezone", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "user_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("user_preferences").delete()
    }
}
