import Foundation

enum PanoramaMetadata {
    static func packet(width: Int, height: Int) -> [String: Any] {
        [
            "ProjectionType": "equirectangular",
            "UsePanoramaViewer": true,
            "PoseHeadingDegrees": 0,
            "CroppedAreaImageWidthPixels": width,
            "CroppedAreaImageHeightPixels": height,
            "FullPanoWidthPixels": width,
            "FullPanoHeightPixels": height,
            "CroppedAreaLeftPixels": 0,
            "CroppedAreaTopPixels": 0
        ]
    }
}