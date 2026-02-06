import Vapor
import Fluent

struct NotificationController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let notifications = routes.grouped("notifications")
        notifications.post("register-device", use: registerDevice)
        notifications.delete("unregister-device", use: unregisterDevice)
        notifications.post("test", use: testNotification)
    }

    // MARK: - Register Device

    func registerDevice(req: Request) async throws -> DeviceTokenResponse {
        let userId = try req.userId
        let input = try req.content.decode(RegisterDeviceRequest.self)

        // Validate platform
        guard ["ios", "android"].contains(input.platform.lowercased()) else {
            throw Abort(.badRequest, reason: "Platform must be 'ios' or 'android'")
        }

        // Check if token already exists for this user
        if let existing = try await DeviceToken.query(on: req.db)
            .filter(\.$token == input.token)
            .first() {
            // Update to current user if different
            if existing.$user.id != userId {
                existing.$user.id = userId
                try await existing.save(on: req.db)
            }
            return existing.toDTO()
        }

        // Create new device token
        let deviceToken = DeviceToken(
            userID: userId,
            token: input.token,
            platform: input.platform.lowercased()
        )
        try await deviceToken.save(on: req.db)

        return deviceToken.toDTO()
    }

    // MARK: - Unregister Device

    func unregisterDevice(req: Request) async throws -> HTTPStatus {
        let userId = try req.userId
        let input = try req.content.decode(UnregisterDeviceRequest.self)

        try await DeviceToken.query(on: req.db)
            .filter(\.$user.$id == userId)
            .filter(\.$token == input.token)
            .delete()

        return .ok
    }

    // MARK: - Test Notification

    func testNotification(req: Request) async throws -> NotificationTestResponse {
        let userId = try req.userId

        // Check if user has any registered devices
        let deviceCount = try await DeviceToken.query(on: req.db)
            .filter(\.$user.$id == userId)
            .count()

        if deviceCount == 0 {
            return NotificationTestResponse(
                success: false,
                message: "No registered devices found. Please register a device first."
            )
        }

        // Placeholder: actual push notification sending would go here
        return NotificationTestResponse(
            success: true,
            message: "Test notification queued for \(deviceCount) device(s)."
        )
    }
}
