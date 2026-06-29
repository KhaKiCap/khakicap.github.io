import SwiftUI
import SwiftData

struct AthleteDetailView: View {
    @Bindable var athlete: Athlete
    @State private var showingCamera = false
    @State private var isEditingProfile = false

    private var sortedSessions: [VideoSession] {
        athlete.sessions.sorted { $0.recordedAt > $1.recordedAt }
    }

    var body: some View {
        List {
            Section {
                athleteHeaderView
            }

            if !athlete.profileNote.isEmpty {
                Section("메모") {
                    Text(athlete.profileNote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("촬영 영상 (\(athlete.sessions.count))") {
                if sortedSessions.isEmpty {
                    ContentUnavailableView(
                        "영상 없음",
                        systemImage: "video.slash",
                        description: Text("카메라 버튼으로 첫 영상을 촬영하세요")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedSessions) { session in
                        NavigationLink(destination: VideoPlayerView(session: session)) {
                            SessionRowView(session: session)
                        }
                    }
                    .onDelete(perform: deleteSessions)
                }
            }
        }
        .navigationTitle(athlete.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { isEditingProfile = true }) {
                        Image(systemName: "pencil")
                    }
                    Button(action: { showingCamera = true }) {
                        Image(systemName: "video.badge.plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraRecordingView(athlete: athlete)
        }
        .sheet(isPresented: $isEditingProfile) {
            EditAthleteView(athlete: athlete)
        }
    }

    private var athleteHeaderView: some View {
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
                Text(athlete.name)
                    .font(.title2.bold())
                HStack {
                    Label(athlete.sport, systemImage: "figure.run")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !athlete.position.isEmpty {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(athlete.position)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Text("등록일: \(athlete.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 8)
    }

    private func deleteSessions(at offsets: IndexSet) {
        let sorted = sortedSessions
        for index in offsets {
            if let pos = athlete.sessions.firstIndex(where: { $0.id == sorted[index].id }) {
                athlete.sessions.remove(at: pos)
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
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Label(session.formattedDuration, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("\(session.feedbackItems.count)개 피드백", systemImage: "bubble.left")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(session.recordedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

struct EditAthleteView: View {
    @Bindable var athlete: Athlete
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("기본 정보") {
                    TextField("이름", text: $athlete.name)
                    TextField("종목", text: $athlete.sport)
                    TextField("포지션", text: $athlete.position)
                }
                Section("메모") {
                    TextField("메모", text: $athlete.profileNote, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                }
            }
            .navigationTitle("선수 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") { dismiss() }
                }
            }
        }
    }
}
