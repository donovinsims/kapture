# Kapture Runtime Readiness Report

This report lists the configuration tasks and technical blockers that currently prevent the Kapture app from running end-to-end, along with forward-looking risks to track as development continues.

## Immediate blockers

- **Populate Notion OAuth credentials.** The production Info.plist still ships with placeholder strings for `NOTION_CLIENT_ID`, `NOTION_CLIENT_SECRET`, and the redirect URI. Without real values, the OAuth flow will fail before it even starts.【F:Kapture/Info.plist†L31-L39】
- **Disable the development authentication bypass.** `ContentView` forces the `bypassAuth` flag to `true`, which skips the entire OAuth flow. That is useful for UI prototyping but prevents real users from authenticating once credentials are supplied.【F:Kapture/App/KaptureApp.swift†L44-L63】
- **SwiftData must be initialised before use.** `StorageService` throws `StorageError.invalidData` unless `configure()` successfully builds a `ModelContainer`, yet the app currently fires `configure()` in a detached `Task` at launch and ignores any failure. On slower devices the capture flow can race this setup and crash. Callers should await `configure()` and surface failures to the user during startup.【F:Kapture/App/KaptureApp.swift†L23-L41】【F:Kapture/Services/StorageService.swift†L12-L38】
- **Real Notion data is gated behind authentication.** `NotionAPIClient` returns empty or mock payloads whenever the user is not authenticated. Until the bypass is removed and valid tokens are issued, the capture screen cannot load real databases or push captured entries to Notion.【F:Kapture/Services/NotionAPIClient.swift†L17-L78】【F:Kapture/Services/NotionAPIClient.swift†L96-L144】

## Near-term risks

- **Token refresh is unimplemented.** `AuthService.refreshToken()` immediately throws `AuthError.refreshNotSupported`, so long-lived sessions will expire and force a full re-login once Notion enables refresh tokens. A real refresh implementation (or UX to guide re-auth) is required before shipping.【F:Kapture/Services/AuthService.swift†L73-L109】
- **Background storage requires iOS 17 SwiftData.** All offline storage types rely on the SwiftData `@Model` macro and predicates, tying the app to iOS 17+. If an iOS 16 fallback is needed, introduce a Core Data or SQLite backend now to avoid a large migration later.【F:Kapture/Models/Local/CapturedEntry.swift†L1-L74】【F:Kapture/Services/StorageService.swift†L1-L119】
- **Network monitoring depends on NWPathMonitor.** The current implementation assumes `Network` framework availability. That is fine on-device, but the module is unavailable in Linux-based CI. Any server-side tooling (like SwiftPM tests) must stub or gate this code with conditional compilation.【F:Kapture/Utilities/NetworkMonitor.swift†L1-L22】

## Operational suggestions

1. Gate SwiftUI- and SwiftData-specific files with `#if canImport` checks or split them into an iOS-only module so continuous integration on non-Apple runners can compile auxiliary targets.
2. Surface a dedicated launch screen state while `StorageService.configure()` runs, preventing capture attempts until the data stack is ready.
3. Add smoke tests that verify `Config` loads real credentials and that `AuthService` transitions to the authenticated state after a simulated OAuth callback.

Keeping these items in the backlog will ensure the CodeRabbit automation and human contributors focus on the changes needed to ship a working, production-ready build.
