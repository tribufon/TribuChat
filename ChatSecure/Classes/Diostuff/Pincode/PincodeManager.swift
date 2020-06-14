//
//  PincodeManager.swift
//  ChatSecureCore
//
//  Created by Lyubomir Marinov on 23.02.20.
//

import Foundation
import LocalAuthentication

// success block
public typealias AuthenticationSuccess = (() -> ())

// failure block
public typealias AuthenticationFailure = ((AuthError) -> ())

public enum AuthError {
    
    case appCancel, failed, userCancel, userFallback, systemCancel, passcodeNotSet, biometryNotEnrolled, biometryLockedout, invalidContext , biometryNotAvailable,other
    
    public static func errorType(_ error: LAError) -> AuthError {
        switch Int32(error.errorCode) {
            
        case kLAErrorAuthenticationFailed:
            return .failed
        case kLAErrorUserCancel:
            return .userCancel
        case kLAErrorUserFallback:
            return .userFallback
        case kLAErrorSystemCancel:
            return .systemCancel
        case kLAErrorPasscodeNotSet:
            return .passcodeNotSet
        case kLAErrorBiometryNotEnrolled:
            return .biometryNotEnrolled
        case kLAErrorBiometryLockout:
            return .biometryLockedout
        case kLAErrorAppCancel:
            return .appCancel
        case kLAErrorInvalidContext:
            return .invalidContext
        case kLAErrorBiometryNotAvailable:
            return .biometryNotAvailable
        default:
            return .other
        }
    }
    
    // get error message based on type
    public func getMessage() -> String {
        switch self {
        case .appCancel:
            return "Authentication was cancelled by application."
        case .failed:
            return "The user failed to provide valid credentials."
        case .invalidContext:
            return "The context is invalid."
        case .userFallback:
            return "The user chose to use the fallback."
        case .userCancel:
            return "The user did cancel."
        case .passcodeNotSet:
            return "Passcode is not set on the device."
        case .systemCancel:
            return "Authentication was cancelled by the system."
        case .biometryNotEnrolled:
            return "Biometric is not enrolled on the device."
        case .biometryLockedout:
            return "Too many failed attempts."
        case .biometryNotAvailable:
            return "Biometric is not available on the device."
        case .other:
            return "Did not find error code on LAError object."
        }
    }
}

public enum DefaultMessages : String {
    case defaultReasonMessage = "Authentication is needed to access your app."
    case lockoutReasonMessage = "Too many failed attempts."
}

@objc public class PincodeManager: NSObject {
    
    public struct Keys {
        static let pincode_key = "com.diomerc.diofon.pincode_value"
        static let disableBiometrics_key = "com.diomerc.diofon.disableBiometrics_value"
    }
    
    fileprivate let localAuthenticationContext = LAContext()
    
    lazy var blurBackground: UIImageView = {
        let imageView = UIImageView(frame: UIScreen.main.bounds)
        imageView.image = UIImage(named: "welcome_background")
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    var completionUponClose: (() -> ())?
    
    var isLocked = false
    
    @objc public static let shared = PincodeManager()
    
    @objc public func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didFinishLaunching), name: UIApplication.didFinishLaunchingNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc public func willResignActive() {
        UIApplication.shared.keyWindow?.addSubview(blurBackground)
    }
    
    @objc public func didBecomeActive() {
        if let _ = (UIApplication.shared.keyWindow?.subviews ?? []).firstIndex(where: { $0 == blurBackground }) {
            blurBackground.removeFromSuperview()
            lock()
        }
    }
    
    @objc public func didFinishLaunching() {
        lock()
    }
    
    @objc public func hasPin() -> Bool {
        guard let pin = UserDefaults.standard.value(forKey: PincodeManager.Keys.pincode_key) as? String else {
            return false
        }
        return pin.count == 4
    }
    
    public func lock() {
        guard OTRAccountsManager.allAccounts().count > 0 else {
            // No account added
            return
        }
        
        guard hasPin() else {
            // No pin is stored
            return
        }
        
        showPinScreen(.check)
    }
    
    public func removePin() {
        UserDefaults.standard.removeObject(forKey: PincodeManager.Keys.pincode_key)
    }
    
    public func createPin() {
        showPinScreen(.create)
    }
    
    public func willRemovePin() {
        showPinScreen(.remove)
    }
    
    func showPinScreen(_ mode: PincodeMode) {
        guard !isLocked else {
            // Lock screen already visible
            return
        }
        guard let keyWindow = UIApplication.shared.keyWindow else {
            // No key window?
            return
        }
        
        guard let topMostViewController = keyWindow.visibleViewController else {
            // No top most view controller
            return
        }
        let storyboard = UIStoryboard(name: "Pincode", bundle: Bundle.otrAssets)
        guard let pincodeViewController = UIStoryboard(name: "Pincode", bundle: Bundle.otrAssets)
            .instantiateViewController(withIdentifier: "PincodeViewController") as? PincodeViewController else {
            // Unable to instantiate pincode view controller
            return
        }
        
        pincodeViewController.pincodeMode = mode
        pincodeViewController.modalTransitionStyle = .crossDissolve
        pincodeViewController.modalPresentationStyle = .overFullScreen
        DispatchQueue.main.async {
            self.isLocked = true
            topMostViewController.present(pincodeViewController, animated: false, completion: {
                pincodeViewController.closeButton.isHidden = mode != .remove
            })
        }
    }
}

extension PincodeManager {
    
    // checks if Biometric Authentication is available on the device.
    public func isBiometricAuthenticationAvailable() -> Bool {
        var error: NSError? = nil
        
        if localAuthenticationContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return (error == nil)
        }
        return false
    }
    
    public func shouldUseBiometrics() -> Bool {
        guard let hasSetting = UserDefaults.standard.value(forKey: PincodeManager.Keys.disableBiometrics_key) as? Int else {
            return false
        }
        
        return true
    }
    
    // Biometric authentication
    public func authenticateUserWithBiometrics(reason: String = "", fallbackTitle: String? = "", cancelTitle: String? = "", success successBlock:@escaping AuthenticationSuccess, failure failureBlock:@escaping AuthenticationFailure) {
        let reasonString = reason.isEmpty ? defaultBiometricAuthenticationReason() : reason
        
        localAuthenticationContext.localizedFallbackTitle = fallbackTitle
        if #available(iOS 10.0, *) {
            localAuthenticationContext.localizedCancelTitle = cancelTitle
        } else {
            // Fallback on earlier versions
        }
        
        // evaluate policy
        evaluate(policy: LAPolicy.deviceOwnerAuthenticationWithBiometrics, with: localAuthenticationContext, reason: reasonString, success: successBlock, failure: failureBlock)
    }
    
    // Passcode authentication
    public func authenticateUserWithPasscode(reason: String = "", cancelTitle: String? = "", success successBlock:@escaping AuthenticationSuccess, failure failureBlock:@escaping AuthenticationFailure) {
        let reasonString = reason.isEmpty ? defaultPasscodeAuthenticationReason() : reason
        
        if #available(iOS 10.0, *) {
            localAuthenticationContext.localizedCancelTitle = cancelTitle
        } else {
            // Fallback on earlier versions
        }
        
        // evaluate policy
        evaluate(policy: LAPolicy.deviceOwnerAuthentication, with: localAuthenticationContext, reason: reasonString, success: successBlock, failure: failureBlock)
    }
    
    // checks if Face ID is avaiable on device
    public func isFaceIDAvailable() -> Bool {
        if #available(iOS 11.0, *) {
            return (localAuthenticationContext.biometryType == .faceID)
        }
        return false
    }
    
    @objc public func enableDisableBiometrics(_ isEnabled: Bool) {
        if isEnabled {
            UserDefaults.standard.removeObject(forKey: PincodeManager.Keys.disableBiometrics_key)
        } else {
            UserDefaults.standard.set(1, forKey: PincodeManager.Keys.disableBiometrics_key)
        }
    }
}

// MARK:- evaluate policy
extension PincodeManager {
   
    public func evaluate(policy: LAPolicy, with context: LAContext, reason: String, success successBlock:@escaping AuthenticationSuccess, failure failureBlock: @escaping AuthenticationFailure) {
        
        context.evaluatePolicy(policy, localizedReason: reason) { (success, err) in
            if success { successBlock() }
            else {
                let errorType = AuthError.errorType(err as! LAError)
                failureBlock(errorType)
            }
        }
    }
}

// MARK:- Get default messages
extension PincodeManager {
    // get default bio authentication reason
    public func defaultBiometricAuthenticationReason() -> String {
        return DefaultMessages.defaultReasonMessage.rawValue
    }
    
    // get reason after too many failed attempts.
    public func defaultPasscodeAuthenticationReason() -> String {
        return DefaultMessages.lockoutReasonMessage.rawValue
    }
}

// MARK: - UIWindow extension
public extension UIWindow {
    var visibleViewController: UIViewController? {
        return UIWindow.visibleVC(vc: self.rootViewController)
    }

    static func visibleVC(vc: UIViewController?) -> UIViewController? {
        if let navigationViewController = vc as? UINavigationController {
            return UIWindow.visibleVC(vc: navigationViewController.visibleViewController)
        } else if let tabBarVC = vc as? UITabBarController {
            return UIWindow.visibleVC(vc: tabBarVC.selectedViewController)
        } else {
            if let presentedVC = vc?.presentedViewController, !presentedVC.isKind(of: PincodeViewController.self) {
                return UIWindow.visibleVC(vc: presentedVC)
            } else {
                return vc
            }
        }
    }
    
    @available(iOS 10.0, *)
    var visibleBlur: UIImage? {
        let renderer = UIGraphicsImageRenderer(size: UIScreen.main.bounds.size)
        guard let viewController = visibleViewController else {
            return nil
        }
        let image = renderer.image { ctx in
            viewController.view.drawHierarchy(in: UIScreen.main.bounds, afterScreenUpdates: true)
        }
        
        let blurredImage = addBlurTo(image)
        return addBlurTo(image)
    }
    
    private func addBlurTo(_ image: UIImage) -> UIImage {
        guard let ciImg = CIImage(image: image) else { return image }
        let blur = CIFilter(name: "CIGaussianBlur")
        blur?.setValue(ciImg, forKey: kCIInputImageKey)
        blur?.setValue(10.0, forKey: kCIInputRadiusKey)
        if let outputImg = blur?.outputImage {
            return UIImage(ciImage: outputImg)
        }
        return image
    }
}

public extension Bundle {
    public static var otrAssets: Bundle? {
        let folderName = "/OTRResources.bundle"
        guard let bundlePath = Bundle.main.resourcePath?.appending(folderName),
            let dataBUndle = Bundle(path: bundlePath) else {
            return nil
        }
        return dataBUndle
    }
}
