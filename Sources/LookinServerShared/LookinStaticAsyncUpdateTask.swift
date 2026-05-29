import Foundation
import CoreGraphics

public enum LookinStaticAsyncUpdateTaskType: Int {
    case noScreenshot = 0
    case soloScreenshot = 1
    case groupScreenshot = 2
}

public enum LookinDetailUpdateTaskAttrRequest: Int {
    case automatic = 0
    case need = 1
    case notNeed = 2
}

public class LookinStaticAsyncUpdateTask: NSObject {
    public var oid: UInt = 0
    public var taskType: LookinStaticAsyncUpdateTaskType = .noScreenshot
    public var attrRequest: LookinDetailUpdateTaskAttrRequest = .automatic
    public var needBasisVisualInfo: Bool = false
    public var needSubitems: Bool = false
    public var clientReadableVersion: String?
    public var frameSize: CGSize = .zero

    public override init() {
        super.init()
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(oid)
        hasher.combine(taskType.rawValue)
        hasher.combine(attrRequest.rawValue)
        hasher.combine(needBasisVisualInfo)
        hasher.combine(needSubitems)
        return hasher.finalize()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? LookinStaticAsyncUpdateTask else { return false }
        if self === other { return true }
        return oid == other.oid
            && taskType == other.taskType
            && attrRequest == other.attrRequest
            && needBasisVisualInfo == other.needBasisVisualInfo
            && needSubitems == other.needSubitems
    }
}

public class LookinStaticAsyncUpdateTasksPackage: NSObject {
    public var tasks: [LookinStaticAsyncUpdateTask]?

    public override init() {
        super.init()
    }

}
