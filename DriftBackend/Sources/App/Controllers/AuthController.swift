import Vapor
import Fluent

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register", use: register)
        auth.post("login", use: login)
        auth.post("refresh", use: refresh)

        // Protected routes
        let protected = auth.grouped(JWTAuthMiddleware())
        protected.post("logout", use: logout)
        protected.delete("account", use: deleteAccount)
    }

    // MARK: - Register

    struct RegisterRequest: Content {
        let email: String
        let password: String
        let displayName: String?
        let timezone: String?
    }

    struct AuthResponse: Content {
        let user: UserDTO
        let accessToken: String
        let refreshToken: String
    }

    func register(req: Request) async throws -> AuthResponse {
        let input = try req.content.decode(RegisterRequest.self)

        // Validate email
        let sanitizedEmail = InputValidation.sanitize(input.email)
        guard InputValidation.isValidEmail(sanitizedEmail) else {
            throw Abort(.badRequest, reason: "Invalid email address")
        }

        // Validate password: 8+ chars, at least 1 uppercase, 1 number
        guard InputValidation.isValidPassword(input.password) else {
            throw Abort(.badRequest, reason: "Password must be at least 8 characters with at least 1 uppercase letter and 1 number")
        }

        // Check if email exists
        let existing = try await User.query(on: req.db)
            .filter(\.$email == sanitizedEmail.lowercased())
            .first()

        guard existing == nil else {
            throw Abort(.conflict, reason: "Email already registered")
        }

        // Create user
        let passwordHash = try Bcrypt.hash(input.password)
        let displayName = input.displayName.map { InputValidation.sanitize($0) }
        let user = User(
            email: sanitizedEmail.lowercased(),
            passwordHash: passwordHash,
            displayName: displayName,
            timezone: input.timezone ?? "UTC"
        )

        try await user.save(on: req.db)

        guard let userId = user.id else {
            throw Abort(.internalServerError, reason: "Failed to create user")
        }

        // Generate tokens
        let accessToken = try req.application.generateAccessToken(for: user)
        let refreshTokenString = req.application.generateRefreshToken()

        // Save refresh token (SHA-256 hash for fast lookup)
        let refreshToken = RefreshToken(
            userID: userId,
            tokenHash: RefreshToken.hash(refreshTokenString),
            expiresAt: Date().addingTimeInterval(30 * 24 * 3600) // 30 days
        )
        try await refreshToken.save(on: req.db)

        return AuthResponse(
            user: user.toDTO(),
            accessToken: accessToken,
            refreshToken: refreshTokenString
        )
    }

    // MARK: - Login

    struct LoginRequest: Content {
        let email: String
        let password: String
        let deviceId: String?
    }

    func login(req: Request) async throws -> AuthResponse {
        let input = try req.content.decode(LoginRequest.self)
        let sanitizedEmail = InputValidation.sanitize(input.email)

        // Find user
        guard let user = try await User.query(on: req.db)
            .filter(\.$email == sanitizedEmail.lowercased())
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }

        // Verify password
        guard try user.verify(password: input.password) else {
            throw Abort(.unauthorized, reason: "Invalid email or password")
        }

        guard let userId = user.id else {
            throw Abort(.internalServerError, reason: "User record invalid")
        }

        // Generate tokens
        let accessToken = try req.application.generateAccessToken(for: user)
        let refreshTokenString = req.application.generateRefreshToken()

        // Save refresh token (SHA-256 hash for fast lookup)
        let refreshToken = RefreshToken(
            userID: userId,
            tokenHash: RefreshToken.hash(refreshTokenString),
            deviceId: input.deviceId,
            expiresAt: Date().addingTimeInterval(30 * 24 * 3600)
        )
        try await refreshToken.save(on: req.db)

        return AuthResponse(
            user: user.toDTO(),
            accessToken: accessToken,
            refreshToken: refreshTokenString
        )
    }

    // MARK: - Refresh

    struct RefreshRequest: Content {
        let refreshToken: String
    }

    struct RefreshResponse: Content {
        let accessToken: String
        let refreshToken: String?
    }

    func refresh(req: Request) async throws -> RefreshResponse {
        let input = try req.content.decode(RefreshRequest.self)

        // Direct lookup by SHA-256 hash (O(1) instead of O(n) Bcrypt scan)
        let hashedToken = RefreshToken.hash(input.refreshToken)

        guard let token = try await RefreshToken.query(on: req.db)
            .filter(\.$tokenHash == hashedToken)
            .filter(\.$isRevoked == false)
            .first(),
            token.isValid else {
            throw Abort(.unauthorized, reason: "Invalid or expired refresh token")
        }

        // Get user
        guard let user = try await User.find(token.$user.id, on: req.db) else {
            throw Abort(.unauthorized, reason: "User not found")
        }

        // Generate new access token
        let accessToken = try req.application.generateAccessToken(for: user)

        // Update last used
        token.lastUsedAt = Date()
        try await token.save(on: req.db)

        return RefreshResponse(
            accessToken: accessToken,
            refreshToken: nil
        )
    }

    // MARK: - Logout

    struct LogoutRequest: Content {
        let refreshToken: String?
        let allDevices: Bool
    }

    func logout(req: Request) async throws -> HTTPStatus {
        let input = try req.content.decode(LogoutRequest.self)
        let userId = try req.userId

        if input.allDevices {
            // Revoke all tokens for user
            try await RefreshToken.query(on: req.db)
                .filter(\.$user.$id == userId)
                .set(\.$isRevoked, to: true)
                .update()
        } else if let tokenString = input.refreshToken {
            // Direct lookup by SHA-256 hash
            let hashedToken = RefreshToken.hash(tokenString)
            if let token = try await RefreshToken.query(on: req.db)
                .filter(\.$user.$id == userId)
                .filter(\.$tokenHash == hashedToken)
                .first() {
                token.isRevoked = true
                try await token.save(on: req.db)
            }
        }

        return .ok
    }

    // MARK: - Delete Account (CCPA/PIPEDA compliance)

    struct DeleteAccountRequest: Content {
        let password: String
    }

    func deleteAccount(req: Request) async throws -> HTTPStatus {
        let userId = try req.userId
        let input = try req.content.decode(DeleteAccountRequest.self)

        // Verify user and password
        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        guard try user.verify(password: input.password) else {
            throw Abort(.unauthorized, reason: "Invalid password")
        }

        // Cascade delete all associated data
        // Order matters: delete children before parents

        // Delete device tokens
        try await DeviceToken.query(on: req.db)
            .filter(\.$user.$id == userId)
            .delete()

        // Delete user preferences
        try await UserPreference.query(on: req.db)
            .filter(\.$user.$id == userId)
            .delete()

        // Delete transactions
        try await Transaction.query(on: req.db)
            .filter(\.$user.$id == userId)
            .delete()

        // Delete accounts
        try await Account.query(on: req.db)
            .filter(\.$user.$id == userId)
            .delete()

        // Delete plaid items
        try await PlaidItem.query(on: req.db)
            .filter(\.$user.$id == userId)
            .delete()

        // Delete refresh tokens
        try await RefreshToken.query(on: req.db)
            .filter(\.$user.$id == userId)
            .delete()

        // Delete user
        try await user.delete(on: req.db)

        return .ok
    }
}
