import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @Bindable var session: VideoSession
    @Environment(\.modelContext) private var modelContext
    @State private var player: AVPlayer?
    @State private var currentTime: Double = 0
    @State private var isPlaying = false
    @State private var showingFeedbackEditor = false
    @State private var timeObserverToken: Any?

    private var sortedFeedback: [FeedbackItem] {
        session.feedbackItems.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        List {
            Section {
                videoPlayerSection
            }

            Section {
                sessionInfoSection
            }

            Section("피드백 (\(session.feedbackItems.count))") {
                if sortedFeedback.isEmpty {
                    ContentUnavailableView(
                        "피드백 없음",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("+ 버튼으로 현재 시점에 피드백을 추가하세요")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedFeedback) { item in
                        FeedbackRowView(item: item) {
                            player?.seek(to: CMTime(seconds: item.timestamp, preferredTimescale: 600))
                        }
                    }
                    .onDelete(perform: deleteFeedback)
                }
            }
        }
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingFeedbackEditor = true }) {
                    Label("피드백 추가", systemImage: "plus.bubble")
                }
            }
        }
        .sheet(isPresented: $showingFeedbackEditor) {
            FeedbackEditorView(session: session, currentTimestamp: currentTime)
        }
        .onAppear(perform: setupPlayer)
        .onDisappear(perform: teardownPlayer)
    }

    private var videoPlayerSection: some View {
        Group {
            if let player {
                VideoPlayer(player: player)
                    .frame(height: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .listRowInsets(EdgeInsets())
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 230)
                    .overlay {
                        Image(systemName: "video.slash")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }
        }
    }

    private var sessionInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(session.recordedAt.formatted(date: .complete, time: .shortened),
                      systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label("길이: \(session.formattedDuration)", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !session.notes.isEmpty {
                Text(session.notes)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func setupPlayer() {
        guard let url = session.videoURL else { return }
        let avPlayer = AVPlayer(url: url)
        player = avPlayer

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = avPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = time.seconds
        }
    }

    private func teardownPlayer() {
        if let token = timeObserverToken {
            player?.removeTimeObserver(token)
        }
        player?.pause()
        player = nil
    }

    private func deleteFeedback(at offsets: IndexSet) {
        let sorted = sortedFeedback
        for index in offsets {
            if let pos = session.feedbackItems.firstIndex(where: { $0.id == sorted[index].id }) {
                modelContext.delete(session.feedbackItems[pos])
                session.feedbackItems.remove(at: pos)
            }
        }
    }
}

struct FeedbackRowView: View {
    let item: FeedbackItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 4) {
                    Text(item.formattedTimestamp)
                        .font(.system(.caption, design: .monospaced).bold())
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    Image(systemName: item.category.systemImage)
                        .font(.caption)
                        .foregroundStyle(categoryColor(item.category))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.category.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(categoryColor(item.category))
                    Text(item.text)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func categoryColor(_ category: FeedbackCategory) -> Color {
        switch category {
        case .general: return .gray
        case .positive: return .yellow
        case .improvement: return .blue
        case .technique: return .green
        }
    }
}
