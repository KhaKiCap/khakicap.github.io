import AVFoundation
import Combine

@MainActor
final class CameraManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var error: String?

    let session = AVCaptureSession()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var timer: Timer?

    var lastRecordingURL: URL?
    var lastDuration: Double = 0

    private var completionHandler: ((URL, Double) -> Void)?

    override init() {
        super.init()
        setupSession()
    }

    func startSession() {
        guard !session.isRunning else { return }
        Task.detached { [weak self] in
            self?.session.startRunning()
        }
    }

    func stopSession() {
        guard session.isRunning else { return }
        Task.detached { [weak self] in
            self?.session.stopRunning()
        }
    }

    func startRecording() {
        let outputURL = makeOutputURL()
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        isRecording = true
        recordingDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.recordingDuration += 1
            }
        }
    }

    func stopRecording(completion: @escaping (URL, Double) -> Void) {
        completionHandler = completion
        movieOutput.stopRecording()
        timer?.invalidate()
        timer = nil
        isRecording = false
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            error = "카메라를 사용할 수 없습니다."
            session.commitConfiguration()
            return
        }
        session.addInput(videoInput)

        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        session.commitConfiguration()
    }

    private func makeOutputURL() -> URL {
        let filename = "recording_\(Date().timeIntervalSince1970).mov"
        return FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput,
                                didFinishRecordingTo outputFileURL: URL,
                                from connections: [AVCaptureConnection],
                                error: Error?) {
        let duration = output.recordedDuration.seconds
        Task { @MainActor [weak self] in
            self?.lastRecordingURL = outputFileURL
            self?.lastDuration = duration
            self?.completionHandler?(outputFileURL, duration)
            self?.completionHandler = nil
        }
    }
}
