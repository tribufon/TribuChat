//
//  SingleToggleTableViewCell.swift
//  ChatSecure
//
//  Created by Chris Ballinger on 2/14/17.
//  Copyright © 2017 Chris Ballinger. All rights reserved.
//

import UIKit

@objc(SingleToggleTableViewCell)
public class SingleToggleTableViewCell: UITableViewCell {

    @IBOutlet public weak var toggle: UISwitch!
    public var toggleAction: ((_ cell: SingleToggleTableViewCell, _ sender: UISwitch) -> ())?

    public class func cellIdentifier() -> String {
        return "SingleToggleTableViewCell"
    }
    
    @IBAction private func valueChanged(_ sender: UISwitch) {
        guard let action = toggleAction else { return }
        action(self, sender)
    }
}
