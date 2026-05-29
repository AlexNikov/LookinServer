#if SHOULD_COMPILE_LOOKIN_SERVER
import Foundation

struct MCPHTTPRequest {
    let method: String
    let path: String
    let jsonBody: [String: Any]?
    let oidParam: UInt
}

struct MCPHTTPResponse {
    let statusCode: Int
    let jsonBody: [String: Any]

    static func ok(data: Any?) -> MCPHTTPResponse {
        MCPHTTPResponse(statusCode: 200, jsonBody: [
            "success": true,
            "data": data ?? NSNull(),
        ])
    }

    static func error(message: String, statusCode: Int) -> MCPHTTPResponse {
        MCPHTTPResponse(statusCode: statusCode, jsonBody: [
            "success": false,
            "error": message,
        ])
    }

    var httpData: Data {
        let body = (try? JSONSerialization.data(withJSONObject: jsonBody, options: []))
            ?? Data("{\"success\":false,\"error\":\"JSON serialization failed\"}".utf8)

        let statusText: String
        switch statusCode {
        case 200: statusText = "OK"
        case 400: statusText = "Bad Request"
        case 404: statusText = "Not Found"
        case 500: statusText = "Internal Server Error"
        case 503: statusText = "Service Unavailable"
        default: statusText = "OK"
        }

        var header = "HTTP/1.1 \(statusCode) \(statusText)\r\n"
        header += "Content-Type: application/json; charset=utf-8\r\n"
        header += "Content-Length: \(body.count)\r\n"
        header += "Connection: close\r\n"
        header += "Access-Control-Allow-Origin: *\r\n\r\n"

        var data = Data(header.utf8)
        data.append(body)
        return data
    }
}

enum MCPHTTPRequestParser {
    static func parse(_ data: Data) -> MCPHTTPRequest? {
        guard let raw = String(data: data, encoding: .utf8) else { return nil }
        guard let separatorRange = raw.range(of: "\r\n\r\n") else { return nil }

        let headerPart = String(raw[..<separatorRange.lowerBound])
        let lines = headerPart.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }

        let parts = requestLine.split(separator: " ", omittingEmptySubsequences: true)
        guard parts.count >= 2 else { return nil }

        let method = String(parts[0]).uppercased()
        var path = String(parts[1])
        if let queryIndex = path.firstIndex(of: "?") {
            path = String(path[..<queryIndex])
        }

        let bodyString = String(raw[separatorRange.upperBound...])
        var jsonBody: [String: Any]?
        if !bodyString.isEmpty, let bodyData = bodyString.data(using: .utf8) {
            jsonBody = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
        }

        var oidParam: UInt = 0
        let components = path.split(separator: "/").map(String.init)
        if components.count >= 2,
           (components[0] == "view" || components[0] == "objects"),
           let oid = UInt(components[1]) {
            oidParam = oid
        }

        return MCPHTTPRequest(method: method, path: path, jsonBody: jsonBody, oidParam: oidParam)
    }
}
#endif
