import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation
import UIKit

// MARK: - VideoImportView

struct VideoImportView: View {
    let athleteId: UUID
    let athleteName: String
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingCamera = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var errorMessage: String?
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
                            .font(.system(size: 64))
                            .foregroundColor(Color.accentColor)
                        Text("영상 추가").font(.title2.bold())
                        Text("카메라로 직접 촬영하거나\n사진 앱에서 기존 영상을 가져오세요")
                            .font(.subheadline).foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 48)

                    VStack(spacing: 14) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button { showingCamera = true } label: {
                                Label("카메라로 촬영", systemImage: "camera.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        PhotosPicker(selection: $pickerItem, matching: .videos) {
                            Label("사진 앱에서 가져오기", systemImage: "photo.stack")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 28)

                    Spacer()

                    if let error = errorMessage {
                        Text(error).foregroundColor(.red).font(.caption).padding()
                    }
                }
            }
            .navigationTitle(athleteName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPickerView(onCancel: { showingCamera = false }) { url, duration in
                pendingURL = url
                pendingDuration = duration
                sessionTitle = "\(athleteName) - \(Date().formatted(date: .abbreviated, time: .shortened))"
                showingCamera = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingSaveAlert = true
                }
            }
            .ignoresSafeArea()
        }
        .alert("영상 저장", isPresented: $showingSaveAlert) {
            TextField("세션 제목", text: $sessionTitle)
            Button("저장") { savePendingVideo() }
            Button("취소", role: .cancel) { pendingURL = nil }
        } message: {
            Text("이 영상을 저장하시겠습니까?")
        }
        .onChange(of: pickerItem) { item in
            guard let item else { return }
            Task { await importFromPhotos(item: item) }
        }
    }

    private func savePendingVideo() {
        guard let url = pendingURL else { return }
        let session = VideoSession(
            title: sessionTitle.isEmpty ? "세션" : sessionTitle,
            videoFilename: url.lastPathComponent,
            duration: pendingDuration
        )
        store.addSession(session, athleteId: athleteId)
        pendingURL = nil
        dismiss()
    }

    private func importFromPhotos(item: PhotosPickerItem) async {
        isProcessing = true
        errorMessage = nil
        do {
            guard let movie = try await item.loadTransferable(type: VideoFile.self) else {
                errorMessage = "영상을 불러올 수 없습니다."
                isProcessing = false
                return
            }
            let filename = "video_\(UUID().uuidString).mov"
            let destURL = store.videosDirectoryURL.appendingPathComponent(filename)
            try FileManager.default.copyItem(at: movie.url, to: destURL)
            let asset = AVURLAsset(url: destURL)
            let duration = (try? await asset.load(.duration))?.seconds ?? 0
            let title = "\(athleteName) - \(Date().formatted(date: .abbreviated, time: .shortened))"
            let session = VideoSession(title: title, videoFilename: filename, duration: duration)
            await MainActor.run {
                store.addSession(session, athleteId: athleteId)
                dismiss()
            }
        } catch {
            errorMessage = "가져오기 실패: \(error.localizedDescription)"
        }
        isProcessing = false
    }
}

// MARK: - VideoFile Transferable

struct VideoFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("import_\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return VideoFile(url: tempURL)
        }
    }
}

// MARK: - CameraPickerView

struct CameraPickerView: UIViewControllerRepresentable {
    let onCancel: () -> Void
    let onVideoRecorded: (URL, Double) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.videoMaximumDuration = 3600
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let tempURL = info[.mediaURL] as? URL else {
                parent.onCancel()
                return
            }
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let videosURL = docs.appendingPathComponent("videos")
            try? FileManager.default.createDirectory(at: videosURL, withIntermediateDirectories: true)
            let filename = "video_\(UUID().uuidString).mov"
            let destURL = videosURL.appendingPathComponent(filename)
            do {
                try FileManager.default.copyItem(at: tempURL, to: destURL)
                Task {
                    let asset = AVURLAsset(url: destURL)
                    let duration = (try? await asset.load(.duration))?.seconds ?? 0
                    await MainActor.run { self.parent.onVideoRecorded(destURL, duration) }
                }
            } catch {
                parent.onVideoRecorded(tempURL, 0)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onCancel()
        }
    }
}
