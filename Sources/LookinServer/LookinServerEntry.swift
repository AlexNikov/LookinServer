
#if os(iOS) || os(tvOS) || os(visionOS)
/// Triggers `LKS_ConnectionManager` bootstrap when the LookinServer product module loads.
private let _lookinServerProductBootstrap = LKS_ConnectionManager.bootstrap
#endif

public enum LookinServerEntry {}
