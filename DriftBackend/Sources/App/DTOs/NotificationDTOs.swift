import Vapor

// MARK: - Request

struct RegisterDeviceRequest: Content {
    let token: String
    let platform: String
}

struct UnregisterDeviceRequest: Content {
    let token: String
}

// MARK: - Response

struct DeviceTokenResponse: Content {
    let id: UUID
    let token: String
    let platform: String
    let createdAt: Date?
}

struct NotificationTestResponse: Content {
    let success: Bool
    let message: String
}

// MARK: - Conversion

extension DeviceToken {
    func toDTO() -> DeviceTokenResponse {
        DeviceTokenResponse(
            id: id!,
            token: token,
            platform: platform,
            createdAt: createdAt
        )
    }
}
