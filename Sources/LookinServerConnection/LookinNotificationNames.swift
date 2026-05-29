#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation

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
