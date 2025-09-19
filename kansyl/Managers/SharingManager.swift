//
//  SharingManager.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI
import UIKit
import MessageUI

class SharingManager: NSObject, ObservableObject {
    static let shared = SharingManager()
    
    // MARK: - Share Achievements
    func shareAchievement(_ achievement: Achievement) -> ShareContent {
        let title = "🎉 Achievement Unlocked!"
        let message = """
        I just unlocked "\(achievement.title)" in Kansyl!
        
        \(achievement.description)
        
        Track your free trials and save money with Kansyl.
        Download: https://apps.apple.com/app/kansyl
        """
        
        let image = generateAchievementImage(achievement)
        
        return ShareContent(
            title: title,
            message: message,
            url: URL(string: "https://kansyl.app/achievement/\(achievement.id)"),
            image: image
        )
    }
    
    // MARK: - Share Savings
    func shareSavings(amount: Double, subscriptionsCount: Int) -> ShareContent {
        let title = "💰 I saved $\(String(format: "%.2f", amount)) with Kansyl!"
        let message = """
        I've successfully managed \(subscriptionsCount) subscriptions and saved $\(String(format: "%.2f", amount)) by canceling before charges!
        
        Never forget to cancel a subscription again.
        Join me on Kansyl: https://kansyl.app
        """
        
        let image = generateSavingsImage(amount: amount)
        
        return ShareContent(
            title: title,
            message: message,
            url: URL(string: "https://kansyl.app/savings"),
            image: image
        )
    }
    
    // MARK: - Export Subscription Data
    func exportSubscriptionData(_ subscriptions: [Subscription]) -> ShareContent {
        let csvContent = generateCSV(from: subscriptions)
        let jsonContent = generateJSON(from: subscriptions)
        
        // Save to temporary files
        let csvURL = saveToTempFile(csvContent, filename: "kansyl_subscriptions.csv")
        let jsonURL = saveToTempFile(jsonContent, filename: "kansyl_subscriptions.json")
        
        let message = """
        My Kansyl subscription data export
        
        Total subscriptions: \(subscriptions.count)
        Active subscriptions: \(subscriptions.filter { $0.status == SubscriptionStatus.active.rawValue }.count)
        """
        
        return ShareContent(
            title: "Kansyl Subscription Data Export",
            message: message,
            url: csvURL,
            additionalURLs: [jsonURL].compactMap { $0 }
        )
    }
    
    // MARK: - Share Referral
    func shareReferral(referralCode: String? = nil) -> ShareContent {
        let code = referralCode ?? generateReferralCode()
        let title = "Try Kansyl - Never forget to cancel subscriptions!"
        let message = """
        I use Kansyl to track all my subscriptions and it's saved me from unwanted charges!
        
        🎁 Use my referral code "\(code)" for 1 month of Premium features FREE!
        
        Features:
        • Smart reminders before subscriptions end
        • Track unlimited subscriptions
        • See your savings grow
        • Siri Shortcuts support
        
        Download now: https://kansyl.app/refer/\(code)
        """
        
        return ShareContent(
            title: title,
            message: message,
            url: URL(string: "https://kansyl.app/refer/\(code)")
        )
    }
    
    // MARK: - Share Subscription Warning
    func shareSubscriptionWarning(_ subscription: Subscription) -> ShareContent {
        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: subscription.endDate ?? Date()).day ?? 0
        let title = "⚠️ Subscription ending soon!"
        let message = """
        My \(subscription.name ?? "subscription") is ending in \(daysRemaining) days.
        
        Monthly cost after trial: $\(String(format: "%.2f", subscription.monthlyPrice))
        
        Tracking with Kansyl to avoid unwanted charges.
        Get it here: https://kansyl.app
        """
        
        return ShareContent(
            title: title,
            message: message,
            url: URL(string: "https://kansyl.app")
        )
    }
    
    // MARK: - Helper Methods
    private func generateCSV(from subscriptions: [Subscription]) -> String {
        var csv = "Service,Start Date,End Date,Status,Monthly Price,Notes\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for subscription in subscriptions {
            let name = subscription.name ?? ""
            let startDate = subscription.startDate.map { dateFormatter.string(from: $0) } ?? ""
            let endDate = subscription.endDate.map { dateFormatter.string(from: $0) } ?? ""
            let status = subscription.status ?? ""
            let price = String(format: "%.2f", subscription.monthlyPrice)
            let notes = subscription.notes ?? ""
            
            csv += "\"\(name)\",\"\(startDate)\",\"\(endDate)\",\"\(status)\",\"\(price)\",\"\(notes)\"\n"
        }
        
        return csv
    }
    
    private func generateJSON(from subscriptions: [Subscription]) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let exportData = subscriptions.map { subscription in
            [
                "id": subscription.id?.uuidString ?? "",
                "name": subscription.name ?? "",
                "startDate": ISO8601DateFormatter().string(from: subscription.startDate ?? Date()),
                "endDate": ISO8601DateFormatter().string(from: subscription.endDate ?? Date()),
                "status": subscription.status ?? "",
                "monthlyPrice": String(subscription.monthlyPrice),
                "notes": subscription.notes ?? ""
            ]
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return "[]"
    }
    
    private func saveToTempFile(_ content: String, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            // Debug: print("Error saving temp file: \(error)")
            return nil
        }
    }
    
    private func generateReferralCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
    
    private func generateAchievementImage(_ achievement: Achievement) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200))
        
        return renderer.image { context in
            // Background
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 200))
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.white
            ]
            
            let title = achievement.title
            let titleSize = title.size(withAttributes: titleAttributes)
            let titleRect = CGRect(
                x: (400 - titleSize.width) / 2,
                y: 80,
                width: titleSize.width,
                height: titleSize.height
            )
            title.draw(in: titleRect, withAttributes: titleAttributes)
            
            // Icon
            if let icon = UIImage(systemName: achievement.icon) {
                icon.draw(in: CGRect(x: 175, y: 20, width: 50, height: 50))
            }
        }
    }
    
    private func generateSavingsImage(amount: Double) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 200))
        
        return renderer.image { context in
            // Background gradient
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [UIColor.systemGreen.cgColor, UIColor.systemTeal.cgColor] as CFArray,
                locations: [0, 1]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 400, y: 200),
                options: []
            )
            
            // Amount text
            let amountAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 48),
                .foregroundColor: UIColor.white
            ]
            
            let amountText = "$\(String(format: "%.2f", amount))"
            let amountSize = amountText.size(withAttributes: amountAttributes)
            let amountRect = CGRect(
                x: (400 - amountSize.width) / 2,
                y: 60,
                width: amountSize.width,
                height: amountSize.height
            )
            amountText.draw(in: amountRect, withAttributes: amountAttributes)
            
            // Saved text
            let savedAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            
            let savedText = "SAVED WITH KANSYL"
            let savedSize = savedText.size(withAttributes: savedAttributes)
            let savedRect = CGRect(
                x: (400 - savedSize.width) / 2,
                y: 130,
                width: savedSize.width,
                height: savedSize.height
            )
            savedText.draw(in: savedRect, withAttributes: savedAttributes)
        }
    }
}

// MARK: - Share Content Model
struct ShareContent {
    let title: String
    let message: String
    let url: URL?
    var image: UIImage? = nil
    var additionalURLs: [URL] = []
    
    func present(from viewController: UIViewController) {
        var items: [Any] = [message]
        
        if let url = url {
            items.append(url)
        }
        
        if let image = image {
            items.append(image)
        }
        
        items.append(contentsOf: additionalURLs)
        
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // Exclude certain activities
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]
        
        // For iPad
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityVC, animated: true)
    }
}

// MARK: - SwiftUI Share Sheet Wrapper
struct SharingSheet: UIViewControllerRepresentable {
    let shareContent: ShareContent
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        var items: [Any] = [shareContent.message]
        
        if let url = shareContent.url {
            items.append(url)
        }
        
        if let image = shareContent.image {
            items.append(image)
        }
        
        items.append(contentsOf: shareContent.additionalURLs)
        
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
