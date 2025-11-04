import Foundation
import Combine

/// ViewModel for managing database list state
@MainActor
class DatabaseListViewModel: ObservableObject {
    @Published var databases: [NotionDatabase] = []
    @Published var recentDatabases: [NotionDatabase] = []
    @Published var favoriteDatabases: [NotionDatabase] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var searchText: String = ""
    
    private let repository: DatabaseRepository
    
    init(repository: DatabaseRepository = .shared) {
        self.repository = repository
    }
    
    /// Loads databases from Notion API
    func loadDatabases() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedDatabases = try await repository.getDatabases()
            databases = fetchedDatabases
            await updateRecentDatabases()
            await updateFavoriteDatabases()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Refreshes databases from API
    func refreshDatabases() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedDatabases = try await repository.getDatabases(forceRefresh: true)
            databases = fetchedDatabases
            await updateRecentDatabases()
            await updateFavoriteDatabases()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Filters databases based on search text
    var filteredDatabases: [NotionDatabase] {
        if searchText.isEmpty {
            return databases
        }
        
        return databases.filter { database in
            database.title.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    /// Marks a database as recently used
    func markAsRecent(_ database: NotionDatabase) async {
        // This will use DatabasePreference model when offline-sync is ready
        // For now, just update the recent list
        if !recentDatabases.contains(where: { $0.id == database.id }) {
            recentDatabases.insert(database, at: 0)
            if recentDatabases.count > 10 {
                recentDatabases.removeLast()
            }
        }
    }
    
    /// Toggles favorite status for a database
    func toggleFavorite(_ database: NotionDatabase) async {
        // This will use DatabasePreference model when offline-sync is ready
        if let index = favoriteDatabases.firstIndex(where: { $0.id == database.id }) {
            favoriteDatabases.remove(at: index)
        } else {
            favoriteDatabases.append(database)
        }
    }
    
    /// Checks if a database is favorited
    func isFavorite(_ database: NotionDatabase) -> Bool {
        favoriteDatabases.contains(where: { $0.id == database.id })
    }
    
    private func updateRecentDatabases() async {
        // Will be implemented with DatabasePreference model
        // For now, keep empty
    }
    
    private func updateFavoriteDatabases() async {
        // Will be implemented with DatabasePreference model
        // For now, keep empty
    }
}

