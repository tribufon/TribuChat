//
//  PincodeViewController.swift
//  ChatSecureCore
//
//  Created by Lyubomir Marinov on 23.02.20.
//

import UIKit

enum PincodeMode {
    case create
    case verify
    case check
    case remove
}

class PincodeViewController: UIViewController {
    
    @IBOutlet weak var pinDotsLabel: UILabel!
    @IBOutlet weak var pinDotsStackView: UIStackView!
    @IBOutlet weak var biometricsButton: UIButton!
    
    @IBOutlet weak var closeButton: UIButton!
    
    var pincodeMode: PincodeMode = .check
    
    var pinArray: [Int] = []
    var verifyPinArray: [Int] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        if pincodeMode != .check {
            biometricsButton.isHidden = true
        } else {
            if !PincodeManager.shared.isBiometricAuthenticationAvailable() {
                biometricsButton.isHidden = true
            }
            
            if !PincodeManager.shared.shouldUseBiometrics() {
                biometricsButton.isHidden = true
            }
        }
        
        redrawLabel()
        redrawDots()
        
//        UserDefaults.standard.set("1986", forKey: PincodeManager.Keys.pincode_key)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (pincodeMode == .check || pincodeMode == .remove) && !PincodeManager.shared.hasPin() {
            self.dismiss(animated: true, completion: {
                NotificationCenter.default.post(name: Notification.Name(rawValue: "reload_contents"), object: nil)
            })
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        PincodeManager.shared.isLocked = false
    }
    
    @IBAction func close() {
        self.dismiss(animated: true, completion: {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reload_contents"), object: nil)
        })
    }
    
    @IBAction func didTapPinButton(_ sender: UIButton) {
        defer {
            verifyPin()
        }
        guard sender.tag >= 0 else {
            if pincodeMode == .check || pincodeMode == .create || pincodeMode == .remove {
                if pinArray.count > 0 {
                    pinArray.removeLast(1)
                }
            } else {
                if verifyPinArray.count > 0 {
                    verifyPinArray.removeLast(1)
                }
            }
            return
        }
        
        if pincodeMode == .check || pincodeMode == .create || pincodeMode == .remove {
            pinArray.append(sender.tag)
        } else {
            verifyPinArray.append(sender.tag)
        }
    }
    
    @IBAction func didTapBiometrics() {
        PincodeManager.shared.authenticateUserWithBiometrics(success: {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "reload_contents"), object: nil)
                })
            }
        }) { error in
            print(error.getMessage())
        }
    }
    
    func verifyPin() {
        if pincodeMode == .check{
            if pinArray.count == 4 {
                let storedPin = (UserDefaults.standard.value(forKey: PincodeManager.Keys.pincode_key) as? String) ?? "no-pin-saved"
                
                if storedPin == digitsToPin() {
                    self.dismiss(animated: true, completion: {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "reload_contents"), object: nil)
                    })
                } else {
                    shake()
                    pinArray.removeAll()
                }
            }
        } else if pincodeMode == .create {
            if pinArray.count == 4 {
                pincodeMode = .verify
            }
        } else if pincodeMode == .remove {
            if pinArray.count == 4 {
                let storedPin = (UserDefaults.standard.value(forKey: PincodeManager.Keys.pincode_key) as? String) ?? "no-pin-saved"
                
                if storedPin == digitsToPin() {
                    PincodeManager.shared.removePin()
                    self.dismiss(animated: true, completion: {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "reload_contents"), object: nil)
                    })
                } else {
                    shake()
                    pinArray.removeAll()
                }
            }
        } else {
            if pinArray.count == 4 && verifyPinArray.count == 4 {
                if pinArray == verifyPinArray {
                    let pinToSave = digitsToPin(.create)
                    UserDefaults.standard.set(pinToSave, forKey: PincodeManager.Keys.pincode_key)
                    self.dismiss(animated: true, completion: {
                        NotificationCenter.default.post(name: Notification.Name(rawValue: "reload_contents"), object: nil)
                    })
                } else {
                    shake()
                    pinArray.removeAll()
                    verifyPinArray.removeAll()
                    
                    pincodeMode = .create
                }
            }
        }
        
        redrawLabel()
        redrawDots()
    }
    
    private func digitsToPin(_ mode: PincodeMode = .check) -> String {
        if mode == .check || mode == .create || mode == .remove {
            return pinArray.compactMap { "\($0)" }.joined(separator: "")
        } else {
            return verifyPinArray.compactMap { "\($0)" }.joined(separator: "")
        }
    }
    
    private func redrawLabel() {
        if pincodeMode == .check || pincodeMode == .remove {
            pinDotsLabel.text = "Enter your PIN"
        } else if pincodeMode == .create {
            pinDotsLabel.text = "Enter your new PIN"
        } else {
            pinDotsLabel.text = "Verify your new PIN"
        }
    }
    
    private func redrawDots() {
        pinDotsStackView.arrangedSubviews.forEach { subview in
            pinDotsStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        if pincodeMode == .check || pincodeMode == .create || pincodeMode == .remove {
            for index in 0 ..< 4 {
                if pinArray.count > index {
                    pinDotsStackView.addArrangedSubview(getPinDot(true))
                } else {
                    pinDotsStackView.addArrangedSubview(getPinDot(false))
                }
            }
        } else {
            for index in 0 ..< 4 {
                if verifyPinArray.count > index {
                    pinDotsStackView.addArrangedSubview(getPinDot(true))
                } else {
                    pinDotsStackView.addArrangedSubview(getPinDot(false))
                }
            }
        }
    }

    private func getPinDot(_ isDot: Bool) -> UIImageView {
        let bundle = Bundle(for: type(of: self))
        let image = isDot ? UIImage(named: "pincode-circle") : UIImage(named: "pincode-dash")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 16.0).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 24.0).isActive = true
        imageView.tintColor = .white
        return imageView
    }
    
    private func shake() {
        let translation = CAKeyframeAnimation(keyPath: "transform.translation.x");
        translation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        translation.values = [-7, 7, -7, 7, -5, 5, -5, 5, -3, 3, -2, 2, 0]

        let rotation = CAKeyframeAnimation(keyPath: "transform.rotation.y");
        rotation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)

        rotation.values = [-7, 7, -7, 7, -5, 5, -5, 5, -3, 3, -2, 2, 0].map {
            CGFloat(Double($0) / 180.0 * .pi)
        }
        let shakeGroup: CAAnimationGroup = CAAnimationGroup()
        shakeGroup.animations = [translation, rotation]
        shakeGroup.duration = 0.66
        self.pinDotsStackView.layer.add(shakeGroup, forKey: "shakeIt")
    }
}
