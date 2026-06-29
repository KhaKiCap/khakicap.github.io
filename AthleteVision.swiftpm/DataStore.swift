import Foundation
import SwiftUI

final class DataStore: ObservableObject {
    @Published var athletes: [Athlete] = []

    private var saveURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("athletes.json")
    }

    var videosDir: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("videos")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    init() { load() }

    func save() {
        guard let data = try? JSONEncoder().encode(athletes) else { return }
        try? data.write(to: saveURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([Athlete].self, from: data) else { return }
        athletes = decoded
    }

    func addAthlete(name: String, sport: String, position: String, note: String) {
        athletes.append(Athlete(name: name, sport: sport, position: position, profileNote: note))
        save()
    }

    func updateAthlete(_ updated: Athlete) {
        guard let i = athletes.firstIndex(where: { $0.id == updated.id }) else { return }
        athletes[i] = updated
        save()
    }

    func deleteAthlete(id: UUID) {
        athletes.removeAll { $0.id == id }
        save()
    }

    func athlete(id: UUID) -> Athlete? {
        athletes.first { $0.id == id }
    }

    func addSession(_ session: VideoSession, athleteId: UUID) {
        guard let i = athletes.firstIndex(where: { $0.id == athleteId }) else { return }
        athletes[i].sessions.insert(session, at: 0)
        save()
    }

    func deleteSession(id: UUID, athleteId: UUID) {
        guard let ai = athletes.firstIndex(where: { $0.id == athleteId }) else { return }
        if let s = athletes[ai].sessions.first(where: { $0.id == id }) {
            try? FileManager.default.removeItem(at: videosDir.appendingPathComponent(s.videoFilename))
        }
        athletes[ai].sessions.removeAll { $0.id == id }
        save()
    }

    func session(id: UUID, athleteId: UUID) -> VideoSession? {
        athletes.first { $0.id == athleteId }?.sessions.first { $0.id == id }
    }

    func addFeedback(_ item: FeedbackItem, sessionId: UUID, athleteId: UUID) {
        guard let ai = athletes.firstIndex(where: { $0.id == athleteId }),
              let si = athletes[ai].sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        athletes[ai].sessions[si].feedbackItems.append(item)
        athletes[ai].sessions[si].feedbackItems.sort { $0.timestamp < $1.timestamp }
        save()
    }

    func deleteFeedback(id: UUID, sessionId: UUID, athleteId: UUID) {
        guard let ai = athletes.firstIndex(where: { $0.id == athleteId }),
              let si = athletes[ai].sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        athletes[ai].sessions[si].feedbackItems.removeAll { $0.id == id }
        save()
    }
}
