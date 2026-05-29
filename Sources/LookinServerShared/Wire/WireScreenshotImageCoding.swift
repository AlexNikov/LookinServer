import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

public enum WireScreenshotImageCoding {
    public static func pngData(from image: LookinImage) -> Data? {
        #if os(iOS) || os(tvOS) || os(visionOS)
        if let uiImage = image as? UIImage {
            return uiImage.pngData()
        }
        #elseif os(macOS)
        if let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff) {
            return rep.representation(using: .png, properties: [:])
        }
        #endif
        return nil
    }

    public static func lookinImage(from data: Data, format: WireImageFormat) -> LookinImage? {
        switch format {
        case .png, .jpeg:
            #if os(iOS) || os(tvOS) || os(visionOS)
            return UIImage(data: data)
            #elseif os(macOS)
            return NSImage(data: data)
            #else
            return nil
            #endif
        }
    }
}
