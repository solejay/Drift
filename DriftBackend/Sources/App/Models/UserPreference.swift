import Fluent
import Vapor

final class UserPreference: Model, Content, @unchecked Sendable {
    static let schema = "user_preferences"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: "user_id")
    var user: User

    @Field(key: "notification_time")
    var notificationTime: String

    @Field(key: "selected_categories")
    var selectedCategories: [String]

    @Field(key: "notification_enabled")
    var notificationEnabled: Bool

    @Field(key: "weekly_summary_enabled")
    var weeklySummaryEnabled: Bool

    @Field(key: "daily_summary_enabled")
    var dailySummaryEnabled: Bool

    @Field(key: "timezone")
    var timezone: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        notificationTime: String = "20:00",
        selectedCategories: [String] = [],
        notificationEnabled: Bool = true,
        weeklySummaryEnabled: Bool = true,
        dailySummaryEnabled: Bool = true,
        timezone: String = "UTC"
    ) {
        self.id = id
        self.$user.id = userID
        self.notificationTime = notificationTime
        self.selectedCategories = selectedCategories
        self.notificationEnabled = notificationEnabled
        self.weeklySummaryEnabled = weeklySummaryEnabled
        self.dailySummaryEnabled = dailySummaryEnabled
        self.timezone = timezone
    }
}
