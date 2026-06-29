import Foundation

// MARK: - Athlete

struct Athlete: Codable, Identifiable {
    var id: UUID
    var name: String
    var sport: String
    var position: String
    var profileNote: String
    var createdAt: Date
    var sessions: [VideoSession]

    init(name: String, sport: String, position: String = "", profileNote: String = "") {
        id = UUID()
        self.name = name
        self.sport = sport
        self.position = position
        self.profileNote = profileNote
        createdAt = Date()
        sessions = []
    }

    var initials: String {
        let parts = name.components(separatedBy: " ")
        if parts.count >= 2,
           let a = parts[0].first,
           let b = parts[1].first {
            return String(a) + String(b)
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - VideoSession

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
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("videos")
            .appendingPathComponent(videoFilename)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    var formattedDuration: String {
        guard duration > 0 else { return "--:--" }
        return String(format: "%d:%02d", Int(duration) / 60, Int(duration) % 60)
    }
}

// MARK: - FeedbackItem

struct FeedbackItem: Codable, Identifiable {
    var id: UUID
    var timestamp: Double
    var text: String
    var categoryRaw: String
    var createdAt: Date

    init(timestamp: Double, text: String, category: FeedbackCategory = .general) {
        id = UUID()
        self.timestamp = timestamp
        self.text = text
        categoryRaw = category.rawValue
        createdAt = Date()
    }

    var category: FeedbackCategory {
        FeedbackCategory(rawValue: categoryRaw) ?? .general
    }

    var formattedTimestamp: String {
        String(format: "%d:%02d", Int(timestamp) / 60, Int(timestamp) % 60)
    }
}

enum FeedbackCategory: String, Codable, CaseIterable {
    case general = "일반"
    case positive = "잘함"
    case improvement = "개선"
    case technique = "기술"

    var systemImage: String {
        switch self {
        case .general:     return "bubble.left.fill"
        case .positive:    return "star.fill"
        case .improvement: return "arrow.up.circle.fill"
        case .technique:   return "figure.run"
        }
    }

    var color: Color {
        switch self {
        case .general:     return .gray
        case .positive:    return .yellow
        case .improvement: return .blue
        case .technique:   return .green
        }
    }
}

// MARK: - Helpers

import SwiftUI

extension Color {}  // keeps SwiftUI import scoped here
