#if canImport(LookinShared)
import LookinShared
#endif
#if SHOULD_COMPILE_LOOKIN_SERVER

import UIKit

extension UITableView {
    @objc(lks_numberOfRows)
    public func lks_numberOfRows() -> [NSNumber]? {
        let sectionsCount = UInt(min(numberOfSections, 10))
        let rowsCount = NSArray.lookin_arrayWithCount(sectionsCount) { idx in
            NSNumber(value: self.numberOfRows(inSection: Int(idx)))
        }
        return rowsCount.count > 0 ? (rowsCount as? [NSNumber]) : nil
    }
}

#endif
