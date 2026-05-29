#if SHOULD_COMPILE_LOOKIN_SERVER

import Dispatch
import Foundation

@objc(Lookin_PTData)
public class LookinPTData: NSObject {
    @objc public private(set) var dispatchData: dispatch_data_t?
    @objc public private(set) var data: UnsafeMutableRawPointer?
    @objc public private(set) var length: Int = 0
    /// Stable copy of frame bytes (Peertalk buffer pointer is only valid during the read callback).
    private var retainedBytes: Data?

    @objc(initWithMappedDispatchData:data:length:)
    public init(mappedDispatchData: dispatch_data_t?, data: UnsafeMutableRawPointer?, length: Int) {
        dispatchData = mappedDispatchData
        self.data = data
        self.length = length
        if let mappedDispatchData, let dispatchData = lookinDispatchData(from: mappedDispatchData) {
            retainedBytes = dispatchData.lookinCopyBytes()
        } else if length > 0, let data {
            retainedBytes = Data(bytes: data, count: length)
        }
        super.init()
    }

    /// Bytes received for this Peertalk frame.
    @objc public func lookinPayloadBytes() -> Data {
        if let retainedBytes, !retainedBytes.isEmpty {
            return retainedBytes
        }
        if let dispatchData, let dispatchData = lookinDispatchData(from: dispatchData) {
            return dispatchData.lookinCopyBytes()
        }
        if length > 0, let data {
            return Data(bytes: data, count: length)
        }
        return Data()
    }

    public override var description: String {
        String(format: "<Lookin_PTData: %p (%zu bytes)>", self, length)
    }
}

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
