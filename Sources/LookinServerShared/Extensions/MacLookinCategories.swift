#if os(macOS)

import AppKit

extension NSImage {
    @objc(lookin_data)
    public func lookin_data() -> Data? {
        tiffRepresentation
    }
}

#endif
