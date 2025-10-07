//
//  ShareViewController.swift
//  KansylShareExtension
//
//  Created by Juan Oclock on 9/26/25.
//

import UIKit
import SwiftUI

@objc(ShareViewController)
class ShareViewController: UIViewController {
    private var hostingController: UIHostingController<ShareExtensionView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("🎤 [ShareViewController] viewDidLoad called")
        
        // Get input items first
        let inputItems = extensionContext?.inputItems as? [NSExtensionItem] ?? []
        print("📎 [ShareViewController] Found \(inputItems.count) input items")
        
        for (index, item) in inputItems.enumerated() {
            print("   Item \(index): \(item.attachments?.count ?? 0) attachments")
            if let attachments = item.attachments {
                for (attachIndex, attachment) in attachments.enumerated() {
                    print("      Attachment \(attachIndex): \(attachment.registeredTypeIdentifiers)")
                }
            }
        }
        
        // Create the SwiftUI view with proper callbacks and input items
        let shareView = ShareExtensionView(
            inputItems: inputItems,
            extensionContext: extensionContext,
            onComplete: {
                // Extension completed successfully
                self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            },
            onCancel: {
                // User cancelled the extension
                self.extensionContext?.cancelRequest(withError: NSError(domain: "ShareExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "User cancelled"]))
            }
        )
        
        // Create hosting controller
        hostingController = UIHostingController(rootView: shareView)
        guard let hostingController = hostingController else { return }
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Set up constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
}
