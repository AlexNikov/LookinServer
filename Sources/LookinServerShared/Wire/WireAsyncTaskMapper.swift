import Foundation

public enum WireAsyncTaskMapper {
    public static func wireTask(from task: LookinStaticAsyncUpdateTask) -> WireStaticAsyncUpdateTask {
        WireStaticAsyncUpdateTask(
            oid: task.oid,
            taskType: task.taskType.rawValue,
            attrRequest: task.attrRequest.rawValue,
            needBasisVisualInfo: task.needBasisVisualInfo,
            needSubitems: task.needSubitems,
            clientReadableVersion: task.clientReadableVersion
        )
    }

    public static func lookinTask(from wire: WireStaticAsyncUpdateTask) -> LookinStaticAsyncUpdateTask {
        var task = LookinStaticAsyncUpdateTask()
        task.oid = wire.oid
        task.taskType = LookinStaticAsyncUpdateTaskType(rawValue: wire.taskType) ?? .noScreenshot
        task.attrRequest = LookinDetailUpdateTaskAttrRequest(rawValue: wire.attrRequest) ?? .automatic
        task.needBasisVisualInfo = wire.needBasisVisualInfo
        task.needSubitems = wire.needSubitems
        task.clientReadableVersion = wire.clientReadableVersion
        return task
    }

    public static func wirePackage(from package: LookinStaticAsyncUpdateTasksPackage) -> WireStaticAsyncUpdateTasksPackage {
        WireStaticAsyncUpdateTasksPackage(
            tasks: package.tasks?.map { wireTask(from: $0) }
        )
    }

    public static func lookinPackage(from wire: WireStaticAsyncUpdateTasksPackage) -> LookinStaticAsyncUpdateTasksPackage {
        var package = LookinStaticAsyncUpdateTasksPackage()
        package.tasks = wire.tasks?.map { lookinTask(from: $0) }
        return package
    }

    public static func wirePackages(from data: Any?) -> [WireStaticAsyncUpdateTasksPackage]? {
        if let packages = data as? [LookinStaticAsyncUpdateTasksPackage] {
            return packages.map { wirePackage(from: $0) }
        }
        if let packages = data as? NSArray {
            return packages.compactMap { $0 as? LookinStaticAsyncUpdateTasksPackage }.map { wirePackage(from: $0) }
        }
        return nil
    }

    public static func wirePatchTasks(from data: Any?) -> [WireStaticAsyncUpdateTask]? {
        if let tasks = data as? [LookinStaticAsyncUpdateTask] {
            return tasks.map { wireTask(from: $0) }
        }
        if let tasks = data as? NSArray {
            return tasks.compactMap { $0 as? LookinStaticAsyncUpdateTask }.map { wireTask(from: $0) }
        }
        return nil
    }
}
