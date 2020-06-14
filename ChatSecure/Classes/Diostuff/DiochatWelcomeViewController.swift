//
//  DiochatWelcomeViewController.swift
//  ChatSecureCore
//
//  Created by Lyubomir Marinov on 29.12.19.
//

import UIKit
import MaterialComponents
import QRCodeReaderViewController

class DiochatWelcomeViewController: OTRBaseLoginViewController {
    
    @IBOutlet weak var nameTextField: MDCTextField!
    @IBOutlet weak var passwordTextField: MDCTextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var qrButton: UIButton!
    @IBOutlet weak var qrScanLabel: UILabel!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate let placeholderColor = UIColor.init(white: 200.0/255.0, alpha: 0.8)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loginHandler = OTRXMPPLoginHandler()

        self.tableView.isHidden = true

        let placeholderAttributes = [
            NSAttributedString.Key.foregroundColor: placeholderColor,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)
        ]
        self.nameTextField.attributedPlaceholder = NSAttributedString(string: "Username", attributes: placeholderAttributes)
        self.nameTextField.textColor = .white
        self.nameTextField.placeholderLabel.textColor = placeholderColor
        self.nameTextField.tag = 1
        self.nameTextField.returnKeyType = .next
        self.nameTextField.enablesReturnKeyAutomatically = true
        self.nameTextField.delegate = self
        self.nameTextField.keyboardType = .emailAddress
        
        self.passwordTextField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: placeholderAttributes)
        self.passwordTextField.textColor = .white
        self.passwordTextField.placeholderLabel.textColor = placeholderColor
        self.passwordTextField.tag = 2
        self.passwordTextField.returnKeyType = .go
        self.passwordTextField.enablesReturnKeyAutomatically = true
        self.passwordTextField.delegate = self

        self.qrScanLabel.textAlignment = .center;
        self.qrScanLabel.textColor = UIColor.white
        self.qrScanLabel.font = UIFont.boldSystemFont(ofSize: 13.0)
        self.qrScanLabel.text = "Scan QR"
        
        self.loginButton.addTarget(self, action: #selector(loginAction), for: .touchUpInside)
        
        self.qrButton.addTarget(self, action: #selector(qrCodeScan), for: .touchUpInside)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    @objc private func loginAction() {
        processFormLogin(self.nameTextField.text, password: self.passwordTextField.text)
    }
    
    @objc private func qrCodeScan() {
        if QRCodeReader.supportsMetadataObjectTypes([AVMetadataObject.ObjectType.qr]) {
            var qrViewController: QRCodeReaderViewController?
            
            let reader = QRCodeReader.init(metadataObjectTypes: [AVMetadataObject.ObjectType.qr])
            qrViewController = QRCodeReaderViewController(cancelButtonTitle: "Close",
                                                          codeReader: reader,
                                                          startScanningAtLoad: true,
                                                          showSwitchCameraButton: false,
                                                          showTorchButton: false)
            qrViewController?.delegate = self
            qrViewController?.modalPresentationStyle = .overFullScreen
            
            if qrViewController != nil {
                self.present(qrViewController!, animated: true, completion: nil)
            }
        } else {
            let alert = UIAlertController(title: "Error", message: "QR Reader not supported by current device", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func processQRLogin(_ value: String?) {
        guard let _value = value,
            let components = _value.removingPercentEncoding?.components(separatedBy: ":"),
            components.count >= 3 else { return }
        let username = components[1].appending("@xmpp1.diomerc.com")
        let password = components[2].replacingOccurrences(of: "@Diomerc", with: "")
        
        processFormLogin(username, password: password)
    }
    
    private func processFormLogin(_ username: String?, password: String?) {
        guard let _username = username,
            !_username.isEmpty,
            let _password = password,
            !_password.isEmpty else { return }
        
        print("{\"username\": \(_username), \"password\": \(_password) }")
        
        guard let account = OTRXMPPAccount(username: "", accountType: .jabber) else { return }
        
        var jidNode = ""
        var jidDomain = ""
        let usernameComponents = _username.components(separatedBy: "@")
        if usernameComponents.count == 2 {
            jidNode = usernameComponents.first ?? ""
            jidDomain = usernameComponents.last ?? ""
        } else {
            jidNode = _username
        }
        
        account.rememberPassword = true
        account.password = _password
        account.autologin = true
        account.domain = "xmpp1.diomerc.com"
        account.port = OTRXMPPAccount.defaultPort()
        account.resource = OTRXMPPAccount.newResource()
        account.disableAutomaticURLFetching = false

        if jidDomain.isEmpty {
            jidDomain = "xmpp1.diomerc.com"
        }
        
        guard let jid = XMPPJID(user: jidNode, domain: jidDomain, resource: account.resource) else { return }
        
        account.username = jid.bare
        if let jidResource = jid.resource {
            account.resource = jidResource
        }
        account.displayName = jidNode
        
        OTRProtocolManager.encryptionManager.otrKit.generatePrivateKey(forAccountName: account.username, protocol: kOTRProtocolTypeXMPP) { [weak self] fingerprint, error in

            if fingerprint != nil {
                print("Fingerprint for '\(jid.bare)': \(fingerprint?.description)")
            } else {
                print("Error is: \(error?.localizedDescription ?? "Unknown")")
            }
        }
        
        self.account = account
        
        self.loginHandler.performAction(withValidForm: nil, account: account, progress: { (progress, summary) in
            print("Progress: \(progress/100)")
        }) { (_account, error) in
            if error != nil {
                OTRDatabaseManager.shared.uiConnection?.read({ transaction in
                    if let account = _account {
                        if transaction.object(forKey: account.uniqueId, inCollection: OTRAccount.collection) != nil {
                            try? account.removeKeychainPassword()
                        }
                    }
                })
                
                self.handleError(error!)
            } else {
                self.handleSuccess(withNewAccount: account, sender: self.loginButton)
            }
        }
    }
    
    override func handleSuccess(withNewAccount account: OTRAccount, sender: Any) {
        OTRDatabaseManager.shared.writeConnection?.readWrite({ transaction in
            account.save(with: transaction)
        })
        
        self.view.endEditing(true)
        PushController.registerForPushNotifications()
        self.navigationController?.dismiss(animated: true) {
            
        }
    }
}

extension DiochatWelcomeViewController {
    override func textFieldDidBeginEditing(_ textField: UITextField) {
        super.textFieldDidBeginEditing(textField)
        if let clearButton = textField.value(forKey: "_clearButton") as? UIButton {
            if let templateImage = clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate) {
                clearButton.setImage(templateImage, for: .normal)
                clearButton.tintColor = placeholderColor
            }
        }
    }
    
    override func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        // Try to find next responder
        let nextResponder = textField.superview?.viewWithTag(nextTag) as? UIResponder

        if nextResponder != nil {
            // Found next responder, so set it
            nextResponder?.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard
            textField.resignFirstResponder()
        }

        return false
    }
}

extension DiochatWelcomeViewController: QRCodeReaderDelegate {
    func reader(_ reader: QRCodeReaderViewController!, didScanResult result: String!) {
        reader.stopScanning()
        reader.dismiss(animated: true, completion: nil)
        
        processQRLogin(result)
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController!) {
        reader.dismiss(animated: true, completion: nil)
    }
}
