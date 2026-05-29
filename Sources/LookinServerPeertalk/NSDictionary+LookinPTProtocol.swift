#if SHOULD_COMPILE_LOOKIN_SERVER

import Dispatch
import Foundation

extension NSDictionary {
    @objc(createReferencingDispatchData)
    public func createReferencingDispatchData() -> dispatch_data_t? {
        do {
            let plistData = try PropertyListSerialization.data(
                fromPropertyList: self,
                format: .binary,
                options: 0
            )
            return (plistData as NSData).createReferencingDispatchData()
        } catch {
            NSLog("Failed to serialize property list: %@", error as NSError)
            return nil
        }
    }

    @objc(dictionaryWithContentsOfDispatchData:)
    public static func dictionary(withContentsOf dispatchDataRef: dispatch_data_t?) -> NSDictionary? {
        guard let dispatchData = lookinDispatchData(from: dispatchDataRef) else { return nil }

        let plistBytes = dispatchData.lookinCopyBytes()
        return try? PropertyListSerialization.propertyList(from: plistBytes, format: nil) as? NSDictionary
    }
}

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
