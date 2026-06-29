import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation

struct VideoImportView: View {
    let athleteId: UUID
    let athleteName: String
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingCamera = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var errorMessage = ""
    @State private var pendingURL: URL?
    @State private var pendingDuration: Double = 0
    @State private var sessionTitle = ""
    @State private var showingSaveAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isProcessing {
                    Spacer()
                    VStack(spacing: 20) {
                        ProgressView().scaleEffect(1.5)
                        Text("영상 처리 중...").font(.headline)
                    }
                    Spacer()
                } else {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 64)).foregroundColor(.accentColor)
                        Text("영상 추가").font(.title2.bold())
                        Text("카메라로 촬영하거나 사진 앱에서 가져오세요")
                            .font(.subheadline).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 48)

                    VStack(spacing: 14) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button { showingCamera = true } label: {
                                Label("카메라로 촬영", systemImage: "camera.fill")
                                    .font(.headline).frame(maxWidth: .infinity).padding()
                                    .background(Color.accentColor).foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        PhotosPicker(selection: $pickerItem, matching: .videos) {
                            Label("사진 앱에서 가져오기", systemImage: "photo.on.rectangle")
                                .font(.headline).frame(maxWidth: .infinity).padding()
                                .background(Color(.systemGray5)).foregroundColor(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 28)
                    Spacer()

                    if !errorMessage.isEmpty {
                        Text(errorMessage).foregroundColor(.red).font(.caption).padding()
                    }
                }
            }
            .navigationTitle(athleteName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPickerView(
                onCancel: { showingCamera = false },
                onDone: { url, dur in
                    pendingURL = url
                    pendingDuration = dur
                    sessionTitle = "\(athleteName) - \(Date().formatted(date: .abbreviated, time: .shortened))"
                    showingCamera = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showingSaveAlert = true }
                }
            )
            .ignoresSafeArea()
        }
        .alert("영상 저장", isPresented: $showingSaveAlert) {
            TextField("세션 제목", text: $sessionTitle)
            Button("저장") { saveVideo() }
            Button("취소", role: .cancel) { pendingURL = nil }
        } message: {
            Text("촬영한 영상을 저장할까요?")
        }
        .task(id: pickerItem) {
            guard let item = pickerItem else { return }
            await importFromPhotos(item: item)
        }
    }

    private func saveVideo() {
        guard let url = pendingURL else { return }
        let s = VideoSession(title: sessionTitle.isEmpty ? "세션" : sessionTitle,
                             videoFilename: url.lastPathComponent, duration: pendingDuration)
        store.addSession(s, athleteId: athleteId)
        pendingURL = nil
        dismiss()
    }

    private func importFromPhotos(item: PhotosPickerItem) async {
        await MainActor.run { isProcessing = true; errorMessage = "" }
        do {
            guard let movie = try await item.loadTransferable(type: VideoFile.self) else {
                await MainActor.run { errorMessage = "영상을 불러올 수 없습니다."; isProcessing = false }
                return
            }
            let filename = "video_\(UUID().uuidString).mov"
            let dest = store.videosDir.appendingPathComponent(filename)
            try FileManager.default.copyItem(at: movie.url, to: dest)
            let asset = AVURLAsset(url: dest)
            let dur = (try? await asset.load(.duration))?.seconds ?? 0
            let title = "\(athleteName) - \(Date().formatted(date: .abbreviated, time: .shortened))"
            let session = VideoSession(title: title, videoFilename: filename, duration: dur)
            await MainActor.run { store.addSession(session, athleteId: athleteId); dismiss() }
        } catch {
            await MainActor.run { errorMessage = "오류: \(error.localizedDescription)"; isProcessing = false }
        }
    }
}

// MARK: - VideoFile Transferable

struct VideoFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { SentTransferredFile($0.url) } importing: { recv in
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("imp_\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: recv.file, to: tmp)
            return VideoFile(url: tmp)
        }
    }
}

// MARK: - Camera UIKit wrapper

struct CameraPickerView: UIViewControllerRepresentable {
    let onCancel: () -> Void
    let onDone: (URL, Double) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = .camera
        p.mediaTypes = ["public.movie"]
        p.videoMaximumDuration = 3600
        p.delegate = context.coordinator
        return p
    }

    func updateUIViewController(_: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ p: CameraPickerView) { parent = p }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let tmp = info[.mediaURL] as? URL else { parent.onCancel(); return }
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("videos")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let dest = dir.appendingPathComponent("video_\(UUID().uuidString).mov")
            do {
                try FileManager.default.copyItem(at: tmp, to: dest)
                Task {
                    let dur = (try? await AVURLAsset(url: dest).load(.duration))?.seconds ?? 0
                    await MainActor.run { self.parent.onDone(dest, dur) }
                }
            } catch { parent.onDone(tmp, 0) }
        }

        func imagePickerControllerDidCancel(_: UIImagePickerController) { parent.onCancel() }
    }
}
