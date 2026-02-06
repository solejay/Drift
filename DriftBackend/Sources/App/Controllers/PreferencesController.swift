import Vapor
import Fluent

struct PreferencesController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let preferences = routes.grouped("preferences")
        preferences.get(use: get)
        preferences.put(use: update)
    }

    // MARK: - Get Preferences

    func get(req: Request) async throws -> PreferenceResponse {
        let userId = try req.userId

        // Return existing or create defaults
        if let existing = try await UserPreference.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first() {
            return existing.toDTO()
        }

        // Create default preferences
        let user = try await req.requireUser()
        let preference = UserPreference(
            userID: userId,
            timezone: user.timezone ?? "UTC"
        )
        try await preference.save(on: req.db)

        return preference.toDTO()
    }

    // MARK: - Update Preferences

    func update(req: Request) async throws -> PreferenceResponse {
        let userId = try req.userId
        let input = try req.content.decode(UpdatePreferenceRequest.self)

        // Find or create preferences
        let preference: UserPreference
        if let existing = try await UserPreference.query(on: req.db)
            .filter(\.$user.$id == userId)
            .first() {
            preference = existing
        } else {
            let user = try await req.requireUser()
            preference = UserPreference(
                userID: userId,
                timezone: user.timezone ?? "UTC"
            )
        }

        // Apply updates
        if let notificationTime = input.notificationTime {
            preference.notificationTime = notificationTime
        }
        if let selectedCategories = input.selectedCategories {
            preference.selectedCategories = selectedCategories
        }
        if let notificationEnabled = input.notificationEnabled {
            preference.notificationEnabled = notificationEnabled
        }
        if let weeklySummaryEnabled = input.weeklySummaryEnabled {
            preference.weeklySummaryEnabled = weeklySummaryEnabled
        }
        if let dailySummaryEnabled = input.dailySummaryEnabled {
            preference.dailySummaryEnabled = dailySummaryEnabled
        }
        if let timezone = input.timezone {
            guard InputValidation.isValidTimezone(timezone) else {
                throw Abort(.badRequest, reason: "Invalid timezone identifier")
            }
            preference.timezone = timezone
        }

        try await preference.save(on: req.db)

        return preference.toDTO()
    }
}
