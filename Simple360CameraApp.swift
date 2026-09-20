import SwiftUI

@main
struct Simple360CameraApp: App {
    @StateObject private var model = CaptureModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .preferredColorScheme(.dark)
        }
    }
}