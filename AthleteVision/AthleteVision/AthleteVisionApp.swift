import SwiftUI
import SwiftData

@main
struct AthleteVisionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Athlete.self, VideoSession.self, FeedbackItem.self])
    }
}
