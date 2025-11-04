import SwiftData
import Foundation

/// Service for managing local storage using SwiftData.
/// Provides CRUD operations for captured entries and database preferences.
actor StorageService {
    static let shared = StorageService()
    
    private var modelContainer: ModelContainer?
    
    private init() {}
    
    /// Configures the SwiftData model container
    func configure() throws {
        let schema = Schema([
            CapturedEntry.self,
            DatabasePreference.self,
            SyncQueueItem.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
    
    /// Gets the model context
    func getContext() throws -> ModelContext {
        guard let container = modelContainer else {
            throw StorageError.invalidData
        }
        return ModelContext(container)
    }
    
    /// Saves a captured entry locally
    func saveEntry(_ entry: CapturedEntry) throws {
        let context = try getContext()
        context.insert(entry)
        try context.save()
    }
    
    /// Fetches all pending entries
    func fetchPendingEntries() throws -> [CapturedEntry] {
        let context = try getContext()
        let pendingStatusRaw = SyncStatus.pending.rawValue
        let descriptor = FetchDescriptor<CapturedEntry>(
            predicate: #Predicate<CapturedEntry> { entry in
                entry.syncStatus.rawValue == pendingStatusRaw
            }
        )
        return try context.fetch(descriptor)
    }
    
    /// Fetches entries that need retry
    func fetchEntriesForRetry() throws -> [CapturedEntry] {
        let context = try getContext()
        let failedStatusRaw = SyncStatus.failed.rawValue
        let maxRetries = 3
        let descriptor = FetchDescriptor<CapturedEntry>(
            predicate: #Predicate<CapturedEntry> { entry in
                entry.syncStatus.rawValue == failedStatusRaw &&
                entry.retryCount < maxRetries
            }
        )
        return try context.fetch(descriptor)
    }
    
    /// Marks an entry as synced
    func markAsSynced(_ entryId: UUID) throws {
        let context = try getContext()
        let entryIdString = entryId.uuidString
        let descriptor = FetchDescriptor<CapturedEntry>(
            predicate: #Predicate<CapturedEntry> { entry in
                entry.id.uuidString == entryIdString
            }
        )
        
        if let entry = try context.fetch(descriptor).first {
            entry.syncStatus = .synced
            entry.syncedAt = Date()
            try context.save()
        }
    }
    
    /// Marks an entry as failed
    func markAsFailed(_ entryId: UUID, error: Error) throws {
        let context = try getContext()
        let entryIdString = entryId.uuidString
        let descriptor = FetchDescriptor<CapturedEntry>(
            predicate: #Predicate<CapturedEntry> { entry in
                entry.id.uuidString == entryIdString
            }
        )
        
        if let entry = try context.fetch(descriptor).first {
            entry.syncStatus = .failed
            entry.syncError = error.localizedDescription
            entry.retryCount += 1
            try context.save()
        }
    }
    
    /// Updates retry count without changing sync status (for retryable failures)
    func updateRetryCount(_ entryId: UUID, retryCount: Int, error: Error) throws {
        let context = try getContext()
        let entryIdString = entryId.uuidString
        let descriptor = FetchDescriptor<CapturedEntry>(
            predicate: #Predicate<CapturedEntry> { entry in
                entry.id.uuidString == entryIdString
            }
        )
        
        if let entry = try context.fetch(descriptor).first {
            entry.retryCount = retryCount
            entry.syncError = error.localizedDescription
            // Keep status as pending so it can be retried
            try context.save()
        }
    }
    
    /// Gets or creates a database preference
    func getDatabasePreference(databaseId: String) throws -> DatabasePreference {
        let context = try getContext()
        let descriptor = FetchDescriptor<DatabasePreference>(
            predicate: #Predicate<DatabasePreference> { preference in
                preference.databaseId == databaseId
            }
        )
        
        if let preference = try context.fetch(descriptor).first {
            return preference
        }
        
        let preference = DatabasePreference(databaseId: databaseId)
        context.insert(preference)
        try context.save()
        return preference
    }
    
    /// Records database usage
    func recordDatabaseUsage(databaseId: String) throws {
        let preference = try getDatabasePreference(databaseId: databaseId)
        preference.recordUsage()
        try getContext().save()
    }
    
    /// Gets most recently used databases
    func getRecentDatabases(limit: Int = 10) throws -> [DatabasePreference] {
        let context = try getContext()
        var descriptor = FetchDescriptor<DatabasePreference>()
        descriptor.sortBy = [SortDescriptor(\.lastUsedAt, order: .reverse)]
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }
    
    /// Gets favorite databases
    func getFavoriteDatabases() throws -> [DatabasePreference] {
        let context = try getContext()
        let descriptor = FetchDescriptor<DatabasePreference>(
            predicate: #Predicate<DatabasePreference> { preference in
                preference.isFavorite == true
            }
        )
        return try context.fetch(descriptor)
    }
}

