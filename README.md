# Kapture - Fast Notion Capture

A fast, modern iOS-native app for capturing information to Notion databases with sub-second performance.

## Features

- ⚡ Lightning fast capture (< 2 seconds)
- 🔐 Secure OAuth authentication
- 📊 Full database support (all property types)
- 📱 iOS Widget integration
- 🔄 Offline-first with automatic sync
- 🎯 Smart database routing

## Project Structure

```
Kapture/
├── Kapture/
│   ├── App/
│   │   └── KaptureApp.swift
│   ├── Services/
│   │   ├── AuthService.swift
│   │   └── NotionAPIClient.swift
│   ├── Views/
│   │   ├── Authentication/
│   │   │   ├── WelcomeView.swift
│   │   │   └── NotionAuthView.swift
│   │   └── Capture/
│   │       └── CaptureView.swift
│   ├── Models/
│   │   └── Notion/
│   │       └── NotionDatabase.swift
│   └── Utilities/
│       └── KeychainManager.swift
```

## Setup Instructions

### Prerequisites

- Xcode 15+ (with iOS 17+ SDK)
- Swift 5.9+
- Apple Developer Account (for App Store distribution)
- Notion OAuth Integration credentials

### Configuration

1. **Create Notion OAuth Integration:**
   - Go to https://www.notion.so/my-integrations
   - Create a new integration
   - Note your `Client ID` and `Client Secret`
   - Set redirect URI (e.g., `kapture://oauth/callback`)

2. **Configure Info.plist:**
   Add the following keys to your `Info.plist`:
   ```xml
   <key>NOTION_CLIENT_ID</key>
   <string>your-client-id</string>
   <key>NOTION_CLIENT_SECRET</key>
   <string>your-client-secret</string>
   <key>NOTION_REDIRECT_URI</key>
   <string>kapture://oauth/callback</string>
   ```

3. **Configure URL Scheme:**
   Add URL scheme to your app target:
   - Scheme: `kapture`
   - Used for OAuth callback handling

4. **Build and Run:**
   ```bash
   # Open in Xcode
   open Kapture.xcodeproj
   
   # Build and run (⌘R)
   ```

## Development Workflow

See `.cursorrules` for the complete agent workflow. Key points:

1. **Read AGENT_CHAT.md** before starting work
2. **Claim work** with your agent tag
3. **Follow verification lock protocol** before running tests
4. **Mark completion** with `<feature-complete>` tag

## Testing

Unit tests are located in `KaptureTests/` and cover:
- **AuthService**: OAuth flow, token extraction, authentication state
- **SyncService**: Retry logic, error handling
- **CaptureViewModel**: Property management, error handling
- **PropertyValue**: Notion format conversion for all property types
- **CapturedEntry**: Data encoding/decoding, model initialization

### Running Tests

For full test execution, use Xcode:
```bash
# In Xcode: Product > Test (⌘U)
# Or via command line:
xcodebuild test -scheme Kapture -destination 'platform=iOS Simulator,name=iPhone 15'
```

The verification script (`bun run verify`) provides a summary of test coverage.

## Continuous Code Review with CodeRabbit

CodeRabbit is configured to automatically review every pull request and provide:
- **Code Quality Checks**: Force unwraps, memory leaks, retain cycles, async/await misuse
- **Security Analysis**: Hardcoded secrets, unsafe API usage, keychain misuse
- **Swift Best Practices**: Actor isolation, error handling, performance optimization
- **Inline Comments**: Suggestions directly on code changes

### Setup CodeRabbit

1. **Install CodeRabbit GitHub App:**
   - Go to https://github.com/apps/coderabbitai
   - Click "Install" and select your repository
   - Grant permissions for PR reviews

2. **Configuration:**
   - CodeRabbit uses `.coderabbit.yaml` for settings
   - GitHub Actions workflow (`.github/workflows/coderabbit-review.yml`) runs on every PR
   - Reviews Swift files automatically

3. **Manual Review (Optional):**
   ```bash
   # Review specific files
   coderabbit review --files "Kapture/**/*.swift"
   ```

CodeRabbit runs automatically on pull requests and provides feedback before code is merged.

## Agent Modules

- **notion-auth**: Authentication & API client ✅
- **capture-ui**: Main capture interface
- **database-management**: Database discovery & selection
- **property-inputs**: Property type inputs
- **offline-sync**: Offline storage & sync
- **widgets**: iOS widget integration
- **smart-routing**: Intelligent database suggestions

## Architecture

- **Pattern**: MVVM with Combine
- **UI**: SwiftUI
- **Storage**: SwiftData (local), Keychain (tokens)
- **Networking**: URLSession with async/await
- **Widgets**: WidgetKit (iOS 18+)

## License

[To be determined]

## Contributing

See `AGENT_CHAT.md` for coordination between agents. Follow the workflow in `.cursorrules`.
