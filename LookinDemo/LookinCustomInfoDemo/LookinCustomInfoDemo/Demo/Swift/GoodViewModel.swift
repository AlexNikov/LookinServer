//
//  GoodViewModel.swift
//  LookinCustomInfoDemo
//
//  Maintained by Cursor Agent.
//

import Foundation

class GoodViewModel {
    var viewModelTargetView: UIView?
    
    init() {
        NotificationCenter.default.post(name: .init("Lookin_RelationSearch"), object: self)
    }
}
