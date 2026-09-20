import AVFoundation
import Foundation

final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()
    @Published private(set) var lastPhotoURL: URL?
    @Published private(set) var permissionDenied = false

    private let output = AVCapturePhotoOutput()
    private let sessionQueue = DispatchQueue(label: "simple-360.camera.session")
    private var configured = false

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureIfNeeded()
            sessionQueue.async { [weak self] in
                guard let self, !self.session.isRunning else { return }
                self.session.startRunning()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.configureIfNeeded()
                    self.start()
                } else {
                    DispatchQueue.main.async { self.permissionDenied = true }
                }
            }
        default:
            DispatchQueue.main.async { self.permissionDenied = true }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func resetLastPhoto() {
        DispatchQueue.main.async {
            self.lastPhotoURL = nil
        }
    }

    func capture() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            self.output.capturePhoto(with: settings, delegate: self)
        }
    }

    private func configureIfNeeded() {
        sessionQueue.async { [weak self] in
            guard let self, !self.configured else { return }
            self.configured = true
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input),
                self.session.canAddOutput(self.output)
            else {
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(input)
            self.session.addOutput(self.output)
            self.session.commitConfiguration()
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard error == nil, let data = photo.fileDataRepresentation() else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("simple-360-frame-\(UUID().uuidString).jpg")
        do {
            try data.write(to: url, options: .atomic)
            DispatchQueue.main.async {
                self.lastPhotoURL = url
            }
        } catch {
            DispatchQueue.main.async {
                self.lastPhotoURL = nil
            }
        }
    }
}