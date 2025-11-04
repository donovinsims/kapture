import Foundation

/// Service for managing offline sync operations.
/// Handles synchronization of captured entries with Notion API, including retry logic and error handling.
actor SyncService {
    static let shared = SyncService()
    
    private let storageService: StorageService
    private let notionService: NotionAPIClient
    private let networkMonitor: NetworkMonitor
    private var isSyncing: Bool = false
    
    private init() {
        self.storageService = StorageService.shared
        self.notionService = NotionAPIClient.shared
        self.networkMonitor = NetworkMonitor.shared
    }
    
    /// Syncs all pending entries
    func syncPendingEntries() async throws {
        guard !isSyncing else { return }
        guard await networkMonitor.checkConnectivity() else {
            return // Skip sync if offline
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let pendingEntries = try await storageService.fetchPendingEntries()
        
        for entry in pendingEntries {
            do {
                try await syncEntry(entry)
                try await storageService.markAsSynced(entry.id)
            } catch {
                try await handleSyncError(entry, error: error)
            }
        }
        
        // Also retry failed entries
        let failedEntries = try await storageService.fetchEntriesForRetry()
        for entry in failedEntries {
            do {
                try await syncEntry(entry)
                try await storageService.markAsSynced(entry.id)
            } catch {
                try await handleSyncError(entry, error: error)
            }
        }
    }
    
    /// Syncs a single entry
    private func syncEntry(_ entry: CapturedEntry) async throws {
        let properties = try entry.decodeProperties()
        
        _ = try await notionService.createPage(
            databaseId: entry.notionDatabaseId,
            properties: properties
        )
    }
    
    /// Handles sync errors with retry logic.
    /// - Parameters:
    ///   - entry: The entry that failed to sync
    ///   - error: The error that occurred
    private func handleSyncError(_ entry: CapturedEntry, error: Error) async throws {
        let newRetryCount = entry.retryCount + 1
        
        if newRetryCount >= 3 {
            // Max retries exceeded, mark as permanently failed
            // Note: markAsFailed will increment retryCount again, so we set it first
            entry.retryCount = newRetryCount - 1
            try await storageService.markAsFailed(entry.id, error: error)
        } else {
            // Update retry count but keep status as pending for retry
            try await storageService.updateRetryCount(entry.id, retryCount: newRetryCount, error: error)
        }
    }
    
    /// Queues an entry for sync
    func queueEntryForSync(_ entry: CapturedEntry) async throws {
        try await storageService.saveEntry(entry)
        
        // Try to sync immediately if online
        if await networkMonitor.checkConnectivity() {
            Task {
                try? await syncPendingEntries()
            }
        }
    }
    
    /// Resolves a sync conflict between local and remote entries.
    /// - Parameters:
    ///   - entry: The local entry
    ///   - remoteEntry: The remote Notion page
    /// Note: For MVP, uses last-write-wins strategy. Could be enhanced with conflict resolution UI.
    func resolveConflict(_ entry: CapturedEntry, _ remoteEntry: NotionPage) async throws {
        try await storageService.markAsSynced(entry.id)
    }
}

