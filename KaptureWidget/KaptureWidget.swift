import WidgetKit
import SwiftUI

/// Main widget configuration
struct KaptureWidget: Widget {
    let kind: String = "KaptureWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: KaptureTimelineProvider()) { entry in
            KaptureWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Capture")
        .description("Capture entries to Notion instantly")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

/// Widget entry model
struct KaptureEntry: TimelineEntry {
    let date: Date
    let recentDatabases: [DatabaseWidgetModel]
}

/// Database model for widget
struct DatabaseWidgetModel: Identifiable {
    let id: String
    let name: String
    let icon: String?
}

/// Timeline provider for widget updates
struct KaptureTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> KaptureEntry {
        KaptureEntry(
            date: Date(),
            recentDatabases: [
                DatabaseWidgetModel(id: "1", name: "Tasks", icon: "📋"),
                DatabaseWidgetModel(id: "2", name: "Notes", icon: "📝")
            ]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (KaptureEntry) -> Void) {
        let entry = KaptureEntry(
            date: Date(),
            recentDatabases: loadRecentDatabases()
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<KaptureEntry>) -> Void) {
        let entry = KaptureEntry(
            date: Date(),
            recentDatabases: loadRecentDatabases()
        )
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadRecentDatabases() -> [DatabaseWidgetModel] {
        // Load from shared UserDefaults or App Group
        // For now, return empty array
        return []
    }
}

/// Widget view
struct KaptureWidgetView: View {
    var entry: KaptureEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

/// Small widget view
struct SmallWidgetView: View {
    var entry: KaptureEntry
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue)
            
            Text("Kapture")
                .font(.system(size: 16, weight: .semibold))
            
            if entry.recentDatabases.isEmpty {
                Text("Tap to capture")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .widgetURL(URL(string: "kapture://capture"))
    }
}

/// Medium widget view
struct MediumWidgetView: View {
    var entry: KaptureEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                Text("Quick Capture")
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
            }
            
            if entry.recentDatabases.isEmpty {
                Text("Tap to capture to Notion")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.recentDatabases.prefix(3)) { database in
                        HStack {
                            if let icon = database.icon {
                                Text(icon)
                                    .font(.system(size: 16))
                            }
                            Text(database.name)
                                .font(.system(size: 14))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        .widgetURL(URL(string: "kapture://capture"))
    }
}

/// Lock screen widget view (iOS 18+)
struct AccessoryRectangularView: View {
    var entry: KaptureEntry
    
    var body: some View {
        HStack {
            Image(systemName: "bolt.fill")
                .font(.system(size: 12))
            Text("Kapture")
                .font(.system(size: 12, weight: .semibold))
            if !entry.recentDatabases.isEmpty {
                Text("•")
                    .foregroundColor(.secondary)
                Text(entry.recentDatabases.first?.name ?? "")
                    .font(.system(size: 12))
                    .lineLimit(1)
            }
        }
        .widgetURL(URL(string: "kapture://capture"))
    }
}

#Preview(as: .systemSmall) {
    KaptureWidget()
} timeline: {
    KaptureEntry(
        date: Date(),
        recentDatabases: [
            DatabaseWidgetModel(id: "1", name: "Tasks", icon: "📋")
        ]
    )
}

