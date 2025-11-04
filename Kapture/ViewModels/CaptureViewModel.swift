import Foundation
import Combine

/// ViewModel for managing capture state and operations
@MainActor
class CaptureViewModel: ObservableObject {
    @Published var selectedDatabase: NotionDatabase?
    @Published var propertyValues: [String: PropertyValue] = [:]
    @Published var isCapturing: Bool = false
    @Published var captureError: Error?
    @Published var captureSuccess: Bool = false
    @Published var showDatabaseSelector: Bool = false
    @Published var isLoadingSchema: Bool = false
    
    private let databaseRepository: DatabaseRepository
    private let syncService: SyncService
    private let smartRouter: SmartRouterService
    private let notionAPI: NotionAPIClient
    
    init(
        databaseRepository: DatabaseRepository = .shared,
        syncService: SyncService = .shared,
        smartRouter: SmartRouterService = .shared,
        notionAPI: NotionAPIClient = .shared
    ) {
        self.databaseRepository = databaseRepository
        self.syncService = syncService
        self.smartRouter = smartRouter
        self.notionAPI = notionAPI
    }
    
    /// Loads suggested database from smart router
    func loadSuggestedDatabase() async {
        if let suggested = await smartRouter.suggestDatabase() {
            selectedDatabase = suggested
            await loadSchema()
        }
    }
    
    /// Loads database schema and initializes property values
    func loadSchema() async {
        guard let database = selectedDatabase else { return }
        
        isLoadingSchema = true
        defer { isLoadingSchema = false }
        
        do {
            let schema = try await notionAPI.fetchDatabaseSchema(database.id)
            initializePropertyValues(from: schema.database)
        } catch {
            captureError = error
        }
    }
    
    /// Initializes property values from database schema
    private func initializePropertyValues(from database: NotionDatabase) {
        propertyValues = [:]
        
        guard let properties = database.properties else { return }
        
        for (_, property) in properties {
            if property.type.isEditable {
                propertyValues[property.id] = PropertyValue()
            }
        }
    }
    
    /// Updates a property value
    func updateProperty(_ propertyId: String, value: PropertyValue) {
        propertyValues[propertyId] = value
    }
    
    /// Captures the entry to Notion
    func captureEntry() async throws {
        guard let database = selectedDatabase else {
            throw CaptureError.noDatabaseSelected
        }
        
        isCapturing = true
        captureError = nil
        captureSuccess = false
        
        defer { isCapturing = false }
        
        do {
            // Build properties dictionary for Notion API
            var notionProperties: [String: Any] = [:]
            
            guard let schema = database.properties else {
                throw CaptureError.invalidSchema
            }
            
            for (propertyId, propertyValue) in propertyValues {
                guard let property = schema[propertyId] else { continue }
                let notionFormat = propertyValue.toNotionFormat(for: property)
                if !notionFormat.isEmpty {
                    notionProperties[propertyId] = notionFormat
                }
            }
            
            // Create entry locally first (offline-first)
            let entry = CapturedEntry(
                notionDatabaseId: database.id,
                notionDatabaseName: database.title,
                properties: notionProperties
            )
            
            // Save locally
            try await syncService.queueEntryForSync(entry)
            
            // Record usage for smart routing
            await smartRouter.recordCapture(databaseId: database.id, timestamp: Date())
            
            captureSuccess = true
            
            // Clear form
            propertyValues = [:]
            initializePropertyValues(from: database)
            
        } catch {
            captureError = error
            throw error
        }
    }
    
    /// Selects a database and loads its schema
    func selectDatabase(_ database: NotionDatabase) async {
        selectedDatabase = database
        await loadSchema()
    }
}

enum CaptureError: Error, LocalizedError {
    case noDatabaseSelected
    case invalidSchema
    case captureFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .noDatabaseSelected:
            return "Please select a database first"
        case .invalidSchema:
            return "Invalid database schema"
        case .captureFailed(let error):
            return "Capture failed: \(error.localizedDescription)"
        }
    }
}

