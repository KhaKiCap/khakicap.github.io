import Foundation
import SwiftData

@Model
final class FeedbackItem {
    var id: UUID
    var timestamp: Double
    var text: String
    var categoryRaw: String
    var createdAt: Date

    var session: VideoSession?

    init(timestamp: Double, text: String, category: FeedbackCategory = .general) {
        self.id = UUID()
        self.timestamp = timestamp
        self.text = text
        self.categoryRaw = category.rawValue
        self.createdAt = Date()
    }

    var category: FeedbackCategory {
        get { FeedbackCategory(rawValue: categoryRaw) ?? .general }
        set { categoryRaw = newValue.rawValue }
    }

    var formattedTimestamp: String {
        let minutes = Int(timestamp) / 60
        let seconds = Int(timestamp) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

enum FeedbackCategory: String, CaseIterable {
    case general = "일반"
    case positive = "잘함"
    case improvement = "개선"
    case technique = "기술"

    var systemImage: String {
        switch self {
        case .general: return "bubble.left.fill"
        case .positive: return "star.fill"
        case .improvement: return "arrow.up.circle.fill"
        case .technique: return "figure.run"
        }
    }

    var color: String {
        switch self {
        case .general: return "gray"
        case .positive: return "yellow"
        case .improvement: return "blue"
        case .technique: return "green"
        }
    }
}
