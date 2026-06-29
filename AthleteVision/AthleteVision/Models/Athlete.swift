import Foundation
import SwiftData

@Model
final class Athlete {
    var id: UUID
    var name: String
    var sport: String
    var position: String
    var birthDate: Date?
    var profileNote: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var sessions: [VideoSession]

    init(name: String, sport: String, position: String = "", profileNote: String = "") {
        self.id = UUID()
        self.name = name
        self.sport = sport
        self.position = position
        self.profileNote = profileNote
        self.createdAt = Date()
        self.sessions = []
    }

    var initials: String {
        let words = name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1)) + String(words[1].prefix(1))
        }
        return String(name.prefix(2))
    }
}
