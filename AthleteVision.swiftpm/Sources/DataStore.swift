import Foundation
import Combine

final class DataStore: ObservableObject {
    @Published var athletes: [Athlete] = []

    private var dataFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("athletes.json")
    }

    var videosDirectoryURL: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("videos", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    init() { load() }

    func save() {
        guard let data = try? JSONEncoder().encode(athletes) else { return }
        try? data.write(to: dataFileURL, options: .atomic)
    }

    private func load() {
        guard let data = try? Data(contentsOf: dataFileURL),
              let decoded = try? JSONDecoder().decode([Athlete].self, from: data) else { return }
        athletes = decoded
    }

    // MARK: - Athletes

    func addAthlete(name: String, sport: String, position: String = "", note: String = "") {
        athletes.append(Athlete(name: name, sport: sport, position: position, profileNote: note))
        save()
    }

    func updateAthlete(_ updated: Athlete) {
        guard let idx = athletes.firstIndex(where: { $0.id == updated.id }) else { return }
        athletes[idx] = updated
        save()
    }

    func deleteAthlete(id: UUID) {
        athletes.removeAll { $0.id == id }
        save()
    }

    func athlete(id: UUID) -> Athlete? {
        athletes.first { $0.id == id }
    }

    // MARK: - Sessions

    func addSession(_ session: VideoSession, athleteId: UUID) {
        guard let idx = athletes.firstIndex(where: { $0.id == athleteId }) else { return }
        athletes[idx].sessions.insert(session, at: 0)
        save()
    }

    func deleteSession(id: UUID, athleteId: UUID) {
        guard let aIdx = athletes.firstIndex(where: { $0.id == athleteId }) else { return }
        if let session = athletes[aIdx].sessions.first(where: { $0.id == id }) {
            let videoURL = videosDirectoryURL.appendingPathComponent(session.videoFilename)
            try? FileManager.default.removeItem(at: videoURL)
        }
        athletes[aIdx].sessions.removeAll { $0.id == id }
        save()
    }

    func session(id: UUID, athleteId: UUID) -> VideoSession? {
        athletes.first { $0.id == athleteId }?.sessions.first { $0.id == id }
    }

    // MARK: - Feedback

    func addFeedback(_ item: FeedbackItem, sessionId: UUID, athleteId: UUID) {
        guard let aIdx = athletes.firstIndex(where: { $0.id == athleteId }),
              let sIdx = athletes[aIdx].sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        athletes[aIdx].sessions[sIdx].feedbackItems.append(item)
        athletes[aIdx].sessions[sIdx].feedbackItems.sort { $0.timestamp < $1.timestamp }
        save()
    }

    func deleteFeedback(id: UUID, sessionId: UUID, athleteId: UUID) {
        guard let aIdx = athletes.firstIndex(where: { $0.id == athleteId }),
              let sIdx = athletes[aIdx].sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        athletes[aIdx].sessions[sIdx].feedbackItems.removeAll { $0.id == id }
        save()
    }
}
