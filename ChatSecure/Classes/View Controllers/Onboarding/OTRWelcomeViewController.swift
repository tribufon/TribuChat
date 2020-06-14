//
//  OTRWelcomeViewController.swift
//  ChatSecure
//
//  Created by Christopher Ballinger on 8/6/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

import UIKit
import OTRAssets

open class OTRWelcomeViewController: UIViewController {
    
    // MARK: - Views
    @IBOutlet var logoImageView: UIImageView?
    @IBOutlet var createAccountButton: UIButton?
    @IBOutlet var existingAccountButton: UIButton?
    @IBOutlet var skipButton: UIButton?
    
    // MARK: - View Lifecycle
    
    override open func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
//        self.performSegue(withIdentifier: "diochat", sender: nil)
        /*
         Multiple commands produce '/Users/lyubomir.marinov/Library/Developer/Xcode/DerivedData/ChatSecure-gmveotxtafgadjgtluaqvxxwvjmp/Build/Products/Debug-iphonesimulator/Diofon.app/Assets.car':
         1) Target 'ChatSecure' (project 'ChatSecure') has compile command with input '/Users/lyubomir.marinov/Documents/Projects/ChatSecure-iOS/ChatSecure/Resources/Images.xcassets'
         2) That command depends on command in Target 'ChatSecure' (project 'ChatSecure'): script phase “[CP] Copy Pods Resources”

         */
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        self.createAccountButton?.setTitle(CREATE_NEW_ACCOUNT_STRING(), for: .normal)
        self.skipButton?.setTitle(SKIP_STRING(), for: .normal)
        self.existingAccountButton?.setTitle(ADD_EXISTING_STRING(), for: .normal)
        
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation

    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let loginVC = segue.destination as? OTRBaseLoginViewController else {
            return
        }
        if segue.identifier == "createNewAccountSegue" {
            loginVC.form = XLFormDescriptor.registerNewAccountForm(with: .jabber)
            loginVC.loginHandler = OTRXMPPCreateAccountHandler()
        } else if segue.identifier == "addExistingAccount" {
            loginVC.form = XLFormDescriptor.existingAccountForm(with: .jabber)
            loginVC.loginHandler = OTRXMPPLoginHandler()
        }
    }
    
    @IBAction func skipButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
