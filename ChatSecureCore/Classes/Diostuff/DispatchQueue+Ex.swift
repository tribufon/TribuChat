//
//  DispatchQueue+Ex.swift
//  ChatSecureCore
//
//  Created by Lyubomir Marinov on 29.12.19.
//

import Foundation

public extension DispatchQueue {
    private static var _onceTracker = [String]()

    public class func once(file: String = #file,
                           function: String = #function,
                           line: Int = #line,
                           block: () -> Void) {
        let token = "\(file):\(function):\(line)"
        once(token: token, block: block)
    }
    
    private class func once(token: String,
                           block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard !_onceTracker.contains(token) else { return }

        _onceTracker.append(token)
        block()
    }
}
