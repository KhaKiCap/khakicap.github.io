import SwiftUI

struct AthleteDetailView: View {
    let athleteId: UUID
    @Environment(DataStore.self) private var store
    @State private var showingVideoImport = false
    @State private var showingEdit = false

    var athlete: Athlete? { store.athlete(id: athleteId) }

    var body: some View {
        Group {
            if let athlete {
                List {
                    Section {
                        headerView(athlete)
                    }

                    if !athlete.profileNote.isEmpty {
                        Section("메모") {
                            Text(athlete.profileNote).foregroundStyle(.secondary)
                        }
                    }

                    Section("촬영 영상 (\(athlete.sessions.count))") {
                        if athlete.sessions.isEmpty {
                            ContentUnavailableView(
                                "영상 없음",
                                systemImage: "video.slash",
                                description: Text("우측 상단 버튼으로 영상을 추가하세요")
                            )
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(athlete.sessions) { session in
                                NavigationLink(
                                    destination: VideoPlayerView(athleteId: athleteId, sessionId: session.id)
                                ) {
                                    SessionRowView(session: session)
                                }
                            }
                            .onDelete { offsets in
                                offsets.forEach {
                                    store.deleteSession(id: athlete.sessions[$0].id, athleteId: athleteId)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(athlete.name)
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button { showingEdit = true } label: {
                                Image(systemName: "pencil")
                            }
                            Button { showingVideoImport = true } label: {
                                Image(systemName: "video.badge.plus")
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingVideoImport) {
                    VideoImportView(athleteId: athleteId, athleteName: athlete.name)
                }
                .sheet(isPresented: $showingEdit) {
                    EditAthleteView(athlete: athlete)
                }
            } else {
                ContentUnavailableView("선수를 찾을 수 없습니다", systemImage: "person.slash")
            }
        }
    }

    private func headerView(_ athlete: Athlete) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 72, height: 72)
                Text(athlete.initials)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(athlete.name).font(.title2.bold())
                HStack {
                    Label(athlete.sport, systemImage: "figure.run")
                        .font(.subheadline).foregroundStyle(.secondary)
                    if !athlete.position.isEmpty {
                        Text("· \(athlete.position)")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Text("등록: \(athlete.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct EditAthleteView: View {
    let athlete: Athlete
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var sport: String
    @State private var position: String
    @State private var note: String

    init(athlete: Athlete) {
        self.athlete = athlete
        _name = State(initialValue: athlete.name)
        _sport = State(initialValue: athlete.sport)
        _position = State(initialValue: athlete.position)
        _note = State(initialValue: athlete.profileNote)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("이름", text: $name)
                    TextField("종목", text: $sport)
                    TextField("포지션", text: $position)
                }
                Section("메모") {
                    TextField("메모", text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }
            }
            .navigationTitle("선수 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        var updated = athlete
                        updated.name = name
                        updated.sport = sport
                        updated.position = position
                        updated.profileNote = note
                        store.updateAthlete(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SessionRowView: View {
    let session: VideoSession

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 44)
                Image(systemName: "play.rectangle.fill")
                    .font(.title2).foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title).font(.subheadline.bold()).lineLimit(1)
                HStack(spacing: 8) {
                    Label(session.formattedDuration, systemImage: "clock")
                        .font(.caption).foregroundStyle(.secondary)
                    Label("\(session.feedbackItems.count)개 피드백", systemImage: "bubble.left")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(session.recordedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}
