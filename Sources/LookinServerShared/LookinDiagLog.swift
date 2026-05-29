import Foundation

/// Grep-friendly diagnostics: `LookinDiag` in Console / `simctl log stream`, plus MCP ring buffer.
public enum LookinDiagLog {
    private static let lock = NSLock()
    private static var buffer: [String] = []
    private static let capacity = 500

    public static func log(_ message: String) {
        NSLog("LookinDiag - %@", message)
        lock.lock()
        if buffer.count >= capacity {
            buffer.removeFirst(buffer.count - capacity + 1)
        }
        buffer.append(message)
        lock.unlock()
    }

    public static func recentLines(limit: Int) -> [String] {
        let n = max(1, min(limit, capacity))
        lock.lock()
        let slice = buffer.suffix(n)
        lock.unlock()
        return Array(slice)
    }

    public static func clear() {
        lock.lock()
        buffer.removeAll(keepingCapacity: true)
        lock.unlock()
    }

    public static var lineCount: Int {
        lock.lock()
        let count = buffer.count
        lock.unlock()
        return count
    }
}
