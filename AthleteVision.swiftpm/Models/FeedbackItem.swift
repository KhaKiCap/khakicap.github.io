import Foundation

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
        case .general: return "bubble.left.fill"
        case .positive: return "star.fill"
        case .improvement: return "arrow.up.circle.fill"
        case .technique: return "figure.run"
        }
    }
}
