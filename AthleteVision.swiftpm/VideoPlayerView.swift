import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    let athleteId: UUID
    let sessionId: UUID
    @EnvironmentObject private var store: DataStore
    @State private var player: AVPlayer?
    @State private var currentTime: Double = 0
    @State private var showingFeedback = false
    @State private var token: Any?

    var session: VideoSession? { store.session(id: sessionId, athleteId: athleteId) }

    var body: some View {
        Group {
            if let session = session {
                List {
                    Section {
                        if let url = session.videoURL(), let player = player {
                            VideoPlayer(player: player)
                                .frame(height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .listRowInsets(EdgeInsets())
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5)).frame(height: 240)
                                .overlay {
                                    VStack(spacing: 8) {
                                        Image(systemName: "video.slash").font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        Text("영상 없음").font(.caption).foregroundColor(.secondary)
                                    }
                                }
                                .listRowInsets(EdgeInsets())
                        }
                    }

                    Section("정보") {
                        Label(session.recordedAt.formatted(date: .complete, time: .shortened),
                              systemImage: "calendar")
                            .font(.subheadline).foregroundColor(.secondary)
                        Label("길이: \(session.formattedDuration)", systemImage: "clock")
                            .font(.subheadline).foregroundColor(.secondary)
                    }

                    Section("피드백 (\(session.feedbackItems.count))") {
                        if session.feedbackItems.isEmpty {
                            PlaceholderView(
                                icon: "bubble.left.and.bubble.right",
                                title: "피드백 없음",
                                subtitle: "+ 버튼으로 현재 시점에 피드백을 추가하세요"
                            )
                            .listRowBackground(Color.clear)
                        } else {
                            ForEach(session.feedbackItems) { item in
                                FeedbackRow(item: item) {
                                    player?.seek(to: CMTime(seconds: item.timestamp,
                                                            preferredTimescale: 600))
                                }
                            }
                            .onDelete { idx in
                                idx.forEach {
                                    store.deleteFeedback(id: session.feedbackItems[$0].id,
                                                         sessionId: sessionId, athleteId: athleteId)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(session.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button { showingFeedback = true } label: {
                            Label("추가", systemImage: "plus.bubble")
                        }
                    }
                }
                .sheet(isPresented: $showingFeedback) {
                    FeedbackEditorView(athleteId: athleteId, sessionId: sessionId,
                                       currentTimestamp: currentTime)
                }
            } else {
                PlaceholderView(icon: "video.slash", title: "세션 없음", subtitle: "")
            }
        }
        .onAppear { setupPlayer() }
        .onDisappear { teardown() }
    }

    private func setupPlayer() {
        guard let url = session?.videoURL() else { return }
        let p = AVPlayer(url: url)
        token = p.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { t in currentTime = t.seconds }
        player = p
    }

    private func teardown() {
        if let t = token { player?.removeTimeObserver(t) }
        player?.pause()
        player = nil
    }
}

struct FeedbackRow: View {
    let item: FeedbackItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Text(item.formattedTimestamp)
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Image(systemName: item.category.systemImage).font(.caption)
                        .foregroundColor(item.category.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.category.rawValue).font(.caption.bold())
                        .foregroundColor(item.category.color)
                    Text(item.text).font(.subheadline).foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
