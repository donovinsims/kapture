import Foundation
import Combine

/// Manages Notion OAuth authentication and token management.
/// Provides secure token storage, OAuth flow handling, and authentication state management.
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated: Bool = false
    @Published var authenticationError: AuthError?
    @Published var workspaceName: String?
    
    private let keychain: KeychainManager
    private let apiClient: NotionAPIClient
    
    private init() {
        self.keychain = KeychainManager.shared
        self.apiClient = NotionAPIClient.shared
        self.isAuthenticated = keychain.exists(.notionAccessToken)
    }
    
    /// Checks current authentication status
    func checkAuthenticationStatus() async {
        isAuthenticated = keychain.exists(.notionAccessToken)
    }
    
    /// Starts the OAuth flow by generating the authorization URL
    /// - Returns: URL for OAuth authorization
    /// - Throws: AuthError if configuration is invalid
    func startOAuthFlow() async throws -> URL {
        guard let clientId = Config.notionClientId,
              let redirectURI = Config.notionRedirectURI else {
            throw AuthError.invalidConfiguration
        }
        
        return await apiClient.buildOAuthURL(
            clientId: clientId,
            redirectURI: redirectURI
        )
    }
    
    /// Handles the OAuth callback URL and exchanges code for token
    /// - Parameter url: The callback URL from Notion OAuth
    /// - Throws: AuthError if authentication fails
    func handleOAuthCallback(_ url: URL) async throws {
        guard let code = extractCode(from: url) else {
            throw AuthError.invalidCallback
        }
        
        guard let clientId = Config.notionClientId,
              let clientSecret = Config.notionClientSecret,
              let redirectURI = Config.notionRedirectURI else {
            throw AuthError.invalidConfiguration
        }
        
        let tokenResponse = try await apiClient.exchangeCodeForToken(
            code: code,
            clientId: clientId,
            clientSecret: clientSecret,
            redirectURI: redirectURI
        )
        
        // Store tokens securely
        try keychain.store(tokenResponse.accessToken, for: .notionAccessToken)
        if let refreshToken = tokenResponse.refreshToken {
            try keychain.store(refreshToken, for: .notionRefreshToken)
        }
        
        workspaceName = tokenResponse.workspaceName
        isAuthenticated = true
        authenticationError = nil
    }
    
    /// Retrieves a valid access token, refreshing if necessary
    /// - Returns: Valid access token string
    /// - Throws: AuthError if token cannot be retrieved
    func getValidToken() async throws -> String {
        guard keychain.exists(.notionAccessToken) else {
            throw AuthError.notAuthenticated
        }
        
        do {
            return try keychain.retrieve(.notionAccessToken)
        } catch {
            // Token might be expired, try refresh
            if keychain.exists(.notionRefreshToken) {
                try await refreshToken()
                return try keychain.retrieve(.notionAccessToken)
            }
            throw AuthError.notAuthenticated
        }
    }
    
    /// Refreshes the access token using the refresh token
    /// - Throws: AuthError if refresh fails
    func refreshToken() async throws {
        guard let refreshToken = try? keychain.retrieve(.notionRefreshToken) else {
            throw AuthError.notAuthenticated
        }
        
        // Note: Notion API doesn't currently support refresh tokens
        // This is a placeholder for future implementation
        // For now, user will need to re-authenticate
        throw AuthError.refreshNotSupported
    }
    
    /// Signs out the user by clearing stored tokens
    func signOut() {
        try? keychain.delete(.notionAccessToken)
        try? keychain.delete(.notionRefreshToken)
        isAuthenticated = false
        workspaceName = nil
    }
    
    /// Extracts the authorization code from OAuth callback URL
    /// - Parameter url: The callback URL
    /// - Returns: Authorization code if present
    private func extractCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        return queryItems.first(where: { $0.name == "code" })?.value
    }
}

/// Authentication errors that can occur during the OAuth flow.
enum AuthError: Error, LocalizedError {
    case invalidConfiguration
    case invalidCallback
    case notAuthenticated
    case tokenExchangeFailed
    case refreshNotSupported
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Invalid Notion OAuth configuration. Please check your client ID and redirect URI."
        case .invalidCallback:
            return "Invalid OAuth callback URL"
        case .notAuthenticated:
            return "Not authenticated with Notion"
        case .tokenExchangeFailed:
            return "Failed to exchange authorization code for token"
        case .refreshNotSupported:
            return "Token refresh not supported. Please re-authenticate."
        }
    }
}

/// App configuration loaded from Info.plist.
/// Note: In production, consider using secure storage for sensitive values.
struct Config {
    static var notionClientId: String? {
        Bundle.main.object(forInfoDictionaryKey: "NOTION_CLIENT_ID") as? String
    }
    
    static var notionClientSecret: String? {
        Bundle.main.object(forInfoDictionaryKey: "NOTION_CLIENT_SECRET") as? String
    }
    
    static var notionRedirectURI: String? {
        Bundle.main.object(forInfoDictionaryKey: "NOTION_REDIRECT_URI") as? String
    }
}

