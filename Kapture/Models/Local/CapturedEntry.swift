import Foundation

#if canImport(SwiftData)
import SwiftData

/// Local model for captured entries before sync
@Model
final class CapturedEntry {
    var id: UUID
    var notionDatabaseId: String
    var notionDatabaseName: String
    var properties: Data // JSON encoded property values
    var createdAt: Date
    var syncedAt: Date?
    var syncStatus: SyncStatus
    var syncError: String?
    var retryCount: Int

    init(
        id: UUID = UUID(),
        notionDatabaseId: String,
        notionDatabaseName: String,
        properties: [String: Any],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.notionDatabaseId = notionDatabaseId
        self.notionDatabaseName = notionDatabaseName
        // Encode properties - if encoding fails, use empty data
        // This should rarely happen with valid dictionary data
        self.properties = (try? JSONSerialization.data(withJSONObject: properties)) ?? Data()
        self.createdAt = createdAt
        self.syncStatus = .pending
        self.retryCount = 0
    }

    /// Decodes properties from Data
    func decodeProperties() throws -> [String: Any] {
        guard let json = try? JSONSerialization.jsonObject(with: properties) as? [String: Any] else {
            throw StorageError.invalidData
        }
        return json
    }

    /// Encodes properties to Data
    func encodeProperties(_ properties: [String: Any]) throws {
        self.properties = try JSONSerialization.data(withJSONObject: properties)
    }
}

/// User preferences for databases
@Model
final class DatabasePreference {
    var databaseId: String
    var isFavorite: Bool
    var lastUsedAt: Date
    var usageCount: Int
    var preferredCaptureTime: DateComponents? // e.g., 9:00 AM

    init(databaseId: String) {
        self.databaseId = databaseId
        self.isFavorite = false
        self.lastUsedAt = Date()
        self.usageCount = 0
    }

    func recordUsage() {
        lastUsedAt = Date()
        usageCount += 1
    }
}

/// Sync queue item for tracking sync operations
@Model
final class SyncQueueItem {
    var entryId: UUID
    var queuedAt: Date
    var attemptCount: Int
    var nextRetryAt: Date?
    var errorMessage: String?

    init(entryId: UUID) {
        self.entryId = entryId
        self.queuedAt = Date()
        self.attemptCount = 0
    }

    func incrementAttempt() {
        attemptCount += 1
        // Exponential backoff: 2^attemptCount minutes
        let delayMinutes = pow(2.0, Double(attemptCount))
        nextRetryAt = Date().addingTimeInterval(delayMinutes * 60)
    }
}

#else

/// Local model for captured entries before sync
final class CapturedEntry {
    var id: UUID
    var notionDatabaseId: String
    var notionDatabaseName: String
    var properties: Data // JSON encoded property values
    var createdAt: Date
    var syncedAt: Date?
    var syncStatus: SyncStatus
    var syncError: String?
    var retryCount: Int

    init(
        id: UUID = UUID(),
        notionDatabaseId: String,
        notionDatabaseName: String,
        properties: [String: Any],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.notionDatabaseId = notionDatabaseId
        self.notionDatabaseName = notionDatabaseName
        self.properties = (try? JSONSerialization.data(withJSONObject: properties)) ?? Data()
        self.createdAt = createdAt
        self.syncStatus = .pending
        self.retryCount = 0
    }

    /// Decodes properties from Data
    func decodeProperties() throws -> [String: Any] {
        guard let json = try? JSONSerialization.jsonObject(with: properties) as? [String: Any] else {
            throw StorageError.invalidData
        }
        return json
    }

    /// Encodes properties to Data
    func encodeProperties(_ properties: [String: Any]) throws {
        self.properties = try JSONSerialization.data(withJSONObject: properties)
    }
}

/// User preferences for databases
final class DatabasePreference {
    var databaseId: String
    var isFavorite: Bool
    var lastUsedAt: Date
    var usageCount: Int
    var preferredCaptureTime: DateComponents? // e.g., 9:00 AM

    init(databaseId: String) {
        self.databaseId = databaseId
        self.isFavorite = false
        self.lastUsedAt = Date()
        self.usageCount = 0
    }

    func recordUsage() {
        lastUsedAt = Date()
        usageCount += 1
    }
}

/// Sync queue item for tracking sync operations
final class SyncQueueItem {
    var entryId: UUID
    var queuedAt: Date
    var attemptCount: Int
    var nextRetryAt: Date?
    var errorMessage: String?

    init(entryId: UUID) {
        self.entryId = entryId
        self.queuedAt = Date()
        self.attemptCount = 0
    }

    func incrementAttempt() {
        attemptCount += 1
        // Exponential backoff: 2^attemptCount minutes
        let delayMinutes = pow(2.0, Double(attemptCount))
        nextRetryAt = Date().addingTimeInterval(delayMinutes * 60)
    }
}

#endif

enum SyncStatus: String, Codable {
    case pending
    case syncing
    case synced
    case failed
    case conflict
}

enum StorageError: Error, LocalizedError {
    case invalidData
    case saveFailed
    case fetchFailed

    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data format"
        case .saveFailed:
            return "Failed to save data"
        case .fetchFailed:
            return "Failed to fetch data"
        }
    }
}
