import Vapor

// Auth DTOs are defined inline in AuthController for simplicity
// This file can be used for shared auth-related types if needed

struct ErrorResponse: Content {
    let error: Bool
    let message: String

    init(message: String) {
        self.error = true
        self.message = message
    }
}
