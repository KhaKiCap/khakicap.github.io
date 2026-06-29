import SwiftUI
import AVFoundation

struct CameraRecordingView: View {
    let athlete: Athlete
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var cameraManager = CameraManager()
    @State private var sessionTitle = ""
    @State private var showingSaveDialog = false
    @State private var pendingURL: URL?
    @State private var pendingDuration: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreviewView(session: cameraManager.session)
                .ignoresSafeArea()

            VStack {
                topBar
                Spacer()
                bottomControls
            }
        }
        .onAppear { cameraManager.startSession() }
        .onDisappear { cameraManager.stopSession() }
        .alert("영상 저장", isPresented: $showingSaveDialog) {
            TextField("세션 제목", text: $sessionTitle)
            Button("저장") { saveSession() }
            Button("삭제", role: .destructive) { dismiss() }
        } message: {
            Text("이 촬영 영상을 저장하시겠습니까?")
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Circle())
            }

            Spacer()

            if cameraManager.isRecording {
                recordingIndicator
            }

            Spacer()
                .frame(width: 44)
        }
        .padding()
    }

    private var recordingIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .opacity(cameraManager.isRecording ? 1 : 0)
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: cameraManager.isRecording)

            Text(formatDuration(cameraManager.recordingDuration))
                .font(.system(.body, design: .monospaced).bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.5))
        .clipShape(Capsule())
    }

    private var bottomControls: some View {
        VStack(spacing: 20) {
            Text(cameraManager.isRecording ? "탭하여 촬영 중지" : "탭하여 촬영 시작")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))

            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .strokeBorder(.white, lineWidth: 4)
                        .frame(width: 80, height: 80)

                    if cameraManager.isRecording {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                            .frame(width: 34, height: 34)
                    } else {
                        Circle()
                            .fill(.white)
                            .frame(width: 66, height: 66)
                    }
                }
            }
            .animation(.spring(response: 0.25), value: cameraManager.isRecording)

            if let error = cameraManager.error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .padding(.bottom, 50)
    }

    private func toggleRecording() {
        if cameraManager.isRecording {
            cameraManager.stopRecording { url, duration in
                pendingURL = url
                pendingDuration = duration
                sessionTitle = "\(athlete.name) - \(Date().formatted(date: .abbreviated, time: .shortened))"
                showingSaveDialog = true
            }
        } else {
            cameraManager.startRecording()
        }
    }

    private func saveSession() {
        guard let url = pendingURL else { return }
        let session = VideoSession(
            title: sessionTitle.isEmpty ? "세션" : sessionTitle,
            videoURL: url,
            duration: pendingDuration
        )
        athlete.sessions.append(session)
        try? modelContext.save()
        dismiss()
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
