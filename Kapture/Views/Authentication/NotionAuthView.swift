import SwiftUI
import SafariServices

/// OAuth authentication view for Notion
struct NotionAuthView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var isPresentingSafari = false
    @State private var authURL: URL?
    @State private var authError: AuthError?
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding(.top, 60)
                    
                    Text("Connecting to Notion...")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                } else {
                    // Instructions
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Connect Your Notion Workspace")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("Kapture uses Notion's secure OAuth to access your workspace. You'll be redirected to Notion to authorize access.")
                            .font(.system(size: 17))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Connect Button
                    Button(action: {
                        print("🔵 Authorize with Notion button tapped")
                        Task {
                            await connectToNotion()
                        }
                    }) {
                        Text("Authorize with Notion")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Connect Notion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isPresentingSafari) {
                if let url = authURL {
                    SafariView(url: url)
                }
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
    
    private func connectToNotion() async {
        print("🔐 connectToNotion() called")
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("🔐 Calling authService.startOAuthFlow()...")
            let url = try await authService.startOAuthFlow()
            print("✅ OAuth URL received: \(url)")
            await MainActor.run {
                authURL = url
                isPresentingSafari = true
                print("✅ authURL set, Safari should open")
            }
        } catch {
            print("❌ Error in connectToNotion: \(error.localizedDescription)")
            await MainActor.run {
                if let authErr = error as? AuthError {
                    authError = authErr
                } else {
                    authError = .invalidConfiguration
                }
            }
        }
    }
}

/// Safari view wrapper for OAuth flow
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let safari = SFSafariViewController(url: url)
        safari.delegate = context.coordinator
        return safari
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, SFSafariViewControllerDelegate {
        let parent: SafariView
        
        init(_ parent: SafariView) {
            self.parent = parent
        }
        
        func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
            // OAuth callback will be handled via URL scheme in AppDelegate
        }
        
        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NotionAuthView()
}
