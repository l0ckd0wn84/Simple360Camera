# Simple 360 Camera — native iOS project

This folder contains a complete Xcode project and the native Swift
implementation. Open `Simple360Camera.xcodeproj` directly on macOS. It
uses only Apple frameworks:

- SwiftUI for the screens and interactive viewer
- AVFoundation for the camera preview and photo capture
- CoreMotion for rotation and level guidance
- Core Image / Image I/O for the local panorama file
- PhotosUI / Photos for export

## Project settings

The project is configured as an iOS application with:

- Bundle identifier: `com.simple360camera.app`
- Deployment target: iOS 17.0
- Device family: iPhone
- SwiftUI application lifecycle
- Automatic code signing
- Camera, motion, and Photos permission descriptions
- `AppIcon` asset catalog

Select a development team in Xcode's Signing & Capabilities tab, choose an
iPhone destination, and build the app.

The stitcher intentionally favors a predictable, memory-bounded local export
over a large third-party dependency. It produces a 2:1 equirectangular JPEG
with Google Photo Sphere XMP tags. Each source frame contributes a vertical
slice in capture order, which is a reliable first local version and leaves a
single replacement point for a feature-based stitcher later.