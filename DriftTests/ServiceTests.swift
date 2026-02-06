//
//  ServiceTests.swift
//  DriftTests
//
//  Tests for Services: KeychainService, BiometricService, HapticManager.
//

import XCTest
import UIKit
@testable import Drift
import Services
import Core
import UI

// MARK: - KeychainService Tests

final class KeychainServiceTests: XCTestCase {

    private let keychain = KeychainService.shared

    override func tearDown() async throws {
        // Clean up all test data from keychain after each test
        try? await keychain.deleteAll()
        try await super.tearDown()
    }

    // MARK: - Save and Retrieve

    func testSaveAndRetrieveAccessToken() async throws {
        let testToken = "test-access-token-\(UUID().uuidString)"

        try await keychain.save(testToken, for: .accessToken)
        let retrieved = try await keychain.get(.accessToken)

        XCTAssertEqual(retrieved, testToken)
    }

    func testSaveAndRetrieveRefreshToken() async throws {
        let testToken = "test-refresh-token-\(UUID().uuidString)"

        try await keychain.save(testToken, for: .refreshToken)
        let retrieved = try await keychain.get(.refreshToken)

        XCTAssertEqual(retrieved, testToken)
    }

    func testSaveAndRetrieveDeviceId() async throws {
        let testId = UUID().uuidString

        try await keychain.save(testId, for: .deviceId)
        let retrieved = try await keychain.get(.deviceId)

        XCTAssertEqual(retrieved, testId)
    }

    // MARK: - Overwrite

    func testSaveOverwritesPreviousValue() async throws {
        let firstValue = "first-value"
        let secondValue = "second-value"

        try await keychain.save(firstValue, for: .accessToken)
        try await keychain.save(secondValue, for: .accessToken)

        let retrieved = try await keychain.get(.accessToken)
        XCTAssertEqual(retrieved, secondValue)
    }

    // MARK: - Delete

    func testDeleteRemovesValue() async throws {
        let testToken = "token-to-delete"

        try await keychain.save(testToken, for: .accessToken)
        try await keychain.delete(.accessToken)

        let retrieved = try await keychain.get(.accessToken)
        XCTAssertNil(retrieved)
    }

    func testDeleteNonExistentKeyDoesNotThrow() async throws {
        // Should not throw when deleting a key that does not exist
        try await keychain.delete(.accessToken)
    }

    // MARK: - Delete All

    func testDeleteAllClearsAllKeys() async throws {
        try await keychain.save("token1", for: .accessToken)
        try await keychain.save("token2", for: .refreshToken)
        try await keychain.save("device1", for: .deviceId)

        try await keychain.deleteAll()

        let accessToken = try await keychain.get(.accessToken)
        let refreshToken = try await keychain.get(.refreshToken)
        let deviceId = try await keychain.get(.deviceId)

        XCTAssertNil(accessToken)
        XCTAssertNil(refreshToken)
        XCTAssertNil(deviceId)
    }

    // MARK: - Get Non-Existent Key

    func testGetNonExistentKeyReturnsNil() async throws {
        // Make sure key is cleared
        try await keychain.delete(.accessToken)

        let retrieved = try await keychain.get(.accessToken)
        XCTAssertNil(retrieved)
    }

    // MARK: - Device ID Generation

    func testGetOrCreateDeviceIdCreatesNewId() async throws {
        // Ensure no device ID exists
        try await keychain.delete(.deviceId)

        let deviceId = try await keychain.getOrCreateDeviceId()
        XCTAssertFalse(deviceId.isEmpty)

        // Verify it is a valid UUID
        XCTAssertNotNil(UUID(uuidString: deviceId))
    }

    func testGetOrCreateDeviceIdReturnsExistingId() async throws {
        let existingId = UUID().uuidString
        try await keychain.save(existingId, for: .deviceId)

        let retrievedId = try await keychain.getOrCreateDeviceId()
        XCTAssertEqual(retrievedId, existingId)
    }

    func testGetOrCreateDeviceIdIsIdempotent() async throws {
        // Ensure no device ID exists
        try await keychain.delete(.deviceId)

        let firstId = try await keychain.getOrCreateDeviceId()
        let secondId = try await keychain.getOrCreateDeviceId()

        XCTAssertEqual(firstId, secondId, "Multiple calls should return the same device ID")
    }

    // MARK: - Special Characters

    func testSaveAndRetrieveSpecialCharacters() async throws {
        let specialValue = "token/with+special=chars&more!"

        try await keychain.save(specialValue, for: .accessToken)
        let retrieved = try await keychain.get(.accessToken)

        XCTAssertEqual(retrieved, specialValue)
    }

    func testSaveAndRetrieveEmptyString() async throws {
        let emptyValue = ""

        try await keychain.save(emptyValue, for: .accessToken)
        let retrieved = try await keychain.get(.accessToken)

        XCTAssertEqual(retrieved, emptyValue)
    }

    func testSaveAndRetrieveLongString() async throws {
        let longValue = String(repeating: "a", count: 10_000)

        try await keychain.save(longValue, for: .accessToken)
        let retrieved = try await keychain.get(.accessToken)

        XCTAssertEqual(retrieved, longValue)
    }
}

// MARK: - KeychainError Tests

final class KeychainErrorTests: XCTestCase {

    func testSaveFailedErrorDescription() {
        let error = KeychainError.saveFailed(-25299)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("save"))
        XCTAssertTrue(error.errorDescription!.contains("-25299"))
    }

    func testReadFailedErrorDescription() {
        let error = KeychainError.readFailed(-25300)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("read"))
    }

    func testDeleteFailedErrorDescription() {
        let error = KeychainError.deleteFailed(-25301)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("delete"))
    }
}

// MARK: - BiometricService Tests

@MainActor
final class BiometricServiceTests: XCTestCase {

    // MARK: - BiometricType

    func testBiometricTypeNoneDisplayName() {
        let type = BiometricService.BiometricType.none
        XCTAssertEqual(type.displayName, "Biometrics")
    }

    func testBiometricTypeTouchIDDisplayName() {
        let type = BiometricService.BiometricType.touchID
        XCTAssertEqual(type.displayName, "Touch ID")
    }

    func testBiometricTypeFaceIDDisplayName() {
        let type = BiometricService.BiometricType.faceID
        XCTAssertEqual(type.displayName, "Face ID")
    }

    func testBiometricTypeNoneIconName() {
        let type = BiometricService.BiometricType.none
        XCTAssertEqual(type.iconName, "lock")
    }

    func testBiometricTypeTouchIDIconName() {
        let type = BiometricService.BiometricType.touchID
        XCTAssertEqual(type.iconName, "touchid")
    }

    func testBiometricTypeFaceIDIconName() {
        let type = BiometricService.BiometricType.faceID
        XCTAssertEqual(type.iconName, "faceid")
    }

    // MARK: - Initialization

    func testBiometricServiceInitializes() {
        let service = BiometricService()
        // On simulator, biometrics are typically unavailable
        // Just verify initialization does not crash
        XCTAssertNotNil(service)
    }

    // MARK: - isEnabled preference

    func testIsEnabledDefaultsFalse() {
        // Clear the stored preference
        UserDefaults.standard.removeObject(forKey: "biometricAuthEnabled")

        let service = BiometricService()
        XCTAssertFalse(service.isEnabled)
    }

    func testSetIsEnabled() {
        let service = BiometricService()
        service.isEnabled = true
        XCTAssertTrue(service.isEnabled)

        service.isEnabled = false
        XCTAssertFalse(service.isEnabled)

        // Clean up
        UserDefaults.standard.removeObject(forKey: "biometricAuthEnabled")
    }

    // MARK: - disable()

    func testDisableClearsState() {
        let service = BiometricService()
        service.isEnabled = true

        service.disable()

        XCTAssertFalse(service.isEnabled)
        XCTAssertFalse(service.isAuthenticated)

        // Clean up
        UserDefaults.standard.removeObject(forKey: "biometricAuthEnabled")
    }

    // MARK: - isAvailable

    func testIsAvailableMatchesBiometricType() {
        let service = BiometricService()
        // On simulator, biometric type is typically .none
        if service.biometricType == .none {
            XCTAssertFalse(service.isAvailable)
        } else {
            XCTAssertTrue(service.isAvailable)
        }
    }
}

// MARK: - HapticManager Tests

final class HapticManagerTests: XCTestCase {

    // These tests simply verify that calling HapticManager methods does not crash.
    // Actual haptic feedback cannot be verified in unit tests.

    func testSelectionDoesNotCrash() {
        HapticManager.selection()
    }

    func testImpactDefaultDoesNotCrash() {
        HapticManager.impact()
    }

    func testImpactLightDoesNotCrash() {
        HapticManager.impact(.light)
    }

    func testImpactMediumDoesNotCrash() {
        HapticManager.impact(.medium)
    }

    func testImpactHeavyDoesNotCrash() {
        HapticManager.impact(.heavy)
    }

    func testImpactSoftDoesNotCrash() {
        HapticManager.impact(.soft)
    }

    func testImpactRigidDoesNotCrash() {
        HapticManager.impact(.rigid)
    }

    func testNotificationSuccessDoesNotCrash() {
        HapticManager.notification(.success)
    }

    func testNotificationWarningDoesNotCrash() {
        HapticManager.notification(.warning)
    }

    func testNotificationErrorDoesNotCrash() {
        HapticManager.notification(.error)
    }
}
