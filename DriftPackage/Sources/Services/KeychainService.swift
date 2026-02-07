import Foundation
import Security

/// Service for secure storage of sensitive data in the Keychain
public actor KeychainService {
    public static let shared = KeychainService()

    private let service = "com.drift.app"

    private init() {}

    // MARK: - Token Keys

    public enum Key: String {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case deviceId = "device_id"
        case userProfile = "user_profile"
    }

    // MARK: - Public Interface

    /// Save a string value to the keychain
    public func save(_ value: String, for key: Key) throws {
        let data = Data(value.utf8)
        try save(data, for: key.rawValue)
    }

    /// Retrieve a string value from the keychain
    public func get(_ key: Key) throws -> String? {
        guard let data = try getData(key.rawValue) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Save raw data to the keychain
    public func saveData(_ data: Data, for key: Key) throws {
        try save(data, for: key.rawValue)
    }

    /// Retrieve raw data from the keychain
    public func getData(_ key: Key) throws -> Data? {
        try getData(key.rawValue)
    }

    /// Delete a value from the keychain
    public func delete(_ key: Key) throws {
        try delete(key.rawValue)
    }

    /// Delete all stored values
    public func deleteAll() throws {
        for key in [Key.accessToken, Key.refreshToken, Key.deviceId, Key.userProfile] {
            try? delete(key)
        }
    }

    // MARK: - Private Implementation

    private func save(_ data: Data, for key: String) throws {
        // Delete existing item first
        try? delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private func getData(_ key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.readFailed(status)
        }
    }

    private func delete(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Errors

public enum KeychainError: Error, LocalizedError {
    case saveFailed(OSStatus)
    case readFailed(OSStatus)
    case deleteFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .readFailed(let status):
            return "Failed to read from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        }
    }
}

// MARK: - Device ID Generation

extension KeychainService {
    /// Get or create a unique device identifier
    public func getOrCreateDeviceId() async throws -> String {
        if let existing = try get(.deviceId) {
            return existing
        }

        let deviceId = UUID().uuidString
        try save(deviceId, for: .deviceId)
        return deviceId
    }
}
