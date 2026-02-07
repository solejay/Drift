import Vapor
import Fluent

func routes(_ app: Application) throws {
    // MARK: - Health Check

    app.get("health") { req async -> HealthCheckResponse in
        var dbStatus = "disconnected"
        do {
            // Use a simple query to verify DB connectivity
            _ = try await User.query(on: req.db).count()
            dbStatus = "connected"
        } catch {
            req.logger.error("Health check DB error: \(error)")
        }

        return HealthCheckResponse(
            status: "healthy",
            version: "1.0.0",
            database: dbStatus
        )
    }

    // MARK: - API v1 Routes

    let api = app.grouped("api", "v1")

    // Auth routes (no authentication required)
    try api.register(collection: AuthController())

    // Plaid webhook (unprotected but verified)
    api.grouped("plaid").post("webhook", use: PlaidController.webhookHandler)

    // Protected routes
    let protected = api.grouped(JWTAuthMiddleware())

    // User profile
    protected.grouped("user").get("profile") { req async throws -> UserDTO in
        let userId = try req.userId
        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        return user.toDTO()
    }

    // Plaid routes
    try protected.register(collection: PlaidController())

    // Account routes
    try protected.register(collection: AccountController())

    // Transaction routes
    try protected.register(collection: TransactionController())

    // Summary routes
    try protected.register(collection: SummaryController())

    // Preferences routes
    try protected.register(collection: PreferencesController())

    // Notification routes
    try protected.register(collection: NotificationController())

    // Export routes
    try protected.register(collection: ExportController())
}

// MARK: - Health Check DTO

struct HealthCheckResponse: Content {
    let status: String
    let version: String
    let database: String
}
