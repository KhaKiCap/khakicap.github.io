import Foundation

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
        let words = name.components(separatedBy: " ")
        if words.count >= 2,
           let first = words.first?.first,
           let second = words[1].first {
            return String(first) + String(second)
        }
        return String(name.prefix(2))
    }
}
