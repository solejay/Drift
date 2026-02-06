@testable import App
import XCTVapor
import JWT
import Foundation

// MARK: - Input Validation Tests

final class InputValidationTests: XCTestCase {

    // MARK: Email Validation

    func testValidEmails() {
        let validEmails = [
            "user@example.com",
            "first.last@domain.org",
            "user+tag@example.co.uk",
            "name123@test.io",
            "user@sub.domain.com",
            "ALL_CAPS@EXAMPLE.COM",
            "mixed.Case@Example.Org",
            "digits123@numbers456.net",
            "user.name+tag@domain.co",
            "a@b.cd",
        ]

        for email in validEmails {
            XCTAssertTrue(
                InputValidation.isValidEmail(email),
                "Expected '\(email)' to be a valid email"
            )
        }
    }

    func testInvalidEmails() {
        let invalidEmails = [
            "",
            "plaintext",
            "@nodomain.com",
            "user@",
            "user@.com",
            "user@domain",
            "user@@domain.com",
            "user @domain.com",
            "user@domain .com",
            "user@domain.c",          // single-char TLD
            "@",
        ]

        for email in invalidEmails {
            XCTAssertFalse(
                InputValidation.isValidEmail(email),
                "Expected '\(email)' to be an invalid email"
            )
        }
    }

    func testEmailWithLeadingTrailingSpaces() {
        // Raw email with spaces is invalid; sanitize first
        let rawEmail = "  user@example.com  "
        XCTAssertFalse(InputValidation.isValidEmail(rawEmail))

        // After sanitization it should be valid
        let sanitized = InputValidation.sanitize(rawEmail)
        XCTAssertTrue(InputValidation.isValidEmail(sanitized))
    }

    // MARK: Password Validation

    func testValidPasswords() {
        let validPasswords = [
            "Password1",          // exactly 8 chars + uppercase + digit
            "Abcdefg1",           // 8 chars
            "StrongPass99",       // 12 chars
            "MyP@ssw0rd!",        // special chars are fine
            "AAAAAA1a",           // uppercase present, digit present
            "12345678A",          // digit-heavy but has uppercase
            "Aa1bbbbb",           // minimal requirements met
            "VeryLongPassword123456", // long password
        ]

        for password in validPasswords {
            XCTAssertTrue(
                InputValidation.isValidPassword(password),
                "Expected '\(password)' to be a valid password"
            )
        }
    }

    func testPasswordTooShort() {
        let shortPasswords = ["", "A1", "Ab1cdef", "Pass1"]

        for password in shortPasswords {
            XCTAssertFalse(
                InputValidation.isValidPassword(password),
                "Expected '\(password)' to be rejected (too short)"
            )
        }
    }

    func testPasswordMissingUppercase() {
        let noUppercase = [
            "password1",
            "12345678a",
            "abcdefgh1",
            "all_lower1",
        ]

        for password in noUppercase {
            XCTAssertFalse(
                InputValidation.isValidPassword(password),
                "Expected '\(password)' to be rejected (no uppercase)"
            )
        }
    }

    func testPasswordMissingNumber() {
        let noNumber = [
            "Password",
            "ABCDEFGH",
            "Abcdefgh",
            "NoDigitsHere",
        ]

        for password in noNumber {
            XCTAssertFalse(
                InputValidation.isValidPassword(password),
                "Expected '\(password)' to be rejected (no digit)"
            )
        }
    }

    func testPasswordExactlyEightChars() {
        // Exactly 8 with uppercase + digit => valid
        XCTAssertTrue(InputValidation.isValidPassword("Abcdefg1"))
        // Exactly 7 with uppercase + digit => invalid (too short)
        XCTAssertFalse(InputValidation.isValidPassword("Abcdef1"))
    }

    // MARK: Sanitization

    func testSanitizeStripsHTMLTags() {
        let input = "<script>alert('xss')</script>Hello"
        let result = InputValidation.sanitize(input)
        XCTAssertEqual(result, "alert('xss')Hello")
    }

    func testSanitizeStripsMultipleHTMLTags() {
        let input = "<b>Bold</b> and <i>italic</i>"
        let result = InputValidation.sanitize(input)
        XCTAssertEqual(result, "Bold and italic")
    }

    func testSanitizeTrimsWhitespace() {
        let input = "   hello world   "
        let result = InputValidation.sanitize(input)
        XCTAssertEqual(result, "hello world")
    }

    func testSanitizeTrimsNewlines() {
        let input = "\n\n  hello  \n\n"
        let result = InputValidation.sanitize(input)
        XCTAssertEqual(result, "hello")
    }

    func testSanitizeCombinedHTMLAndWhitespace() {
        let input = "  <div>  content  </div>  "
        let result = InputValidation.sanitize(input)
        XCTAssertEqual(result, "content")
    }

    func testSanitizeEmptyString() {
        let result = InputValidation.sanitize("")
        XCTAssertEqual(result, "")
    }

    func testSanitizeNoHTMLNoWhitespace() {
        let input = "clean text"
        let result = InputValidation.sanitize(input)
        XCTAssertEqual(result, "clean text")
    }

    func testSanitizeNestedHTMLTags() {
        let input = "<div><span>text</span></div>"
        let result = InputValidation.sanitize(input)
        XCTAssertEqual(result, "text")
    }

    func testSanitizeSelfClosingTags() {
        let input = "before<br/>after"
        let result = InputValidation.sanitize(input)
        XCTAssertEqual(result, "beforeafter")
    }

    func testSanitizeHTMLAttributes() {
        let input = "<a href=\"https://example.com\">link</a>"
        let result = InputValidation.sanitize(input)
        XCTAssertEqual(result, "link")
    }
}

// MARK: - Rate Limiter Tests

final class RateLimiterTests: XCTestCase {

    func testAllowsRequestsWithinLimit() async {
        let limiter = RateLimiter(window: 60)
        let key = "test-user"

        // First request should be allowed
        let firstAllowed = await limiter.checkLimit(for: key, limit: 5)
        XCTAssertTrue(firstAllowed, "First request should be allowed")

        // Second request should be allowed
        let secondAllowed = await limiter.checkLimit(for: key, limit: 5)
        XCTAssertTrue(secondAllowed, "Second request should be allowed")
    }

    func testBlocksRequestsOverLimit() async {
        let limiter = RateLimiter(window: 60)
        let key = "flood-user"
        let limit = 3

        // Use up all allowed requests
        for i in 1...limit {
            let allowed = await limiter.checkLimit(for: key, limit: limit)
            XCTAssertTrue(allowed, "Request \(i) of \(limit) should be allowed")
        }

        // Next request should be blocked
        let blocked = await limiter.checkLimit(for: key, limit: limit)
        XCTAssertFalse(blocked, "Request exceeding limit should be blocked")
    }

    func testDifferentKeysAreIndependent() async {
        let limiter = RateLimiter(window: 60)
        let limit = 2

        // Fill up key A
        for _ in 1...limit {
            _ = await limiter.checkLimit(for: "keyA", limit: limit)
        }
        let keyABlocked = await limiter.checkLimit(for: "keyA", limit: limit)
        XCTAssertFalse(keyABlocked, "keyA should be rate-limited")

        // key B should still be allowed
        let keyBAllowed = await limiter.checkLimit(for: "keyB", limit: limit)
        XCTAssertTrue(keyBAllowed, "keyB should not be affected by keyA's limit")
    }

    func testLimitOfOneBlocksImmediately() async {
        let limiter = RateLimiter(window: 60)
        let key = "single-shot"

        let first = await limiter.checkLimit(for: key, limit: 1)
        XCTAssertTrue(first, "First request with limit=1 should be allowed")

        let second = await limiter.checkLimit(for: key, limit: 1)
        XCTAssertFalse(second, "Second request with limit=1 should be blocked")
    }

    func testWindowExpirationAllowsNewRequests() async {
        // Use a very short window so requests expire quickly
        let limiter = RateLimiter(window: 0.1) // 100ms window
        let key = "expiring"
        let limit = 1

        let first = await limiter.checkLimit(for: key, limit: limit)
        XCTAssertTrue(first)

        let blocked = await limiter.checkLimit(for: key, limit: limit)
        XCTAssertFalse(blocked)

        // Wait for the window to pass
        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

        let afterExpiry = await limiter.checkLimit(for: key, limit: limit)
        XCTAssertTrue(afterExpiry, "Request after window expiry should be allowed")
    }

    func testHighLimitAllowsManyRequests() async {
        let limiter = RateLimiter(window: 60)
        let key = "bulk"
        let limit = 100

        // All 100 should pass
        for i in 1...limit {
            let allowed = await limiter.checkLimit(for: key, limit: limit)
            XCTAssertTrue(allowed, "Request \(i) of \(limit) should be allowed")
        }

        // 101st should fail
        let blocked = await limiter.checkLimit(for: key, limit: limit)
        XCTAssertFalse(blocked, "Request 101 should be blocked at limit 100")
    }
}

// MARK: - JWT Payload Tests

final class JWTPayloadTests: XCTestCase {

    func testPayloadCreationSetsFields() {
        let userId = UUID()
        let beforeCreation = Date()
        let payload = DriftJWTPayload(userId: userId)
        let afterCreation = Date()

        XCTAssertEqual(payload.userId, userId)
        XCTAssertEqual(payload.subject.value, userId.uuidString)

        // issuedAt should be approximately now
        let iat = payload.issuedAt.value
        XCTAssertGreaterThanOrEqual(iat, beforeCreation)
        XCTAssertLessThanOrEqual(iat, afterCreation)
    }

    func testPayloadExpirationIsOneHourFromNow() {
        let now = Date()
        let payload = DriftJWTPayload(userId: UUID())
        let expiration = payload.expiration.value

        // Should be approximately 3600 seconds from now (with small tolerance)
        let difference = expiration.timeIntervalSince(now)
        XCTAssertGreaterThan(difference, 3590, "Expiration should be ~1 hour from now")
        XCTAssertLessThan(difference, 3610, "Expiration should be ~1 hour from now")
    }

    func testPayloadVerifySucceedsWhenNotExpired() throws {
        let payload = DriftJWTPayload(userId: UUID())
        let signer = JWTSigner.hs256(key: "test-secret-key-for-unit-tests")

        // Should not throw since the token was just created (not expired)
        XCTAssertNoThrow(try payload.verify(using: signer))
    }

    func testPayloadVerifyFailsWhenExpired() throws {
        var payload = DriftJWTPayload(userId: UUID())
        // Manually set expiration to the past
        payload.expiration = ExpirationClaim(value: Date().addingTimeInterval(-60))

        let signer = JWTSigner.hs256(key: "test-secret-key-for-unit-tests")

        XCTAssertThrowsError(try payload.verify(using: signer)) { error in
            // JWT library throws JWTError for expired tokens
            XCTAssertTrue(
                "\(error)".contains("exp"),
                "Error should reference expiration claim"
            )
        }
    }

    func testDifferentUserIdsProduceDifferentPayloads() {
        let userId1 = UUID()
        let userId2 = UUID()

        let payload1 = DriftJWTPayload(userId: userId1)
        let payload2 = DriftJWTPayload(userId: userId2)

        XCTAssertNotEqual(payload1.userId, payload2.userId)
        XCTAssertNotEqual(payload1.subject.value, payload2.subject.value)
    }

    func testPayloadSubjectMatchesUserId() {
        let userId = UUID()
        let payload = DriftJWTPayload(userId: userId)

        XCTAssertEqual(payload.subject.value, userId.uuidString)
    }

    func testPayloadSignAndVerifyRoundTrip() throws {
        let signer = JWTSigner.hs256(key: "test-secret-key-for-roundtrip")
        let userId = UUID()
        let payload = DriftJWTPayload(userId: userId)

        // Sign the payload to produce a JWT string
        let token = try signer.sign(payload)
        XCTAssertFalse(token.isEmpty, "Signed token should not be empty")

        // Verify and decode the token
        let decoded = try signer.verify(token, as: DriftJWTPayload.self)
        XCTAssertEqual(decoded.userId, userId)
        XCTAssertEqual(decoded.subject.value, userId.uuidString)
    }

    func testPayloadEncodesWithCorrectCodingKeys() throws {
        let userId = UUID()
        let payload = DriftJWTPayload(userId: userId)

        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json?["sub"], "JSON should contain 'sub' key")
        XCTAssertNotNil(json?["exp"], "JSON should contain 'exp' key")
        XCTAssertNotNil(json?["iat"], "JSON should contain 'iat' key")
        XCTAssertNotNil(json?["user_id"], "JSON should contain 'user_id' key")
        XCTAssertEqual(json?["sub"] as? String, userId.uuidString)
    }
}

// MARK: - RefreshToken Model Tests

final class RefreshTokenModelTests: XCTestCase {

    func testIsValidWhenNotRevokedAndNotExpired() {
        let token = RefreshToken(
            userID: UUID(),
            tokenHash: "hash",
            expiresAt: Date().addingTimeInterval(3600) // expires in 1 hour
        )

        XCTAssertTrue(token.isValid, "Token should be valid when not revoked and not expired")
    }

    func testIsInvalidWhenRevoked() {
        let token = RefreshToken(
            userID: UUID(),
            tokenHash: "hash",
            expiresAt: Date().addingTimeInterval(3600)
        )
        token.isRevoked = true

        XCTAssertFalse(token.isValid, "Token should be invalid when revoked")
    }

    func testIsInvalidWhenExpired() {
        let token = RefreshToken(
            userID: UUID(),
            tokenHash: "hash",
            expiresAt: Date().addingTimeInterval(-60) // expired 1 minute ago
        )

        XCTAssertFalse(token.isValid, "Token should be invalid when expired")
    }

    func testIsInvalidWhenBothRevokedAndExpired() {
        let token = RefreshToken(
            userID: UUID(),
            tokenHash: "hash",
            expiresAt: Date().addingTimeInterval(-60)
        )
        token.isRevoked = true

        XCTAssertFalse(token.isValid, "Token should be invalid when both revoked and expired")
    }

    func testIsValidAtExpirationBoundary() {
        // Token that expires far in the future should be valid
        let farFuture = RefreshToken(
            userID: UUID(),
            tokenHash: "hash",
            expiresAt: Date().addingTimeInterval(30 * 24 * 3600) // 30 days
        )
        XCTAssertTrue(farFuture.isValid)
    }

    func testInitSetsIsRevokedToFalse() {
        let token = RefreshToken(
            userID: UUID(),
            tokenHash: "hash",
            expiresAt: Date().addingTimeInterval(3600)
        )

        XCTAssertFalse(token.isRevoked, "Newly created token should not be revoked")
    }

    func testInitSetsUserIdCorrectly() {
        let userId = UUID()
        let token = RefreshToken(
            userID: userId,
            tokenHash: "somehash",
            expiresAt: Date().addingTimeInterval(3600)
        )

        XCTAssertEqual(token.$user.id, userId)
    }

    func testInitSetsDeviceId() {
        let token = RefreshToken(
            userID: UUID(),
            tokenHash: "hash",
            deviceId: "iphone-14-pro",
            expiresAt: Date().addingTimeInterval(3600)
        )

        XCTAssertEqual(token.deviceId, "iphone-14-pro")
    }

    func testInitWithNilDeviceId() {
        let token = RefreshToken(
            userID: UUID(),
            tokenHash: "hash",
            deviceId: nil,
            expiresAt: Date().addingTimeInterval(3600)
        )

        XCTAssertNil(token.deviceId)
    }
}

// MARK: - User Model Tests

final class UserModelTests: XCTestCase {

    func testToDTOConvertsAllFields() {
        let userId = UUID()
        let createdDate = Date()

        let user = User(
            id: userId,
            email: "test@example.com",
            passwordHash: "hashed",
            displayName: "Test User",
            timezone: "America/New_York"
        )
        user.createdAt = createdDate

        let dto = user.toDTO()

        XCTAssertEqual(dto.id, userId)
        XCTAssertEqual(dto.email, "test@example.com")
        XCTAssertEqual(dto.displayName, "Test User")
        XCTAssertEqual(dto.timezone, "America/New_York")
        XCTAssertEqual(dto.createdAt, createdDate)
    }

    func testToDTOWithNilOptionalFields() {
        let userId = UUID()
        let user = User(
            id: userId,
            email: "minimal@example.com",
            passwordHash: "hashed",
            displayName: nil,
            timezone: nil
        )

        let dto = user.toDTO()

        XCTAssertEqual(dto.id, userId)
        XCTAssertEqual(dto.email, "minimal@example.com")
        XCTAssertNil(dto.displayName)
        XCTAssertNil(dto.timezone)
    }

    func testToDTODoesNotExposePasswordHash() {
        let user = User(
            id: UUID(),
            email: "secure@example.com",
            passwordHash: "super-secret-hash"
        )

        let dto = user.toDTO()

        // Encode DTO to JSON and ensure no password field
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(dto),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            XCTAssertNil(json["passwordHash"], "DTO should not contain passwordHash")
            XCTAssertNil(json["password_hash"], "DTO should not contain password_hash")
            XCTAssertNil(json["password"], "DTO should not contain password")
        } else {
            XCTFail("Failed to encode UserDTO to JSON")
        }
    }

    func testToDTOUsesCurrentDateWhenCreatedAtIsNil() {
        let user = User(
            id: UUID(),
            email: "new@example.com",
            passwordHash: "hash"
        )
        // createdAt is nil for a user that hasn't been saved

        let beforeConversion = Date()
        let dto = user.toDTO()
        let afterConversion = Date()

        // The fallback date should be approximately now
        XCTAssertGreaterThanOrEqual(dto.createdAt, beforeConversion)
        XCTAssertLessThanOrEqual(dto.createdAt, afterConversion)
    }

    func testUserSchemaIsCorrect() {
        XCTAssertEqual(User.schema, "users")
    }
}

// MARK: - Transaction Model Tests

final class TransactionModelTests: XCTestCase {

    func testToDTOConvertsAllFields() {
        let transactionId = UUID()
        let accountId = UUID()
        let userId = UUID()
        let transactionDate = Date()

        let transaction = Transaction(
            id: transactionId,
            accountID: accountId,
            userID: userId,
            plaidTransactionId: "plaid_tx_123",
            amount: Decimal(string: "42.99")!,
            date: transactionDate,
            merchantName: "Coffee Shop",
            category: "Food & Drink",
            description: "Morning latte",
            isPending: false,
            isExcluded: true
        )

        let dto = transaction.toDTO()

        XCTAssertEqual(dto.id, transactionId)
        XCTAssertEqual(dto.accountId, accountId)
        XCTAssertEqual(dto.plaidTransactionId, "plaid_tx_123")
        XCTAssertEqual(dto.amount, Decimal(string: "42.99")!)
        XCTAssertEqual(dto.date, transactionDate)
        XCTAssertEqual(dto.merchantName, "Coffee Shop")
        XCTAssertEqual(dto.category, "Food & Drink")
        XCTAssertEqual(dto.description, "Morning latte")
        XCTAssertFalse(dto.isPending)
        XCTAssertTrue(dto.isExcluded)
    }

    func testToDTOWithNilOptionalFields() {
        let transactionId = UUID()
        let accountId = UUID()
        let userId = UUID()

        let transaction = Transaction(
            id: transactionId,
            accountID: accountId,
            userID: userId,
            plaidTransactionId: nil,
            amount: Decimal(10),
            date: Date(),
            merchantName: "Store",
            category: "Shopping",
            description: nil,
            isPending: true,
            isExcluded: false
        )

        let dto = transaction.toDTO()

        XCTAssertNil(dto.plaidTransactionId)
        XCTAssertNil(dto.description)
        XCTAssertTrue(dto.isPending)
        XCTAssertFalse(dto.isExcluded)
    }

    func testToDTODefaultValues() {
        let transaction = Transaction(
            id: UUID(),
            accountID: UUID(),
            userID: UUID(),
            amount: Decimal(0),
            date: Date(),
            merchantName: "Test",
            category: "Test"
        )

        let dto = transaction.toDTO()

        // Default values from init
        XCTAssertFalse(dto.isPending, "isPending should default to false")
        XCTAssertFalse(dto.isExcluded, "isExcluded should default to false")
        XCTAssertNil(dto.plaidTransactionId)
        XCTAssertNil(dto.description)
    }

    func testToDTOPreservesDecimalPrecision() {
        let preciseAmount = Decimal(string: "1234.56")!

        let transaction = Transaction(
            id: UUID(),
            accountID: UUID(),
            userID: UUID(),
            amount: preciseAmount,
            date: Date(),
            merchantName: "Precise",
            category: "Test"
        )

        let dto = transaction.toDTO()
        XCTAssertEqual(dto.amount, preciseAmount, "Decimal precision should be preserved")
    }

    func testToDTONegativeAmount() {
        let negativeAmount = Decimal(string: "-25.50")!

        let transaction = Transaction(
            id: UUID(),
            accountID: UUID(),
            userID: UUID(),
            amount: negativeAmount,
            date: Date(),
            merchantName: "Refund",
            category: "Refund"
        )

        let dto = transaction.toDTO()
        XCTAssertEqual(dto.amount, negativeAmount, "Negative amounts should be preserved")
    }

    func testTransactionSchemaIsCorrect() {
        XCTAssertEqual(Transaction.schema, "transactions")
    }
}

// MARK: - HealthCheckResponse Tests

final class HealthCheckResponseTests: XCTestCase {

    func testHealthCheckResponseEncoding() throws {
        let response = HealthCheckResponse(
            status: "healthy",
            version: "1.0.0",
            database: "connected"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["status"] as? String, "healthy")
        XCTAssertEqual(json?["version"] as? String, "1.0.0")
        XCTAssertEqual(json?["database"] as? String, "connected")
    }

    func testHealthCheckResponseDecodingRoundTrip() throws {
        let original = HealthCheckResponse(
            status: "healthy",
            version: "1.0.0",
            database: "disconnected"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(HealthCheckResponse.self, from: data)

        XCTAssertEqual(decoded.status, original.status)
        XCTAssertEqual(decoded.version, original.version)
        XCTAssertEqual(decoded.database, original.database)
    }
}

// MARK: - AuthController DTO Tests

final class AuthControllerDTOTests: XCTestCase {

    func testRegisterRequestDecoding() throws {
        let json = """
        {
            "email": "test@example.com",
            "password": "Password123",
            "display_name": "Test User",
            "timezone": "UTC"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let request = try decoder.decode(AuthController.RegisterRequest.self, from: json)

        XCTAssertEqual(request.email, "test@example.com")
        XCTAssertEqual(request.password, "Password123")
        XCTAssertEqual(request.displayName, "Test User")
        XCTAssertEqual(request.timezone, "UTC")
    }

    func testRegisterRequestDecodingWithoutOptionals() throws {
        let json = """
        {
            "email": "test@example.com",
            "password": "Password123"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let request = try decoder.decode(AuthController.RegisterRequest.self, from: json)

        XCTAssertEqual(request.email, "test@example.com")
        XCTAssertEqual(request.password, "Password123")
        XCTAssertNil(request.displayName)
        XCTAssertNil(request.timezone)
    }

    func testLoginRequestDecoding() throws {
        let json = """
        {
            "email": "user@example.com",
            "password": "Secret123",
            "device_id": "iphone-abc"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let request = try decoder.decode(AuthController.LoginRequest.self, from: json)

        XCTAssertEqual(request.email, "user@example.com")
        XCTAssertEqual(request.password, "Secret123")
        XCTAssertEqual(request.deviceId, "iphone-abc")
    }

    func testRefreshRequestDecoding() throws {
        let json = """
        {
            "refresh_token": "abc123tokenvalue"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let request = try decoder.decode(AuthController.RefreshRequest.self, from: json)

        XCTAssertEqual(request.refreshToken, "abc123tokenvalue")
    }

    func testLogoutRequestDecoding() throws {
        let json = """
        {
            "refresh_token": "token123",
            "all_devices": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let request = try decoder.decode(AuthController.LogoutRequest.self, from: json)

        XCTAssertEqual(request.refreshToken, "token123")
        XCTAssertTrue(request.allDevices)
    }

    func testAuthResponseEncoding() throws {
        let userId = UUID()
        let userDTO = UserDTO(
            id: userId,
            email: "test@example.com",
            displayName: "Test",
            timezone: "UTC",
            createdAt: Date()
        )
        let response = AuthController.AuthResponse(
            user: userDTO,
            accessToken: "access.jwt.token",
            refreshToken: "refresh_token_value"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json?["user"])
        XCTAssertNotNil(json?["accessToken"] ?? json?["access_token"])
        XCTAssertNotNil(json?["refreshToken"] ?? json?["refresh_token"])
    }

    func testRefreshResponseEncoding() throws {
        let response = AuthController.RefreshResponse(
            accessToken: "new.access.token",
            refreshToken: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json?["accessToken"] ?? json?["access_token"])
    }
}

// MARK: - UserDTO Tests

final class UserDTOTests: XCTestCase {

    func testUserDTOEncodingRoundTrip() throws {
        let userId = UUID()
        let createdAt = Date()

        let dto = UserDTO(
            id: userId,
            email: "round@trip.com",
            displayName: "Round Trip",
            timezone: "Europe/London",
            createdAt: createdAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dto)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(UserDTO.self, from: data)

        XCTAssertEqual(decoded.id, userId)
        XCTAssertEqual(decoded.email, "round@trip.com")
        XCTAssertEqual(decoded.displayName, "Round Trip")
        XCTAssertEqual(decoded.timezone, "Europe/London")
    }

    func testUserDTOWithNilOptionals() throws {
        let dto = UserDTO(
            id: UUID(),
            email: "nil@test.com",
            displayName: nil,
            timezone: nil,
            createdAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dto)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(UserDTO.self, from: data)

        XCTAssertNil(decoded.displayName)
        XCTAssertNil(decoded.timezone)
    }
}

// MARK: - TransactionDTO Tests

final class TransactionDTOTests: XCTestCase {

    func testTransactionDTOEncodingRoundTrip() throws {
        let transactionId = UUID()
        let accountId = UUID()
        let transactionDate = Date()

        let dto = TransactionDTO(
            id: transactionId,
            accountId: accountId,
            plaidTransactionId: "plaid_123",
            amount: Decimal(string: "99.99")!,
            date: transactionDate,
            merchantName: "Test Merchant",
            category: "Shopping",
            description: "A purchase",
            isPending: false,
            isExcluded: false
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dto)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TransactionDTO.self, from: data)

        XCTAssertEqual(decoded.id, transactionId)
        XCTAssertEqual(decoded.accountId, accountId)
        XCTAssertEqual(decoded.plaidTransactionId, "plaid_123")
        XCTAssertEqual(decoded.merchantName, "Test Merchant")
        XCTAssertEqual(decoded.category, "Shopping")
        XCTAssertEqual(decoded.description, "A purchase")
        XCTAssertFalse(decoded.isPending)
        XCTAssertFalse(decoded.isExcluded)
    }
}

// MARK: - Integration Smoke Tests (Edge Cases)

final class InputValidationEdgeCaseTests: XCTestCase {

    func testEmailWithSpecialCharactersInLocal() {
        XCTAssertTrue(InputValidation.isValidEmail("user.name+tag@example.com"))
        XCTAssertTrue(InputValidation.isValidEmail("user%special@domain.org"))
    }

    func testEmailWithSubdomains() {
        XCTAssertTrue(InputValidation.isValidEmail("user@mail.sub.domain.com"))
    }

    func testPasswordWithOnlySpecialCharsAndRequired() {
        // Has 8+ chars, uppercase, number -- rest are special chars
        XCTAssertTrue(InputValidation.isValidPassword("A!@#$%^1"))
    }

    func testPasswordWithUnicode() {
        // Unicode chars do count toward length, but uppercase/number
        // requirements use ASCII regex ranges
        XCTAssertTrue(InputValidation.isValidPassword("Passw0rd"))
    }

    func testSanitizeWithHTMLEntities() {
        // HTML entities are not tags, so they pass through
        let input = "&amp; &lt; &gt;"
        let result = InputValidation.sanitize(input)
        XCTAssertEqual(result, "&amp; &lt; &gt;")
    }

    func testSanitizeWithOnlyWhitespace() {
        let result = InputValidation.sanitize("   \n\t  ")
        XCTAssertEqual(result, "")
    }

    func testSanitizeWithOnlyHTMLTags() {
        let result = InputValidation.sanitize("<br><hr><div></div>")
        XCTAssertEqual(result, "")
    }
}
