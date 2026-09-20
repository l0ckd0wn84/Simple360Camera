import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import UIKit

enum PanoramaStitcher {
    enum StitchError: LocalizedError {
        case noFrames
        case invalidImage
        case couldNotCreateDestination

        var errorDescription: String? {
            switch self {
            case .noFrames: return "No captured photos were available."
            case .invalidImage: return "One of the captured photos could not be read."
            case .couldNotCreateDestination: return "The panorama file could not be created."
            }
        }
    }

    static func makePanorama(from urls: [URL], destination: URL) async throws -> URL {
        guard !urls.isEmpty else { throw StitchError.noFrames }

        let images = try urls.compactMap { UIImage(contentsOfFile: $0.path)?.cgImage }
        guard images.count == urls.count, let first = images.first else {
            throw StitchError.invalidImage
        }

        let outputWidth = min(max(first.width * 2, 2048), 8192)
        let outputHeight = outputWidth / 2
        guard let context = CGContext(
            data: nil,
            width: outputWidth,
            height: outputHeight,
            bitsPerComponent: 8,
            bytesPerRow: outputWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw StitchError.invalidImage
        }

        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: outputWidth, height: outputHeight))

        let sliceWidth = CGFloat(outputWidth) / CGFloat(images.count)
        for (index, image) in images.enumerated() {
            let sourceAspect = CGFloat(image.width) / CGFloat(image.height)
            let sliceRect = CGRect(
                x: CGFloat(index) * sliceWidth,
                y: 0,
                width: sliceWidth + 1,
                height: CGFloat(outputHeight)
            )
            let sourceRect: CGRect
            if sourceAspect > 2 {
                let cropWidth = CGFloat(image.height) * 2
                sourceRect = CGRect(
                    x: (CGFloat(image.width) - cropWidth) / 2,
                    y: 0,
                    width: cropWidth,
                    height: CGFloat(image.height)
                )
            } else {
                sourceRect = CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height))
            }
            context.saveGState()
            context.clip(to: sliceRect)
            context.draw(image, in: sliceRect, byTiling: false)
            context.restoreGState()
            _ = sourceRect
        }

        guard let panorama = context.makeImage(),
              let destinationRef = CGImageDestinationCreateWithURL(
                destination as CFURL,
                UTType.jpeg.identifier as CFString,
                1,
                nil
              )
        else {
            throw StitchError.couldNotCreateDestination
        }

        let xmp = PanoramaMetadata.packet(width: outputWidth, height: outputHeight)
        let properties: [CFString: Any] = [
            kCGImagePropertyXMPDictionary: xmp,
            kCGImagePropertyJPEGDictionary: [
                kCGImageDestinationLossyCompressionQuality: 0.9
            ]
        ]
        CGImageDestinationAddImage(destinationRef, panorama, properties as CFDictionary)
        guard CGImageDestinationFinalize(destinationRef) else {
            throw StitchError.couldNotCreateDestination
        }
        return destination
    }
}