#if SHOULD_COMPILE_LOOKIN_SERVER

import Foundation

#if (os(iOS) && !swift(>=5.0)) || (os(macOS) && !swift(>=5.0))
let ptDispatchRetainRelease = true
#else
let ptDispatchRetainRelease = false
#endif

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
