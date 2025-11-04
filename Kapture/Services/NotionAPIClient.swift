import Foundation

/// Client for communicating with the Notion API.
/// Handles all HTTP requests to Notion's REST API with proper authentication and error handling.
actor NotionAPIClient {
    static let shared = NotionAPIClient()
    
    private let baseURL = "https://api.notion.com/v1"
    private let notionVersion = "2022-06-28"
    
    private init() {}
    
    // Access MainActor-isolated AuthService.shared on-demand
    private func getTokenManager() async -> AuthService {
        await MainActor.run { AuthService.shared }
    }
    
    /// Fetches all accessible databases from Notion
    /// - Returns: Array of NotionDatabase objects
    /// - Throws: NotionAPIError if request fails
    func fetchDatabases() async throws -> [NotionDatabase] {
        // Development bypass: return empty array if no auth
        let tokenManager = await getTokenManager()
        let isAuthenticated = await MainActor.run { tokenManager.isAuthenticated }
        guard isAuthenticated else {
            print("⚠️ Auth bypass: Returning empty databases list")
            return []
        }
        
        let token = try await tokenManager.getValidToken()
        
        guard let url = URL(string: "\(baseURL)/search") else {
            throw NotionAPIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "filter": [
                "property": "object",
                "value": "database"
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotionAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NotionAPIError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(NotionSearchResponse.self, from: data)
        
        return result.results.compactMap { NotionDatabase.from($0) }
    }
    
    /// Creates a new page in a Notion database
    /// - Parameters:
    ///   - databaseId: The ID of the database
    ///   - properties: Dictionary of property values
    /// - Returns: Created NotionPage object
    /// - Throws: NotionAPIError if request fails
    func createPage(databaseId: String, properties: [String: Any]) async throws -> NotionPage {
        // Development bypass: return mock page if no auth
        let tokenManager = await getTokenManager()
        let isAuthenticated = await MainActor.run { tokenManager.isAuthenticated }
        guard isAuthenticated else {
            print("⚠️ Auth bypass: Returning mock NotionPage")
            // Return a mock page
            return NotionPage(
                id: UUID().uuidString,
                url: "https://notion.so/mock-page",
                createdTime: Date(),
                lastEditedTime: Date()
            )
        }
        
        let token = try await tokenManager.getValidToken()
        
        guard let url = URL(string: "\(baseURL)/pages") else {
            throw NotionAPIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "parent": [
                "database_id": databaseId
            ],
            "properties": properties
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotionAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NotionAPIError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(NotionPage.self, from: data)
    }
    
    /// Fetches the schema for a specific database
    /// - Parameter databaseId: The ID of the database
    /// - Returns: DatabaseSchema object
    /// - Throws: NotionAPIError if request fails
    func fetchDatabaseSchema(_ databaseId: String) async throws -> DatabaseSchema {
        // Development bypass: return mock schema if no auth
        let tokenManager = await getTokenManager()
        let isAuthenticated = await MainActor.run { tokenManager.isAuthenticated }
        guard isAuthenticated else {
            print("⚠️ Auth bypass: Returning mock database schema")
            // Return a basic mock schema
            let mockDatabase = NotionDatabase(
                id: databaseId,
                title: "Mock Database",
                icon: nil,
                url: "https://notion.so/mock",
                createdTime: nil,
                lastEditedTime: nil,
                properties: [:],
                parent: nil
            )
            return DatabaseSchema(database: mockDatabase)
        }
        
        let token = try await tokenManager.getValidToken()
        
        guard let url = URL(string: "\(baseURL)/databases/\(databaseId)") else {
            throw NotionAPIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(notionVersion, forHTTPHeaderField: "Notion-Version")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotionAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NotionAPIError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let database = try decoder.decode(NotionDatabase.self, from: data)
        
        return DatabaseSchema(database: database)
    }
    
    /// Builds the OAuth authorization URL
    /// - Parameters:
    ///   - clientId: Notion OAuth client ID
    ///   - redirectURI: Redirect URI for OAuth callback
    /// - Returns: URL for OAuth authorization
    func buildOAuthURL(clientId: String, redirectURI: String) -> URL {
        guard var components = URLComponents(string: "https://api.notion.com/v1/oauth/authorize") else {
            // This should never fail with a valid URL string
            preconditionFailure("Invalid OAuth base URL")
        }
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "owner", value: "user")
        ]
        
        guard let url = components.url else {
            preconditionFailure("Failed to build OAuth URL")
        }
        
        return url
    }
    
    /// Exchanges authorization code for access token
    /// - Parameters:
    ///   - code: Authorization code from OAuth callback
    ///   - clientId: Notion OAuth client ID
    ///   - clientSecret: Notion OAuth client secret
    ///   - redirectURI: Redirect URI used in OAuth flow
    /// - Returns: OAuthTokenResponse with access and refresh tokens
    /// - Throws: NotionAPIError if exchange fails
    func exchangeCodeForToken(code: String, clientId: String, clientSecret: String, redirectURI: String) async throws -> OAuthTokenResponse {
        guard let url = URL(string: "https://api.notion.com/v1/oauth/token") else {
            throw NotionAPIError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = bodyData
        
        let authString = "\(clientId):\(clientSecret)"
        guard let authData = authString.data(using: .utf8) else {
            throw NotionAPIError.invalidResponse
        }
        
        let base64Auth = authData.base64EncodedString()
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NotionAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NotionAPIError.requestFailed(httpResponse.statusCode, errorMessage)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(OAuthTokenResponse.self, from: data)
    }
}

/// Errors that can occur when communicating with the Notion API.
enum NotionAPIError: Error, LocalizedError {
    case invalidResponse
    case requestFailed(Int, String)
    case invalidToken
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Notion API"
        case .requestFailed(let statusCode, let message):
            return "Notion API request failed with status \(statusCode): \(message)"
        case .invalidToken:
            return "Invalid or expired Notion access token"
        case .rateLimitExceeded:
            return "Notion API rate limit exceeded"
        }
    }
}

/// Response from Notion search API
struct NotionSearchResponse: Codable {
    let results: [NotionDatabaseRaw]
}

/// OAuth token response
struct OAuthTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let refreshToken: String?
    let botId: String?
    let workspaceName: String?
    let workspaceIcon: String?
    let workspaceId: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case botId = "bot_id"
        case workspaceName = "workspace_name"
        case workspaceIcon = "workspace_icon"
        case workspaceId = "workspace_id"
    }
}

/// Wrapper for database schema information.
struct DatabaseSchema {
    let database: NotionDatabase
    // Additional schema details can be added here as needed
}

