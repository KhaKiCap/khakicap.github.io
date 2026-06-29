import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    let athleteId: UUID
    let sessionId: UUID
    @Environment(DataStore.self) private var store

    @State private var player: AVPlayer?
    @State private var currentTime: Double = 0
    @State private var showingFeedbackEditor = false
    @State private var timeObserverToken: Any?

    var session: VideoSession? { store.session(id: sessionId, athleteId: athleteId) }

    var body: some View {
        Group {
            if let session {
                List {
                    Section {
                        videoSection(session)
                    }

                    Section("세션 정보") {
                        Label(
                            session.recordedAt.formatted(date: .complete, time: .shortened),
                            systemImage: "calendar"
                        )
                        .font(.subheadline).foregroundStyle(.secondary)

                        Label("길이: \(session.formattedDuration)", systemImage: "clock")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }

                    Section("피드백 (\(session.feedbackItems.count))") {
                        if session.feedbackItems.isEmpty {
                            ContentUnavailableView(
                                "피드백 없음",
                                systemImage: "bubble.left.and.bubble.right",
                                description: Text("+ 버튼으로 현재 시점에 피드백을 추가하세요")
                            )
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(session.feedbackItems) { item in
                                FeedbackRowView(item: item) {
                                    player?.seek(to: CMTime(seconds: item.timestamp, preferredTimescale: 600))
                                }
                            }
                            .onDelete { offsets in
                                offsets.forEach {
                                    store.deleteFeedback(
                                        id: session.feedbackItems[$0].id,
                                        sessionId: sessionId,
                                        athleteId: athleteId
                                    )
                                }
                            }
                        }
                    }
                }
                .navigationTitle(session.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showingFeedbackEditor = true } label: {
                            Label("피드백 추가", systemImage: "plus.bubble")
                        }
                    }
                }
                .sheet(isPresented: $showingFeedbackEditor) {
                    FeedbackEditorView(
                        athleteId: athleteId,
                        sessionId: sessionId,
                        currentTimestamp: currentTime
                    )
                }
            } else {
                ContentUnavailableView("세션을 찾을 수 없습니다", systemImage: "video.slash")
            }
        }
        .onAppear { setupPlayer() }
        .onDisappear { teardownPlayer() }
    }

    @ViewBuilder
    private func videoSection(_ session: VideoSession) -> some View {
        if let url = session.videoURL(), let player {
            VideoPlayer(player: player)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .listRowInsets(EdgeInsets())
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(height: 240)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "video.slash").font(.largeTitle).foregroundStyle(.secondary)
                        Text("영상 파일을 찾을 수 없습니다").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .listRowInsets(EdgeInsets())
        }
    }

    private func setupPlayer() {
        guard let url = session?.videoURL() else { return }
        let avPlayer = AVPlayer(url: url)
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = time.seconds
        }
        player = avPlayer
    }

    private func teardownPlayer() {
        if let token = timeObserverToken { player?.removeTimeObserver(token) }
        player?.pause()
        player = nil
    }
}

struct FeedbackRowView: View {
    let item: FeedbackItem
    let onTap: () -> Void

    var categoryColor: Color {
        switch item.category {
        case .general: return .gray
        case .positive: return .yellow
        case .improvement: return .blue
        case .technique: return .green
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Text(item.formattedTimestamp)
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Image(systemName: item.category.systemImage)
                        .font(.caption)
                        .foregroundStyle(categoryColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.category.rawValue)
                        .font(.caption.bold()).foregroundStyle(categoryColor)
                    Text(item.text)
                        .font(.subheadline).foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
