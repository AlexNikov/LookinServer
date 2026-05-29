import Foundation

public class LookinHierarchyInfo: NSObject, NSCopying {
    public var displayItems: [LookinDisplayItem]?
    public var colorAlias: [String: Any]?
    public var collapsedClassList: [String]?
    public var appInfo: LookinAppInfo?
    public var serverVersion: Int32 = 0

    public override init() {
        super.init()
    }

    // MARK: - NSCopying

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = LookinHierarchyInfo()
        copy.serverVersion = serverVersion
        copy.appInfo = appInfo?.copy() as? LookinAppInfo
        copy.collapsedClassList = collapsedClassList
        copy.colorAlias = colorAlias
        copy.displayItems = displayItems?.lookin_map { $1.copy() as? LookinDisplayItem }
        return copy
    }

    private enum CodingKey {
        static let displayItems = "1"
        static let appInfo = "2"
        static let colorAlias = "3"
        static let collapsedClassList = "4"
    }

}
