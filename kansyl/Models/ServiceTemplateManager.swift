//
//  ServiceTemplateManager.swift
//  kansyl
//
//  Created on 9/12/25.
//

import Foundation
import CoreData
import SwiftUI

struct ServiceTemplateData {
    let name: String
    let defaultSubscriptionLength: Int16 // in days
    let logoName: String // SF Symbol name
    let monthlyPrice: Double
    let category: String
    let brandColor: Color
}

class ServiceTemplateManager {
    static let shared = ServiceTemplateManager()
    
    // Popular service templates with realistic pricing
    let templates: [ServiceTemplateData] = [
        // Streaming Services
        ServiceTemplateData(
            name: "Netflix",
            defaultSubscriptionLength: 30,
            logoName: "netflix",
            monthlyPrice: 15.49,
            category: "Streaming",
            brandColor: Color(red: 229/255, green: 9/255, blue: 20/255)
        ),
        ServiceTemplateData(
            name: "YouTube",
            defaultSubscriptionLength: 30,
            logoName: "youtube",
            monthlyPrice: 13.99,
            category: "Streaming",
            brandColor: Color(red: 255/255, green: 0/255, blue: 0/255)
        ),
        ServiceTemplateData(
            name: "Spotify",
            defaultSubscriptionLength: 30,
            logoName: "spotify",
            monthlyPrice: 11.99,
            category: "Music",
            brandColor: Color(red: 30/255, green: 215/255, blue: 96/255)
        ),
        ServiceTemplateData(
            name: "Apple Music",
            defaultSubscriptionLength: 90,
            logoName: "apple",
            monthlyPrice: 10.99,
            category: "Music",
            brandColor: Color(red: 252/255, green: 69/255, blue: 117/255)
        ),
        ServiceTemplateData(
            name: "HBO Max",
            defaultSubscriptionLength: 7,
            logoName: "hbo",
            monthlyPrice: 15.99,
            category: "Streaming",
            brandColor: Color(red: 90/255, green: 31/255, blue: 219/255)
        ),
        ServiceTemplateData(
            name: "Apple TV+",
            defaultSubscriptionLength: 7,
            logoName: "appletv",
            monthlyPrice: 6.99,
            category: "Streaming",
            brandColor: Color.black
        ),
        
        // Productivity & Software
        ServiceTemplateData(
            name: "Notion",
            defaultSubscriptionLength: 30,
            logoName: "notion",
            monthlyPrice: 10.00,
            category: "Productivity",
            brandColor: Color.black
        ),
        ServiceTemplateData(
            name: "Dropbox Plus",
            defaultSubscriptionLength: 30,
            logoName: "dropbox",
            monthlyPrice: 11.99,
            category: "Storage",
            brandColor: Color(red: 0/255, green: 97/255, blue: 255/255)
        ),
        ServiceTemplateData(
            name: "Google One",
            defaultSubscriptionLength: 30,
            logoName: "google",
            monthlyPrice: 1.99,
            category: "Storage",
            brandColor: Color(red: 66/255, green: 133/255, blue: 244/255)
        ),
        ServiceTemplateData(
            name: "iCloud+",
            defaultSubscriptionLength: 30,
            logoName: "icloud",
            monthlyPrice: 0.99,
            category: "Storage",
            brandColor: Color(red: 0/255, green: 122/255, blue: 255/255)
        ),
        
        // Communication & Social
        ServiceTemplateData(
            name: "Discord Nitro",
            defaultSubscriptionLength: 30,
            logoName: "discord",
            monthlyPrice: 9.99,
            category: "Social",
            brandColor: Color(red: 88/255, green: 101/255, blue: 242/255)
        ),
        ServiceTemplateData(
            name: "Slack Pro",
            defaultSubscriptionLength: 30,
            logoName: "slack",
            monthlyPrice: 6.67,
            category: "Business",
            brandColor: Color(red: 74/255, green: 21/255, blue: 75/255)
        ),
        ServiceTemplateData(
            name: "Zoom Pro",
            defaultSubscriptionLength: 30,
            logoName: "zoom",
            monthlyPrice: 14.99,
            category: "Business",
            brandColor: Color(red: 45/255, green: 140/255, blue: 255/255)
        ),
        
        // Fitness & Wellness
        ServiceTemplateData(
            name: "Peloton App",
            defaultSubscriptionLength: 30,
            logoName: "peloton",
            monthlyPrice: 12.99,
            category: "Fitness",
            brandColor: Color(red: 223/255, green: 13/255, blue: 54/255)
        ),
        ServiceTemplateData(
            name: "Headspace",
            defaultSubscriptionLength: 14,
            logoName: "headspace",
            monthlyPrice: 12.99,
            category: "Wellness",
            brandColor: Color(red: 255/255, green: 135/255, blue: 86/255)
        ),
        
        // Gaming & Entertainment
        ServiceTemplateData(
            name: "PlayStation Plus",
            defaultSubscriptionLength: 7,
            logoName: "playstation",
            monthlyPrice: 11.99,
            category: "Gaming",
            brandColor: Color(red: 0/255, green: 55/255, blue: 145/255)
        ),
        ServiceTemplateData(
            name: "Twitch Turbo",
            defaultSubscriptionLength: 30,
            logoName: "twitch",
            monthlyPrice: 8.99,
            category: "Gaming",
            brandColor: Color(red: 169/255, green: 112/255, blue: 255/255)
        ),
        
        // AI & Tech Services
        ServiceTemplateData(
            name: "OpenAI Plus",
            defaultSubscriptionLength: 30,
            logoName: "openai",
            monthlyPrice: 20.00,
            category: "AI",
            brandColor: Color.black
        ),
        ServiceTemplateData(
            name: "Claude Pro",
            defaultSubscriptionLength: 30,
            logoName: "claude",
            monthlyPrice: 20.00,
            category: "AI",
            brandColor: Color(red: 255/255, green: 165/255, blue: 0/255)
        ),
        
        // Social Media Premium
        ServiceTemplateData(
            name: "X",
            defaultSubscriptionLength: 30,
            logoName: "x",
            monthlyPrice: 8.00,
            category: "Social",
            brandColor: Color.black
        ),
        ServiceTemplateData(
            name: "Instagram+",
            defaultSubscriptionLength: 30,
            logoName: "instagram",
            monthlyPrice: 4.99,
            category: "Social",
            brandColor: Color(red: 225/255, green: 48/255, blue: 108/255)
        )
    ]
    
    private init() {}
    
    // Load templates into Core Data if not already present
    func loadTemplatesIfNeeded(context: NSManagedObjectContext) {
        let request: NSFetchRequest<ServiceTemplate> = ServiceTemplate.fetchRequest()
        
        do {
            let count = try context.count(for: request)
            if count == 0 {
                loadTemplates(context: context)
            }
        } catch {
            // Debug: print("Error checking service templates: \(error)")
        }
    }
    
    private func loadTemplates(context: NSManagedObjectContext) {
        for template in templates {
            let serviceTemplate = ServiceTemplate(context: context)
            serviceTemplate.id = UUID()
            serviceTemplate.name = template.name
            serviceTemplate.defaultSubscriptionLength = template.defaultSubscriptionLength
            serviceTemplate.logoName = template.logoName
            serviceTemplate.monthlyPrice = template.monthlyPrice
        }
        
        do {
            try context.save()
            // Debug: print("Loaded \(templates.count) service templates")
        } catch {
            // Debug: print("Error saving service templates: \(error)")
        }
    }
    
    // Fetch all templates from Core Data
    func fetchTemplates(context: NSManagedObjectContext) -> [ServiceTemplate] {
        let request: NSFetchRequest<ServiceTemplate> = ServiceTemplate.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceTemplate.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            // Debug: print("Error fetching service templates: \(error)")
            return []
        }
    }
    
    // Get template data by name
    func getTemplateData(for name: String) -> ServiceTemplateData? {
        return templates.first { $0.name == name }
    }
    
    // Get categories
    var categories: [String] {
        Array(Set(templates.map { $0.category })).sorted()
    }
    
    // Get templates by category
    func templates(for category: String) -> [ServiceTemplateData] {
        templates.filter { $0.category == category }
    }
    
    // MARK: - AI-Enhanced Service Matching
    
    /// Find the best matching service template for a given service name
    /// This uses fuzzy matching and common variations to improve AI receipt scanning accuracy
    func findBestMatch(for serviceName: String, confidence threshold: Float = 0.7) -> ServiceTemplateData? {
        let searchName = serviceName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // First try exact match
        if let exactMatch = templates.first(where: { $0.name.lowercased() == searchName }) {
            return exactMatch
        }
        
        // Try fuzzy matching with known variations
        for template in templates {
            if let match = fuzzyMatch(searchName: searchName, template: template) {
                return match
            }
        }
        
        // Try substring matching
        for template in templates {
            let templateName = template.name.lowercased()
            if templateName.contains(searchName) || searchName.contains(templateName) {
                return template
            }
        }
        
        return nil
    }
    
    private func fuzzyMatch(searchName: String, template: ServiceTemplateData) -> ServiceTemplateData? {
        let templateName = template.name.lowercased()
        
        // Define known variations and common misspellings
        let variations: [String: [String]] = [
            "netflix": ["netflx", "net flix", "netflix inc", "netflix.com"],
            "spotify": ["spotify premium", "spotify music", "spotify.com", "spotify inc"],
            "youtube": ["youtube premium", "youtube music", "yt premium", "youtube.com", "google youtube"],
            "apple music": ["apple", "itunes", "apple.com/music", "music app"],
            "hbo max": ["hbo", "hbomax", "hbo streaming", "warner bros"],
            "apple tv+": ["apple tv", "appletv", "apple tv plus", "tv.apple.com"],
            "disney+": ["disney", "disney plus", "disneyplus", "walt disney"],
            "amazon prime": ["amazon", "prime", "amazon.com", "prime video"],
            "notion": ["notion.so", "notion labs"],
            "dropbox plus": ["dropbox", "dropbox.com"],
            "google one": ["google", "google drive", "google.com"],
            "icloud+": ["icloud", "apple icloud", "cloud storage"],
            "discord nitro": ["discord", "discord.com"],
            "slack pro": ["slack", "slack.com"],
            "zoom pro": ["zoom", "zoom.us", "zoom meeting"],
            "peloton app": ["peloton", "peloton.com"],
            "headspace": ["headspace.com", "headspace meditation"],
            "playstation plus": ["playstation", "ps plus", "sony playstation"],
            "twitch turbo": ["twitch", "twitch.tv"],
            "openai plus": ["openai", "chatgpt", "chat gpt", "openai.com"],
            "claude pro": ["claude", "anthropic", "claude ai"],
            "x": ["twitter", "twitter.com", "x.com"],
            "instagram+": ["instagram", "ig", "instagram.com"]
        ]
        
        // Check if the template has variations defined
        if let templateVariations = variations[templateName] {
            for variation in templateVariations {
                if searchName.contains(variation) || variation.contains(searchName) {
                    return template
                }
            }
        }
        
        return nil
    }
    
    /// Get suggested templates based on AI-detected service information
    func getSuggestions(for receiptData: Any) -> [ServiceTemplateData] {
        // This could be expanded to analyze receipt patterns and suggest likely services
        // For now, return popular streaming and productivity services
        return templates.filter { template in
            ["Streaming", "Music", "Productivity", "AI"].contains(template.category)
        }.prefix(6).map { $0 }
    }
    
    /// Validate and enhance AI-detected service information
    func validateAndEnhance(serviceName: String, amount: Double?) -> (template: ServiceTemplateData?, confidence: Float) {
        guard let template = findBestMatch(for: serviceName) else {
            return (nil, 0.0)
        }
        
        var confidence: Float = 0.8 // Base confidence for template match
        
        // Adjust confidence based on price matching
        if let detectedAmount = amount {
            let priceDifference = abs(detectedAmount - template.monthlyPrice)
            let priceVariance = priceDifference / template.monthlyPrice
            
            if priceVariance <= 0.1 { // Within 10%
                confidence += 0.15
            } else if priceVariance <= 0.3 { // Within 30%
                confidence += 0.05
            } else if priceVariance > 0.5 { // More than 50% difference
                confidence -= 0.2
            }
        }
        
        // Cap confidence at 1.0
        confidence = min(confidence, 1.0)
        
        return (template, confidence)
    }
}
