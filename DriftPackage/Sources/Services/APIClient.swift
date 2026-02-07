import Foundation
import Core

/// HTTP client for API communication
public actor APIClient {
    public static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private var accessToken: String?
    private var refreshToken: String?
    private var isRefreshing = false
    private var pendingRequests: [CheckedContinuation<Void, Error>] = []

    public init(
        baseURL: URL? = nil,
        session: URLSession = .shared
    ) {
        #if targetEnvironment(simulator)
        self.baseURL = baseURL ?? URL(string: "http://localhost:8080")!
        #else
        self.baseURL = baseURL ?? URL(string: "http://10.0.0.86:8080")!
        #endif
        self.session = session

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    // MARK: - Token Management

    public func setTokens(access: String, refresh: String) {
        self.accessToken = access
        self.refreshToken = refresh
    }

    public func clearTokens() {
        self.accessToken = nil
        self.refreshToken = nil
    }

    public var isAuthenticated: Bool {
        accessToken != nil
    }

    // MARK: - Request Methods

    public func get<T: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let request = try buildRequest(
            path: path,
            method: "GET",
            queryItems: queryItems
        )
        return try await execute(request)
    }

    public func post<T: Decodable, B: Encodable>(
        _ path: String,
        body: B
    ) async throws -> T {
        var request = try buildRequest(path: path, method: "POST")
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await execute(request)
    }

    public func post<T: Decodable>(
        _ path: String
    ) async throws -> T {
        let request = try buildRequest(path: path, method: "POST")
        return try await execute(request)
    }

    public func put<T: Decodable, B: Encodable>(
        _ path: String,
        body: B
    ) async throws -> T {
        var request = try buildRequest(path: path, method: "PUT")
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await execute(request)
    }

    public func delete<T: Decodable>(
        _ path: String
    ) async throws -> T {
        let request = try buildRequest(path: path, method: "DELETE")
        return try await execute(request)
    }

    public func delete(_ path: String) async throws {
        let request = try buildRequest(path: path, method: "DELETE")
        let _: EmptyResponse = try await execute(request)
    }

    // MARK: - Request Building

    private func buildRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem]? = nil
    ) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: true)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    // MARK: - Request Execution

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                if data.isEmpty, let empty = EmptyResponse() as? T {
                    return empty
                }
                return try decoder.decode(T.self, from: data)

            case 401:
                // Try to refresh token and retry
                if let _ = refreshToken {
                    try await refreshAccessToken()
                    var newRequest = request
                    if let token = accessToken {
                        newRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    }
                    return try await execute(newRequest)
                }
                throw APIError.unauthorized

            case 400:
                let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
                throw APIError.badRequest(errorResponse?.message ?? "Bad request")

            case 404:
                throw APIError.notFound

            case 422:
                let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
                throw APIError.validationError(errorResponse?.message ?? "Validation failed")

            case 500...599:
                throw APIError.serverError(httpResponse.statusCode)

            default:
                throw APIError.unexpectedStatusCode(httpResponse.statusCode)
            }
        } catch let error as APIError {
            throw error
        } catch let error as DecodingError {
            throw APIError.decodingError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Token Refresh

    private func refreshAccessToken() async throws {
        guard !isRefreshing else {
            // Wait for ongoing refresh
            try await withCheckedThrowingContinuation { continuation in
                pendingRequests.append(continuation)
            }
            return
        }

        isRefreshing = true
        defer {
            isRefreshing = false
            // Resume all pending requests
            for continuation in pendingRequests {
                continuation.resume()
            }
            pendingRequests.removeAll()
        }

        guard let refreshToken = refreshToken else {
            throw APIError.unauthorized
        }

        let request = RefreshTokenRequest(refreshToken: refreshToken)
        let response: RefreshTokenResponse = try await post("/api/v1/auth/refresh", body: request)

        self.accessToken = response.accessToken
        if let newRefresh = response.refreshToken {
            self.refreshToken = newRefresh
        }

        // Persist new tokens
        try await KeychainService.shared.save(response.accessToken, for: .accessToken)
        if let newRefresh = response.refreshToken {
            try await KeychainService.shared.save(newRefresh, for: .refreshToken)
        }
    }
}

// MARK: - Error Types

public enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case badRequest(String)
    case notFound
    case validationError(String)
    case serverError(Int)
    case unexpectedStatusCode(Int)
    case decodingError(DecodingError)
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Please log in again"
        case .badRequest(let message):
            return message
        case .notFound:
            return "Resource not found"
        case .validationError(let message):
            return message
        case .serverError(let code):
            return "Server error (\(code))"
        case .unexpectedStatusCode(let code):
            return "Unexpected response (\(code))"
        case .decodingError(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Response Types

private struct ErrorResponse: Decodable {
    let message: String
    let error: Bool?
}

private struct EmptyResponse: Decodable {}
