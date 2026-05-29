//
//  CALayer+Custom.swift
//  LookinCustomInfoDemo
//
//  Maintained by Cursor Agent.
//

import UIKit

extension CALayer {
    /// Implement this method to expose custom properties in Lookin
    /// Check whether a parent, child, or category already implements this method. To avoid conflicts, rename it to lookin_customDebugInfos_0 (the trailing 0 may be 0–5).
    /// Lookin calls this on every refresh; keep it fast to avoid slowing down inspection.
    ///
    /// Implement this method to display custom properties in Lookin.
    /// Please note if this method has already been implemented by the superclass, subclass, or category. If so, to avoid conflicts, you can rename this method to lookin_customDebugInfos_0 (the trailing number 0 can be replaced with any number from 0 to 5).
    /// This method is called every time Lookin refreshes, so if this method takes a long time to execute, it will slow down the refresh speed.
    ///
    /// https://bytedance.feishu.cn/docx/TRridRXeUoErMTxs94bcnGchnlb
    @objc func lookin_customDebugInfos_1() -> [String:Any]? {
        let ret: [String:Any] = [
            "properties": self.cusotm_makeCustomProperties()
        ]
        return ret
    }
    
    private func cusotm_makeCustomProperties() -> [Any] {
        let stringProperty: [String:Any] = [
            "section": "Life Style",
            "title": "Hobby",
            "value": "Bike",
            "valueType": "string"
        ]
        
        return [stringProperty]
    }
}
