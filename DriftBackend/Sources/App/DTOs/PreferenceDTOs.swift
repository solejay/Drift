import Vapor

// MARK: - Response

struct PreferenceResponse: Content {
    let id: UUID
    let notificationTime: String
    let selectedCategories: [String]
    let notificationEnabled: Bool
    let weeklySummaryEnabled: Bool
    let dailySummaryEnabled: Bool
    let timezone: String
    let createdAt: Date?
    let updatedAt: Date?
}

// MARK: - Request

struct UpdatePreferenceRequest: Content {
    let notificationTime: String?
    let selectedCategories: [String]?
    let notificationEnabled: Bool?
    let weeklySummaryEnabled: Bool?
    let dailySummaryEnabled: Bool?
    let timezone: String?
}

// MARK: - Conversion

extension UserPreference {
    func toDTO() -> PreferenceResponse {
        PreferenceResponse(
            id: id!,
            notificationTime: notificationTime,
            selectedCategories: selectedCategories,
            notificationEnabled: notificationEnabled,
            weeklySummaryEnabled: weeklySummaryEnabled,
            dailySummaryEnabled: dailySummaryEnabled,
            timezone: timezone,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
