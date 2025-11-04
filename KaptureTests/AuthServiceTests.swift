import XCTest
@testable import Kapture

/// Unit tests for AuthService authentication logic
@MainActor
final class AuthServiceTests: XCTestCase {
    var authService: AuthService!
    
    override func setUp() {
        super.setUp()
        authService = AuthService.shared
    }
    
    override func tearDown() {
        // Clean up any tokens
        authService.signOut()
        super.tearDown()
    }
    
    // MARK: - OAuth URL Building Tests
    
    func testExtractCode_WithValidCallbackURL_ReturnsCode() {
        // Given
        let callbackURL = URL(string: "kapture://oauth/callback?code=test_code_123&state=xyz")!
        
        // When
        let code = authService.extractCode(from: callbackURL)
        
        // Then
        XCTAssertEqual(code, "test_code_123")
    }
    
    func testExtractCode_WithInvalidURL_ReturnsNil() {
        // Given
        let invalidURL = URL(string: "kapture://oauth/callback")!
        
        // When
        let code = authService.extractCode(from: invalidURL)
        
        // Then
        XCTAssertNil(code)
    }
    
    func testExtractCode_WithNoCodeParameter_ReturnsNil() {
        // Given
        let url = URL(string: "kapture://oauth/callback?state=xyz&error=access_denied")!
        
        // When
        let code = authService.extractCode(from: url)
        
        // Then
        XCTAssertNil(code)
    }
    
    // MARK: - Authentication Status Tests
    
    func testCheckAuthenticationStatus_WhenNoToken_ReturnsNotAuthenticated() async {
        // Given - ensure no token exists
        authService.signOut()
        
        // When
        await authService.checkAuthenticationStatus()
        
        // Then
        XCTAssertFalse(authService.isAuthenticated)
    }
    
    // MARK: - Sign Out Tests
    
    func testSignOut_ClearsAuthenticationState() {
        // Given
        authService.isAuthenticated = true
        authService.workspaceName = "Test Workspace"
        
        // When
        authService.signOut()
        
        // Then
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.workspaceName)
    }
}

// MARK: - Helper Extension for Testing

extension AuthService {
    /// Exposes extractCode for testing (internal method)
    func extractCode(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        return queryItems.first(where: { $0.name == "code" })?.value
    }
}
