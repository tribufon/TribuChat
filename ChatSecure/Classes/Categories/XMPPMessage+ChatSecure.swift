//
//  XMPPMessage+ChatSecure.swift
//  ChatSecureCore
//
//  Created by Chris Ballinger on 10/18/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import Foundation

public class XMPPTimerManager: NSObject {
    
    @objc public static func setFireTime(_ messageID: String, time: Int) {
        var newVal: [String: Any] = [:]
        
        if let val = UserDefaults.standard.value(forKey: "XMPPFireTimerManager"), let dict = (val as? [String: Any]) {
            newVal = dict
        }
        
        newVal[messageID] = time
        
        UserDefaults.standard.set(newVal, forKey: "XMPPFireTimerManager")
        UserDefaults.standard.synchronize()
    }
    
    
    @objc public static func getFireTime(_ messageID: String) -> Int {
        if let val = UserDefaults.standard.value(forKey: "XMPPFireTimerManager"),
            let dict = (val as? [String: Any]),
            let res = (dict[messageID] as? Int)
        {
            return res
        }
        return 0
    }
    
    
    @objc public static func removeFireTime(_ messageID: String) {
        if let val = UserDefaults.standard.value(forKey: "XMPPFireTimerManager"), let dict = (val as? [String: Any]) {
            var newVal = dict
            newVal.removeValue(forKey: messageID)
            UserDefaults.standard.set(newVal, forKey: "XMPPFireTimerManager")
            UserDefaults.standard.synchronize()
        }
    }
}


extension XMPPMessage {
    /// Safely extracts XEP-0359 stanza-id
    @objc public func extractStanzaId(account: OTRXMPPAccount, capabilities: XMPPCapabilities) -> String? {
        let stanzaIds = self.stanzaIds
        guard stanzaIds.count > 0 else {
            return nil
        }
        if let myJID = account.bareJID,
            let sid = stanzaIds[myJID] {
            return sid
        }
        if let fromJID = self.from?.bareJID,
            let sid = stanzaIds[fromJID] {
            return sid
        }
        return nil
    }
}
