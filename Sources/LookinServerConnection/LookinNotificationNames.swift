#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation

#if canImport(LookinServerShared)
import LookinServerShared
#endif
#if canImport(LookinServerCoreSwift)
import LookinServerCoreSwift
#endif
#if canImport(LookinServerCategories)
import LookinServerCategories
#endif
#if canImport(LookinServerOthers)
import LookinServerOthers
#endif
#if canImport(LookinServerPeertalk)
import LookinServerPeertalk
#endif
extension Notification.Name {
    static let lookin2D = Notification.Name("Lookin_2D")
    static let lookin3D = Notification.Name("Lookin_3D")
    static let lookinExport = Notification.Name("Lookin_Export")
    static let lookinRelationSearch = Notification.Name("Lookin_RelationSearch")
    static let getLookinInfo = Notification.Name("GetLookinInfo")
    static let lookinWillExport = Notification.Name("Lookin_WillExport")
    static let lookinDidFinishExport = Notification.Name("Lookin_DidFinishExport")
}

#endif
