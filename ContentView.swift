import Photos
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: CaptureModel
    @State private var previewOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            switch model.screen {
            case .home:
                home
            case .capture:
                capture
            case .preview:
                preview
            }
        }
        .alert("Simple 360 Camera", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var home: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Circle().stroke(Color.greenish, lineWidth: 1).frame(width: 30, height: 30)
                    .overlay(Circle().fill(Color.mint).frame(width: 8, height: 8))
                Text("PRIVATE / ON DEVICE")
                    .font(.caption2.weight(.bold))
                    .tracking(1.8)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Text("Simple\n360 Camera")
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .tracking(-1.5)
                .foregroundStyle(.white)
            Text("Capture a complete view of the room around you. No account. No cloud.")
                .font(.body)
                .foregroundStyle(.gray)
                .padding(.top, 16)
                .frame(maxWidth: 320, alignment: .leading)
            Spacer()
            HStack(spacing: 24) {
                detail(value: "24", label: "frames / turn")
                Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1, height: 30)
                detail(value: "360°", label: "local capture")
            }
            Button(action: model.beginCapture) {
                HStack {
                    Text("New 360° Photo").font(.body.weight(.bold))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 22)
                .frame(height: 62)
                .background(Color.lime, in: Capsule())
            }
            .padding(.top, 18)
            Text("Hold your phone in place and rotate slowly.")
                .font(.caption)
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
    }

    private var capture: some View {
        ZStack {
            CameraPreview(session: model.camera.session).ignoresSafeArea()
            Color.black.opacity(0.14).ignoresSafeArea()
            VStack {
                HStack {
                    Button(action: model.cancelCapture) {
                        Image(systemName: "xmark").frame(width: 42, height: 42)
                    }
                    Spacer()
                    Text("Photo \(min(model.frames.count + 1, 24)) / 24")
                        .font(.caption.weight(.bold))
                    Spacer()
                    Circle().fill(model.motion.isAvailable ? Color.lime : Color.red).frame(width: 7, height: 7)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                Spacer()
                Circle()
                    .stroke(model.motion.isLevel ? Color.white : Color.red, lineWidth: 2)
                    .frame(width: 80, height: 80)
                Text(model.motion.isLevel ? "Rotate slowly to the target" : "Keep the phone level")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.top, 18)
                Spacer()
                HStack {
                    Text("Finish")
                        .foregroundStyle(model.frames.count >= 3 ? .white : .gray)
                        .onTapGesture { model.finishCapture() }
                    Spacer()
                    Button(action: model.captureFrame) {
                        Circle().fill(Color.lime).frame(width: 66, height: 66)
                    }
                    .overlay(Circle().stroke(.white, lineWidth: 4).frame(width: 82, height: 82))
                    Spacer()
                    Text("\(model.frames.count) saved")
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 24)
            }
        }
        .onReceive(model.camera.$lastPhotoURL.compactMap { $0 }) { url in
            model.receiveFrame(url)
        }
    }

    private var preview: some View {
        VStack(spacing: 18) {
            HStack {
                Button(action: { model.screen = .home }) {
                    Image(systemName: "arrow.left").frame(width: 42, height: 42)
                }
                VStack(alignment: .leading) {
                    Text("CAPTURE COMPLETE").font(.caption2.weight(.bold)).tracking(1.5).foregroundStyle(.gray)
                    Text("360° Preview").font(.title2.weight(.bold))
                }
                Spacer()
                Text("\(model.frames.count) frames")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1), in: Capsule())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            Spacer()
            if let url = model.panoramaURL, let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 230)
                    .clipped()
                    .offset(x: previewOffset)
                    .gesture(DragGesture().onChanged { previewOffset = $0.translation.width })
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)
            }
            Spacer()
            VStack(spacing: 10) {
                Button(action: model.saveToPhotos) {
                    Label("Save to Photos", systemImage: "arrow.down.to.line")
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundStyle(.black)
                        .background(Color.lime, in: Capsule())
                }
                if let url = model.panoramaURL {
                    ShareLink(item: url) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundStyle(.white)
                            .overlay(Capsule().stroke(.white.opacity(0.2)))
                    }
                }
                Text("Processed on this device · nothing uploaded")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func detail(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(.title3.weight(.bold)).foregroundStyle(.white)
            Text(label).font(.caption).foregroundStyle(.gray)
        }
    }
}

private extension Color {
    static let lime = Color(red: 0.84, green: 1, blue: 0.33)
    static let mint = Color(red: 0.43, green: 0.91, blue: 0.82)
    static let greenish = Color(red: 0.16, green: 0.21, blue: 0.18)
}