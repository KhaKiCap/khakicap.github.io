import Foundation
import SwiftData

@Model
final class VideoSession {
    var id: UUID
    var title: String
    var recordedAt: Date
    var videoURLString: String
    var duration: Double
    var notes: String
    var thumbnailData: Data?

    @Relationship(deleteRule: .cascade)
    var feedbackItems: [FeedbackItem]

    var athlete: Athlete?

    init(title: String, videoURL: URL, duration: Double = 0, notes: String = "") {
        self.id = UUID()
        self.title = title
        self.recordedAt = Date()
        self.videoURLString = videoURL.absoluteString
        self.duration = duration
        self.notes = notes
        self.feedbackItems = []
    }

    var videoURL: URL? {
        URL(string: videoURLString)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
