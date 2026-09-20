import Foundation
import Photos
import SwiftUI
import UIKit

struct CapturedFrame: Identifiable {
    let id = UUID()
    let url: URL
    let heading: Double
}

@MainActor
final class CaptureModel: ObservableObject {
    enum Screen {
        case home
        case capture
        case preview
    }

    @Published var screen: Screen = .home
    @Published private(set) var frames: [CapturedFrame] = []
    @Published private(set) var panoramaURL: URL?
    @Published var errorMessage: String?
    @Published var isBusy = false

    let camera = CameraService()
    let motion = MotionGuide()

    func beginCapture() {
        errorMessage = nil
        frames = []
        panoramaURL = nil
        camera.resetLastPhoto()
        camera.start()
        motion.start()
        screen = .capture
    }

    func captureFrame() {
        guard !isBusy else { return }
        camera.capture()
    }

    func receiveFrame(_ url: URL) {
        frames.append(CapturedFrame(url: url, heading: motion.heading))
    }

    func finishCapture() {
        guard frames.count >= 3 else {
            errorMessage = "Capture at least three photos first."
            return
        }

        isBusy = true
        camera.stop()
        motion.stop()

        Task {
            do {
                let output = try await PanoramaStitcher.makePanorama(
                    from: frames.map(\.url),
                    destination: FileManager.default.temporaryDirectory
                        .appendingPathComponent("simple-360-\(UUID().uuidString).jpg")
                )
                await MainActor.run {
                    self.panoramaURL = output
                    self.isBusy = false
                    self.screen = .preview
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isBusy = false
                }
            }
        }
    }

    func cancelCapture() {
        camera.stop()
        motion.stop()
        screen = .home
    }

    func saveToPhotos() {
        guard let panoramaURL else { return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                Task { @MainActor in
                    self.errorMessage = "Photos permission is needed to save this panorama."
                }
                return
            }
            guard let image = UIImage(contentsOfFile: panoramaURL.path) else {
                Task { @MainActor in
                    self.errorMessage = "The panorama image could not be read."
                }
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { saved, error in
                Task { @MainActor in
                    if let error {
                        self.errorMessage = error.localizedDescription
                    } else if !saved {
                        self.errorMessage = "The panorama could not be saved."
                    }
                }
            }
        }
    }
}