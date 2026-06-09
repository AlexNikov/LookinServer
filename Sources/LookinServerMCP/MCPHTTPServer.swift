#if SHOULD_COMPILE_LOOKIN_SERVER
import Foundation
import Network

@objc(LKS_MCPHTTPServer)
@objcMembers
public final class MCPHTTPServer: NSObject {
    public static let shared = MCPHTTPServer()

    private let queue = DispatchQueue(label: "lookin.mcp.http")
    private var listener: NWListener?
    private let handler = MCPHTTPHandler()

    /// ObjC entry from `LKS_ConnectionManager` (`performSelector` passes `NSNumber`).
    @objc(startWithPort:)
    public func startWithPort(_ portNumber: NSNumber) {
        startListening(onPort: portNumber.uint16Value)
    }

    @nonobjc
    public func startListening(onPort port: UInt16 = 47190) {
        queue.async {
            guard self.listener == nil else { return }

            do {
                let params = NWParameters.tcp
                params.allowLocalEndpointReuse = true
                params.requiredInterfaceType = .loopback

                guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }
                let listener = try NWListener(using: params, on: nwPort)
                listener.newConnectionHandler = { [weak self] connection in
                    self?.handle(connection: connection)
                }
                listener.stateUpdateHandler = { state in
                    if case .failed(let error) = state {
                        NSLog("LookinServer - MCP HTTP listener failed: \(error.localizedDescription)")
                    }
                }
                listener.start(queue: self.queue)
                self.listener = listener
                NSLog("LookinServer - Swift MCP HTTP Server started on 127.0.0.1:\(port)")
            } catch {
                NSLog("LookinServer - Failed to start Swift MCP HTTP server: \(error.localizedDescription)")
            }
        }
    }

    public func stop() {
        queue.async {
            self.listener?.cancel()
            self.listener = nil
        }
    }

    private func handle(connection: NWConnection) {
        connection.start(queue: queue)
        Task { [weak self] in
            guard let self else {
                connection.cancel()
                return
            }
            guard let data = await self.receive(from: connection) else { return }
            guard let request = MCPHTTPRequestParser.parse(data) else {
                await self.send(response: .error(message: "Bad request", statusCode: 400), on: connection)
                return
            }
            let response = await self.handler.handle(request: request)
            await self.send(response: response, on: connection)
        }
    }

    private func receive(from connection: NWConnection) async -> Data? {
        await withCheckedContinuation { continuation in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 1_048_576) { data, _, _, error in
                if let data, error == nil {
                    continuation.resume(returning: data)
                } else {
                    connection.cancel()
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func send(response: MCPHTTPResponse, on connection: NWConnection) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let payload = response.httpData
            connection.send(content: payload, completion: .contentProcessed { _ in
                connection.cancel()
                continuation.resume()
            })
        }
    }
}
#endif
