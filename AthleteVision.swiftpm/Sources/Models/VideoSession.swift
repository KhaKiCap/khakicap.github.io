import Foundation

struct VideoSession: Codable, Identifiable {
    var id: UUID
    var title: String
    var recordedAt: Date
    var videoFilename: String
    var duration: Double
    var notes: String
    var feedbackItems: [FeedbackItem]

    init(title: String, videoFilename: String, duration: Double = 0, notes: String = "") {
        id = UUID()
        self.title = title
        recordedAt = Date()
        self.videoFilename = videoFilename
        self.duration = duration
        self.notes = notes
        feedbackItems = []
    }

    func videoURL() -> URL? {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = base.appendingPathComponent("videos").appendingPathComponent(videoFilename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    var formattedDuration: String {
        guard duration > 0 else { return "--:--" }
        return String(format: "%d:%02d", Int(duration) / 60, Int(duration) % 60)
    }
}
