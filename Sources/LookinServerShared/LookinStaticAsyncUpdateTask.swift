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

public struct LookinStaticAsyncUpdateTask: Hashable {
    public var oid: UInt = 0
    public var taskType: LookinStaticAsyncUpdateTaskType = .noScreenshot
    public var attrRequest: LookinDetailUpdateTaskAttrRequest = .automatic
    public var needBasisVisualInfo: Bool = false
    public var needSubitems: Bool = false
    public var clientReadableVersion: String?
    public var frameSize: CGSize = .zero

    public init() {}

    public func hash(into hasher: inout Hasher) {
        hasher.combine(oid)
        hasher.combine(taskType.rawValue)
        hasher.combine(attrRequest.rawValue)
        hasher.combine(needBasisVisualInfo)
        hasher.combine(needSubitems)
    }

    public static func == (lhs: LookinStaticAsyncUpdateTask, rhs: LookinStaticAsyncUpdateTask) -> Bool {
        lhs.oid == rhs.oid
            && lhs.taskType == rhs.taskType
            && lhs.attrRequest == rhs.attrRequest
            && lhs.needBasisVisualInfo == rhs.needBasisVisualInfo
            && lhs.needSubitems == rhs.needSubitems
    }
}

public struct LookinStaticAsyncUpdateTasksPackage {
    public var tasks: [LookinStaticAsyncUpdateTask]?

    public init() {}
}
