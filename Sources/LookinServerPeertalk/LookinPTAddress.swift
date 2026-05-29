#if SHOULD_COMPILE_LOOKIN_SERVER

import Darwin
import Foundation

@objc(Lookin_PTAddress)
public class LookinPTAddress: NSObject {
    private var sockaddr_ = sockaddr_storage()

    @objc(initWithSockaddr:)
    public init(sockaddr addr: UnsafePointer<sockaddr_storage>) {
        super.init()
        memcpy(&sockaddr_, addr, Int(addr.pointee.ss_len))
    }

    @objc public var name: String? {
        guard sockaddr_.ss_len != 0 else { return nil }

        var buf = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN) + 1)
        let result: String?
        if sockaddr_.ss_family == sa_family_t(AF_INET6) {
            var addr6 = sockaddr_in6()
            memcpy(&addr6, &sockaddr_, MemoryLayout<sockaddr_in6>.size)
            result = withUnsafePointer(to: &addr6.sin6_addr) {
                inet_ntop(AF_INET6, $0, &buf, socklen_t(INET6_ADDRSTRLEN)) != nil
                    ? String(cString: buf)
                    : nil
            }
        } else {
            var addr4 = sockaddr_in()
            memcpy(&addr4, &sockaddr_, MemoryLayout<sockaddr_in>.size)
            result = withUnsafePointer(to: &addr4.sin_addr) {
                inet_ntop(AF_INET, $0, &buf, socklen_t(INET_ADDRSTRLEN)) != nil
                    ? String(cString: buf)
                    : nil
            }
        }
        return result
    }

    @objc public var port: Int {
        guard sockaddr_.ss_len != 0 else { return 0 }
        if sockaddr_.ss_family == sa_family_t(AF_INET6) {
            var addr6 = sockaddr_in6()
            memcpy(&addr6, &sockaddr_, MemoryLayout<sockaddr_in6>.size)
            return Int(UInt16(bigEndian: addr6.sin6_port))
        }
        var addr4 = sockaddr_in()
        memcpy(&addr4, &sockaddr_, MemoryLayout<sockaddr_in>.size)
        return Int(UInt16(bigEndian: addr4.sin_port))
    }

    public override var description: String {
        guard sockaddr_.ss_len != 0, let name else { return "(?)" }
        return "\(name):\(port)"
    }
}

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
