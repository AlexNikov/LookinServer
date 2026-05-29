#if SHOULD_COMPILE_LOOKIN_SERVER

import Dispatch
import Foundation
import ObjectiveC

private var lookinPTDispatchDataRefKey: UInt8 = 0

extension NSData {
    @objc(createReferencingDispatchData)
    public func createReferencingDispatchData() -> dispatch_data_t {
        DispatchData(bytes: UnsafeRawBufferPointer(start: bytes, count: length)).lookinDispatchDataRef
    }
}

extension NSData {
    @objc(dataWithContentsOfDispatchData:)
    public static func data(withContentsOf dispatchDataRef: dispatch_data_t?) -> NSData? {
        guard let dispatchData = lookinDispatchData(from: dispatchDataRef) else { return nil }

        let copied = dispatchData.lookinCopyBytes()
        let ref = LookinPTDispatchData(dispatchData: dispatchData)
        let newData = NSData(data: copied)
        objc_setAssociatedObject(newData, &lookinPTDispatchDataRefKey, ref, .OBJC_ASSOCIATION_RETAIN)
        return newData
    }
}

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
