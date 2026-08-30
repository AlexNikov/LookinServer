import Foundation

/// iOS LookinServer connection phase timings (LOOKIN_CONN_TIMING=1 or LOOKIN_VERIFY=1).
public enum LKServerConnectionTiming {
    private static let lock = NSLock()
    private static var completed: [[String: Any]] = []
    private static let capacity = 120

    public static var isEnabled: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["LOOKIN_CONN_TIMING"] == "1" || env["LOOKIN_VERIFY"] == "1"
    }

    public static func recordInstant(_ phase: String, durationMs: Int = 0, attrs: [String: Any] = [:]) {
        guard isEnabled else { return }
        lock.lock()
        defer { lock.unlock() }
        var entry: [String: Any] = [
            "phase": phase,
            "durationMs": durationMs,
            "ms": Int(Date().timeIntervalSince1970 * 1000),
        ]
        for (key, value) in attrs {
            entry[key] = value
        }
        if completed.count >= capacity {
            completed.removeFirst(completed.count - capacity + 1)
        }
        completed.append(entry)
        let attrSummary = attrs.isEmpty
            ? ""
            : " " + attrs.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: " ")
        LookinDiagLog.log("timing phase=\(phase) ms=\(durationMs)\(attrSummary)")
    }

    public static var summary: [String: Any] {
        lock.lock()
        defer { lock.unlock() }
        var totals: [String: Int] = [:]
        var counts: [String: Int] = [:]
        var maxMs: [String: Int] = [:]
        for entry in completed {
            guard let phase = entry["phase"] as? String,
                  let ms = entry["durationMs"] as? Int else { continue }
            totals[phase, default: 0] += ms
            counts[phase, default: 0] += 1
            maxMs[phase] = max(maxMs[phase] ?? 0, ms)
        }
        return [
            "enabled": true,
            "phaseCount": completed.count,
            "totalsMs": totals,
            "counts": counts,
            "maxMs": maxMs,
            "recent": completed.suffix(24).map { $0 },
        ]
    }
}
