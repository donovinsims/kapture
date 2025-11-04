import Foundation
import Security

/// Manages secure storage of sensitive data using iOS Keychain.
/// Provides methods for storing, retrieving, and deleting tokens securely.
class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.kapture.notion"
    
    private init() {}
    
    /// Stores a token securely in the Keychain
    /// - Parameters:
    ///   - token: The token string to store
    ///   - key: The keychain key identifier
    /// - Throws: KeychainError if storage fails
    func store(_ token: String, for key: KeychainKey) throws {
        guard let tokenData = token.data(using: .utf8) else {
            throw KeychainError.storeFailed(errSecInvalidData)
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: tokenData
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    /// Retrieves a token from the Keychain
    /// - Parameter key: The keychain key identifier
    /// - Returns: The stored token string
    /// - Throws: KeychainError if retrieval fails
    func retrieve(_ key: KeychainKey) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.notFound
        }
        
        return token
    }
    
    /// Deletes a token from the Keychain
    /// - Parameter key: The keychain key identifier
    /// - Throws: KeychainError if deletion fails
    func delete(_ key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    /// Checks if a token exists in the Keychain
    /// - Parameter key: The keychain key identifier
    /// - Returns: True if token exists, false otherwise
    func exists(_ key: KeychainKey) -> Bool {
        do {
            _ = try retrieve(key)
            return true
        } catch {
            return false
        }
    }
}

/// Keychain key identifiers for different token types.
enum KeychainKey: String {
    case notionAccessToken
    case notionRefreshToken
}

/// Errors that can occur during Keychain operations.
enum KeychainError: Error, LocalizedError {
    case storeFailed(OSStatus)
    case notFound
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .storeFailed(let status):
            return "Failed to store token in Keychain. Status: \(status)"
        case .notFound:
            return "Token not found in Keychain"
        case .deleteFailed(let status):
            return "Failed to delete token from Keychain. Status: \(status)"
        }
    }
}

