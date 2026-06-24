#if canImport(LookinShared)
import LookinShared
#endif
#if os(iOS) || os(tvOS) || os(visionOS)
/// Triggers `LKS_ConnectionManager` bootstrap when the LookinServer product module loads.
private let _lookinServerProductBootstrap = LKS_ConnectionManager.bootstrap
#if LOOKIN_SERVER_MCP
/// Compile-time anchor for subspec MCP — keeps `LKS_MCPHTTPServer` in the app binary
/// (`ConnectionManager` starts it via `NSClassFromString`).
private let _lookinMCPEntry = MCPHTTPServer.self
#endif
#endif

/// Reference `LookinServerEntry.self` in AppDelegate (Debug) to load LookinServer + MCP.
public enum LookinServerEntry {}
