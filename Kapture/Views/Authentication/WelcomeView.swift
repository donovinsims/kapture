import SwiftUI

/// Welcome screen shown to unauthenticated users
struct WelcomeView: View {
    @StateObject private var authService = AuthService.shared
    @State private var isPresentingAuth = false
    @State private var authError: AuthError?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // App Icon/Logo
                Image(systemName: "bolt.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.top, 60)
                
                // Title
                VStack(spacing: 8) {
                    Text("Welcome to Kapture")
                        .font(.system(size: 34, weight: .bold))
                    
                    Text("Fast Notion Capture")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "bolt.fill",
                        title: "Lightning Fast",
                        description: "Capture entries in under 2 seconds"
                    )
                    
                    FeatureRow(
                        icon: "database.fill",
                        title: "Full Database Support",
                        description: "All property types and inline databases"
                    )
                    
                    FeatureRow(
                        icon: "wifi.slash",
                        title: "Works Offline",
                        description: "Capture anywhere, sync automatically"
                    )
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Connect Button
                Button(action: {
                    isPresentingAuth = true
                }) {
                    HStack {
                        Text("Connect Notion")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .sheet(isPresented: $isPresentingAuth) {
                NotionAuthView()
            }
            .alert("Authentication Error", isPresented: Binding(
                get: { authError != nil },
                set: { if !$0 { authError = nil } }
            )) {
                Button("OK") {
                    authError = nil
                }
            } message: {
                if let error = authError {
                    Text(error.localizedDescription)
                }
            }
        }
    }
}

/// Feature row component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    WelcomeView()
}

