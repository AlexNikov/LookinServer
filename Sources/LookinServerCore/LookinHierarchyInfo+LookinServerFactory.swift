import Foundation
#if canImport(LookinShared)
import LookinShared
#endif

#if os(iOS) || os(tvOS) || os(visionOS)

extension LKHierarchyInfo {
    @objc(staticInfoWithLookinVersion:)
    public class func staticInfo(withLookinVersion version: String?) -> LKHierarchyInfo {
        var readCustomInfo = false
        if let version, version.lookin_numbericOSVersion() >= 10004 {
            readCustomInfo = true
        }

        LKS_CustomAttrSetterManager.sharedInstance().removeAll()

        let info = LKHierarchyInfo()
        info.serverVersion = lookinServerVersionInt32
        info.displayItems = LKS_HierarchyDisplayItemsMaker.items(
            withScreenshots: false,
            attrList: false,
            lowImageQuality: false,
            readCustomInfo: readCustomInfo,
            saveCustomSetter: true
        )
        info.appInfo = LKAppInfo.currentInfo(withScreenshot: false, icon: true, localIdentifiers: nil)
        info.collapsedClassList = LKSConfigManager.collapsedClassList()
        info.colorAlias = LKSConfigManager.colorAlias() as? [String: Any]
        return info
    }

    @objc(exportedInfo)
    public class func exportedInfo() -> LKHierarchyInfo {
        let info = LKHierarchyInfo()
        info.serverVersion = lookinServerVersionInt32
        info.displayItems = LKS_HierarchyDisplayItemsMaker.items(
            withScreenshots: true,
            attrList: true,
            lowImageQuality: true,
            readCustomInfo: true,
            saveCustomSetter: false
        )
        info.appInfo = LKAppInfo.currentInfo(withScreenshot: false, icon: true, localIdentifiers: nil)
        info.collapsedClassList = LKSConfigManager.collapsedClassList()
        info.colorAlias = LKSConfigManager.colorAlias() as? [String: Any]
        return info
    }
}

#endif
