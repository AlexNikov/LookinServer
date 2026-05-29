#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation

/// Replaces `LKS_ConnectionManagerBootstrap.m` `+load` — starts Peertalk when the pod module links.
private enum LKS_ConnectionManagerBootstrap {
    static let activated: Void = {
        _ = LKS_ConnectionManager.bootstrap
        return ()
    }()
}

private let _lksConnectionManagerBootstrapToken: Void = LKS_ConnectionManagerBootstrap.activated

#endif
