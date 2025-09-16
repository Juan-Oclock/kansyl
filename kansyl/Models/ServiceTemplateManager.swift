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
            print("Error checking service templates: \(error)")
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
            print("Loaded \(templates.count) service templates")
        } catch {
            print("Error saving service templates: \(error)")
        }
    }
    
    // Fetch all templates from Core Data
    func fetchTemplates(context: NSManagedObjectContext) -> [ServiceTemplate] {
        let request: NSFetchRequest<ServiceTemplate> = ServiceTemplate.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceTemplate.name, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching service templates: \(error)")
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
}
