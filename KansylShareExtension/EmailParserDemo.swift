//
//  EmailParserDemo.swift
//  KansylShareExtension
//
//  Created on 9/12/25.
//

import Foundation
import UniformTypeIdentifiers

class EmailParserDemo: ObservableObject {
    
    @Published var parsedData: EmailParser.ParsedTrialData?
    @Published var isProcessing = false
    @Published var error: Error?
    
    private let emailParser = EmailParser()
    
    init() {
        print("🎆 [EmailParserDemo] Initializing EmailParserDemo")
    }
    
    // MARK: - Process Shared Content
    func processSharedContent(_ items: [NSExtensionItem]) {
        isProcessing = true
        error = nil
        
        print("📥 Processing \(items.count) input items")
        
        var foundContent = false
        
        for item in items {
            guard let attachments = item.attachments else { continue }
            
            print("📎 Found \(attachments.count) attachments")
            
            for provider in attachments {
                print("🔍 Checking provider: \(provider.registeredTypeIdentifiers)")
                
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    foundContent = true
                    handleText(provider)
                } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    foundContent = true
                    handleURL(provider)
                } else if provider.hasItemConformingToTypeIdentifier(UTType.html.identifier) {
                    foundContent = true
                    handleHTML(provider)
                } else if provider.hasItemConformingToTypeIdentifier("public.plain-text") {
                    // Fallback to older identifier
                    foundContent = true
                    handleText(provider)
                }
            }
        }
        
        // If no content was found, stop processing with an error
        if !foundContent {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.error = NSError(domain: "EmailParser", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "No supported content found in shared items"
                ])
                self.isProcessing = false
            }
        }
    }
    
    // MARK: - Handle Text Content
    private func handleText(_ provider: NSItemProvider) {
        // Try both new and old type identifiers
        let typeIdentifier = provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) 
            ? UTType.plainText.identifier 
            : "public.plain-text"
        
        print("📝 Loading text with identifier: \(typeIdentifier)")
        
        provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] (item, error) in
            DispatchQueue.main.async {
                defer { self?.isProcessing = false }
                
                if let text = item as? String {
                    print("✅ Loaded text: \(text.prefix(100))...")
                    self?.parseText(text)
                } else if let error = error {
                    print("❌ Error loading text: \(error)")
                    self?.error = error
                } else {
                    print("❌ No text content found")
                    self?.error = NSError(domain: "EmailParser", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "Could not extract text content"
                    ])
                }
            }
        }
    }
    
    // MARK: - Handle URL Content
    private func handleURL(_ provider: NSItemProvider) {
        print("🔗 Loading URL content")
        
        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
            DispatchQueue.main.async {
                defer { self?.isProcessing = false }
                
                if let url = item as? URL {
                    print("✅ Loaded URL: \(url)")
                    self?.parseURL(url)
                } else if let error = error {
                    print("❌ Error loading URL: \(error)")
                    self?.error = error
                } else {
                    print("❌ No URL content found")
                    self?.error = NSError(domain: "EmailParser", code: 3, userInfo: [
                        NSLocalizedDescriptionKey: "Could not extract URL content"
                    ])
                }
            }
        }
    }
    
    // MARK: - Handle HTML Content
    private func handleHTML(_ provider: NSItemProvider) {
        print("🌐 Loading HTML content")
        
        provider.loadItem(forTypeIdentifier: UTType.html.identifier, options: nil) { [weak self] (item, error) in
            DispatchQueue.main.async {
                defer { self?.isProcessing = false }
                
                if let html = item as? String {
                    print("✅ Loaded HTML: \(html.prefix(100))...")
                    // Strip HTML tags and parse as text
                    let text = self?.stripHTML(html) ?? ""
                    self?.parseText(text)
                } else if let error = error {
                    print("❌ Error loading HTML: \(error)")
                    self?.error = error
                } else {
                    print("❌ No HTML content found")
                    self?.error = NSError(domain: "EmailParser", code: 4, userInfo: [
                        NSLocalizedDescriptionKey: "Could not extract HTML content"
                    ])
                }
            }
        }
    }
    
    // MARK: - Parse Methods
    private func parseText(_ text: String) {
        parsedData = emailParser.parseEmail(text)
        
        // If parsing failed, try to extract basic info
        if parsedData?.isValid != true {
            parsedData = extractBasicInfo(from: text)
        }
    }
    
    private func parseURL(_ url: URL) {
        // First try to parse from URL
        if let data = emailParser.parseFromURL(url) {
            parsedData = data
            return
        }
        
        // For now, just parse the URL string itself
        // In a full implementation, you might fetch content, but that would require
        // careful async handling to not leave isProcessing = true
        parseText(url.absoluteString)
    }
    
    // MARK: - Helper Methods
    private func stripHTML(_ html: String) -> String {
        let pattern = "<[^>]+>"
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: html.utf16.count)
        let text = regex?.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "") ?? html
        return text
    }
    
    private func extractBasicInfo(from text: String) -> EmailParser.ParsedTrialData {
        var data = EmailParser.ParsedTrialData()
        
        // Try to find any service name
        let services = ["Netflix", "Spotify", "Disney+", "Amazon Prime", "Apple TV+", "Hulu", "HBO Max", "YouTube Premium"]
        for service in services {
            if text.lowercased().contains(service.lowercased()) {
                data.serviceName = service
                break
            }
        }
        
        // Try to find any duration
        if text.contains("7 day") {
            data.trialDuration = 7
        } else if text.contains("14 day") {
            data.trialDuration = 14
        } else if text.contains("30 day") || text.contains("month") {
            data.trialDuration = 30
        }
        
        // Default to today's date
        data.startDate = Date()
        if let duration = data.trialDuration {
            data.endDate = Calendar.current.date(byAdding: .day, value: duration, to: Date())
        }
        
        return data
    }
    
    private func fetchContent(from url: URL) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                if let data = data, let content = String(data: data, encoding: .utf8) {
                    self?.parseText(content)
                } else if let error = error {
                    self?.error = error
                }
                self?.isProcessing = false
            }
        }
        task.resume()
    }
    
    // MARK: - Debug/Recovery Methods
    func forceStopProcessing() {
        print("⚙️ [EmailParserDemo] Force stopping processing")
        isProcessing = false
        if error == nil {
            error = NSError(domain: "EmailParser", code: 999, userInfo: [
                NSLocalizedDescriptionKey: "Processing timed out. This might be due to unsupported content format."
            ])
        }
    }
}
