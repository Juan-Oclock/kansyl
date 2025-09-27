import Foundation
import AuthenticationServices
import UIKit

/// Helper class to provide presentation context for ASWebAuthenticationSession
class AuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    private weak var rootViewController: UIViewController?
    
    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        super.init()
    }
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Try to get the topmost view controller
        var topViewController = rootViewController
        
        while let presented = topViewController?.presentedViewController {
            topViewController = presented
        }
        
        // Return the window of the topmost view controller
        return topViewController?.view.window ?? ASPresentationAnchor()
    }
}