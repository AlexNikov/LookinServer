#if SHOULD_COMPILE_LOOKIN_SERVER

import Dispatch
import Foundation

final class LookinPTDispatchData: NSObject {
    let dispatchData: DispatchData

    init(dispatchData: DispatchData) {
        self.dispatchData = dispatchData
        super.init()
    }
}

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
