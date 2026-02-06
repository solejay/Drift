import Vapor
import JWT

struct JWTAuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Extract token from Authorization header
        guard let authHeader = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "Missing authorization header")
        }

        // Verify and decode the JWT
        do {
            let payload = try request.jwt.verify(authHeader.token, as: DriftJWTPayload.self)

            // Store the user ID in request storage for controllers to access
            request.auth.login(payload)

        } catch {
            throw Abort(.unauthorized, reason: "Invalid or expired token")
        }

        return try await next.respond(to: request)
    }
}

// MARK: - Request Extensions

extension Request {
    var userId: UUID {
        get throws {
            guard let payload = auth.get(DriftJWTPayload.self) else {
                throw Abort(.unauthorized, reason: "User not authenticated")
            }
            return payload.userId
        }
    }

    func requireUser() async throws -> User {
        let userId = try self.userId
        guard let user = try await User.find(userId, on: db) else {
            throw Abort(.unauthorized, reason: "User not found")
        }
        return user
    }
}
