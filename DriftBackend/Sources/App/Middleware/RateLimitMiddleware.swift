import Vapor
import JWT

actor RateLimiter {
    private var requests: [String: [Date]] = [:]
    private let window: TimeInterval

    init(window: TimeInterval = 60) {
        self.window = window
    }

    func checkLimit(for key: String, limit: Int) -> Bool {
        let now = Date()
        let windowStart = now.addingTimeInterval(-window)

        // Clean old requests
        var keyRequests = requests[key] ?? []
        keyRequests = keyRequests.filter { $0 > windowStart }

        // Check limit
        if keyRequests.count >= limit {
            return false
        }

        // Add new request
        keyRequests.append(now)
        requests[key] = keyRequests

        return true
    }
}

struct RateLimitMiddleware: AsyncMiddleware {
    private let limiter = RateLimiter()

    // 100 requests per minute for authenticated users
    private let authenticatedLimit = 100
    // 20 requests per minute for unauthenticated endpoints
    private let unauthenticatedLimit = 20

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Try to identify by authenticated user ID first
        let key: String
        let limit: Int

        if let authHeader = request.headers.bearerAuthorization,
           let payload = try? request.jwt.verify(authHeader.token, as: DriftJWTPayload.self) {
            // Authenticated user: rate limit by user ID
            key = "user:\(payload.userId.uuidString)"
            limit = authenticatedLimit
        } else {
            // Unauthenticated: rate limit by IP
            key = "ip:\(request.remoteAddress?.ipAddress ?? "unknown")"
            limit = unauthenticatedLimit
        }

        let allowed = await limiter.checkLimit(for: key, limit: limit)

        guard allowed else {
            throw Abort(.tooManyRequests, reason: "Rate limit exceeded. Try again later.")
        }

        return try await next.respond(to: request)
    }
}
