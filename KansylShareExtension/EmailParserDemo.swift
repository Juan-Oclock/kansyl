//
//  EmailParserDemo.swift
//  KansylShareExtension
//
//  Created on 9/12/25.
//

import Foundation
import UniformTypeIdentifiers
import PDFKit
import Vision
import UIKit

class EmailParserDemo: ObservableObject {
    
    @Published var parsedData: EmailParser.ParsedTrialData?
    @Published var isProcessing = false
    @Published var error: Error?
    
    private let emailParser = EmailParser()
    private var lastError: Error?
    
    init() {
        print("🎆 [EmailParserDemo] Initializing EmailParserDemo")
    }
    
    // MARK: - Process Shared Content
    func processSharedContent(_ items: [NSExtensionItem]) {
        isProcessing = true
        error = nil
        lastError = nil
        parsedData = nil
        
        print("📥 [EmailParserDemo] Processing \(items.count) input items")
        
        // Flatten all NSItemProviders from the shared NSExtensionItems
        var providers: [NSItemProvider] = []
        for (itemIndex, item) in items.enumerated() {
            let userInfoKeys = item.userInfo?.keys.map { "\($0)" }.joined(separator: ", ") ?? "no userInfo"
            print("📦 [EmailParserDemo] Item \(itemIndex): \(userInfoKeys)")
            if let attachments = item.attachments, !attachments.isEmpty {
                print("📎 [EmailParserDemo] Found \(attachments.count) attachments in item \(itemIndex)")
                providers.append(contentsOf: attachments)
            } else {
                print("   No attachments in item \(itemIndex)")
            }
        }
        
        guard !providers.isEmpty else {
            self.error = NSError(domain: "EmailParser", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No supported content found in shared items"
            ])
            self.isProcessing = false
            return
        }
        
        // Process providers sequentially until we succeed or exhaust them
        processNextProvider(providers, index: 0)
    }
    
    private func processNextProvider(_ providers: [NSItemProvider], index: Int) {
        if index >= providers.count {
            // Finished without success
            DispatchQueue.main.async {
                if self.parsedData == nil {
                    self.error = self.lastError ?? NSError(
                        domain: "EmailParser",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Could not extract subscription information from the shared content"]
                    )
                }
                self.isProcessing = false
            }
            return
        }
        
        let provider = providers[index]
        let typeIdentifiers = provider.registeredTypeIdentifiers
        print("🔍 [EmailParserDemo] Provider types: \(typeIdentifiers.joined(separator: ", "))")
        
        // Try text → HTML → PDF → URL → generic, sequentially
        attemptText(provider) { [weak self] success in
            guard let self = self else { return }
            if success { self.isProcessing = false; return }
            self.attemptHTML(provider) { success in
                if success { self.isProcessing = false; return }
                self.attemptPDF(provider) { success in
                    if success { self.isProcessing = false; return }
                    self.attemptURL(provider) { success in
                        if success { self.isProcessing = false; return }
                        self.loadFirstAvailable(provider) { success in
                            if success { self.isProcessing = false; return }
                            // Try next provider
                            self.processNextProvider(providers, index: index + 1)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Generic Content Loader
    private func loadGenericContent(_ provider: NSItemProvider, typeIdentifier: String, completion: @escaping () -> Void) {
        print("🔄 [EmailParserDemo] Loading generic content with type: \\(typeIdentifier)")
        
        provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] (item, error) in
            DispatchQueue.main.async {
                defer { completion() }
                
                if let error = error {
                    print("❌ Error loading content: \(error)")
                    self?.lastError = error
                    return
                }
                
                // Try different ways to extract text from the content
                var extractedText: String?
                
                if let text = item as? String {
                    extractedText = text
                    print("✅ Got string content")
                } else if let data = item as? Data {
                    // Try as UTF-8 text
                    if let text = String(data: data, encoding: .utf8) {
                        extractedText = text
                        print("✅ Converted data to text")
                    } else if let text = String(data: data, encoding: .utf16) {
                        extractedText = text
                        print("✅ Converted data to text (UTF-16)")
                    }
                } else if let url = item as? URL {
                    // Try to read content from URL
                    if let text = try? String(contentsOf: url, encoding: .utf8) {
                        extractedText = text
                        print("✅ Read text from URL")
                    } else {
                        self?.parseURL(url)
                        return
                    }
                } else {
                    print("⚠️ Unknown item type: \(type(of: item))")
                }
                
                if let text = extractedText {
                    print("📧 Content preview: \(text.prefix(500))...")
                    self?.parseText(text)
                } else {
                    self?.lastError = NSError(domain: "EmailParser", code: 5, userInfo: [
                        NSLocalizedDescriptionKey: "Could not extract text from shared content"
                    ])
                }
            }
        }
    }
    
    // Try the first available registered type identifier when we don't recognize specific types
    private func loadFirstAvailable(_ provider: NSItemProvider, completion: @escaping (Bool) -> Void) {
        if let firstType = provider.registeredTypeIdentifiers.first {
            loadGenericContent(provider, typeIdentifier: firstType) {
                completion(self.parsedData?.isValid == true)
            }
        } else {
            completion(false)
        }
    }
    
    // MARK: - Attempt PDF
    private func attemptPDF(_ provider: NSItemProvider, completion: @escaping (Bool) -> Void) {
        let pdfIdentifier = provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier)
            ? UTType.pdf.identifier
            : "com.adobe.pdf"
        print("📄 Loading PDF content with identifier: \(pdfIdentifier)")
        
        provider.loadItem(forTypeIdentifier: pdfIdentifier, options: nil) { [weak self] (item, error) in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let self = self else { return }
                if let error = error {
                    DispatchQueue.main.async {
                        print("❌ Error loading PDF: \(error)")
                        self.lastError = error
                        completion(false)
                    }
                    return
                }
                
                var pdfData: Data?
                if let data = item as? Data {
                    pdfData = data
                } else if let url = item as? URL {
                    pdfData = try? Data(contentsOf: url)
                }
                
                guard let data = pdfData, let document = PDFDocument(data: data) else {
                    DispatchQueue.main.async {
                        print("❌ Could not read PDF data")
                        self.lastError = NSError(domain: "EmailParser", code: 6, userInfo: [NSLocalizedDescriptionKey: "Could not read PDF data"]) 
                        completion(false)
                    }
                    return
                }
                
                // 1) Try native text from PDF
                var fullText = ""
                for i in 0..<document.pageCount {
                    if let page = document.page(at: i), let text = page.string {
                        fullText.append(text)
                        fullText.append("\n")
                    }
                }
                
                // Heuristic: if native text is too small, use OCR fallback for first few pages
                let needsOCR = fullText.trimmingCharacters(in: .whitespacesAndNewlines).count < 60
                if needsOCR {
                    print("🔎 Running OCR fallback on PDF (first pages)...")
                    let maxPages = min(3, document.pageCount)
                    var ocrText = ""
                    for i in 0..<maxPages {
                        guard let page = document.page(at: i) else { continue }
                        let targetSize = CGSize(width: 1600, height: 2200)
                        let image = page.thumbnail(of: targetSize, for: .mediaBox)
                        if let cgImage = image.cgImage {
                            if let recognized = self.recognizeText(cgImage: cgImage) {
                                ocrText.append(recognized)
                                ocrText.append("\n")
                            }
                        }
                    }
                    fullText = ocrText.isEmpty ? fullText : ocrText
                }
                
                DispatchQueue.main.async {
                    if fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        print("⚠️ PDF had no extractable text (even after OCR)")
                        completion(false)
                        return
                    }
                    self.parseText(fullText)
                    completion(self.parsedData?.isValid == true)
                }
            }
        }
    }
    
    // OCR using Vision
    private func recognizeText(cgImage: CGImage) -> String? {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.minimumTextHeight = 0.02
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let lines: [String] = observations.compactMap { $0.topCandidates(1).first?.string }
            return lines.joined(separator: "\n")
        } catch {
            print("❌ OCR failed: \(error)")
            return nil
        }
    }
    
    // MARK: - Handle Text Content
    // MARK: - Attempt Text
    private func attemptText(_ provider: NSItemProvider, completion: @escaping (Bool) -> Void) {
        handleText(provider) {
            // Evaluate whether we parsed valid data
            completion(self.parsedData?.isValid == true)
        }
    }
    
    private func handleText(_ provider: NSItemProvider, completion: @escaping () -> Void = {}) {
        // Try to find the best type identifier
        let typeIdentifier: String
        if provider.hasItemConformingToTypeIdentifier("public.plain-text") {
            typeIdentifier = "public.plain-text"
        } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            typeIdentifier = UTType.plainText.identifier
        } else if let firstType = provider.registeredTypeIdentifiers.first {
            // Try the first available type
            typeIdentifier = firstType
        } else {
            typeIdentifier = UTType.plainText.identifier
        }
        
        print("📝 [EmailParserDemo] Loading text with identifier: \(typeIdentifier)")
        
        provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { [weak self] (item, error) in
            DispatchQueue.main.async {
                defer { completion() }
                
                if let text = item as? String {
                    print("✅ Loaded text (\(text.count) characters)")
                    print("📧 Text preview: \(text.prefix(500))...")
                    self?.parseText(text)
                } else if let data = item as? Data, let text = String(data: data, encoding: .utf8) {
                    print("✅ Loaded text from data (\(text.count) characters)")
                    print("📧 Text preview: \(text.prefix(500))...")
                    self?.parseText(text)
                } else if let url = item as? URL {
                    print("🔗 Got URL instead of text: \(url)")
                    if let text = try? String(contentsOf: url, encoding: .utf8) {
                        print("✅ Read text from URL (\(text.count) characters)")
                        self?.parseText(text)
                    } else {
                        self?.parseURL(url)
                    }
                } else if let error = error {
                    print("❌ Error loading text: \\(error)")
                    self?.lastError = error
                } else {
                    print("❌ No text content found, item type: \\(type(of: item))")
                    self?.lastError = NSError(domain: "EmailParser", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "Could not extract text content from shared item"
                    ])
                }
            }
        }
    }
    
    // MARK: - Attempt HTML
    private func attemptHTML(_ provider: NSItemProvider, completion: @escaping (Bool) -> Void) {
        handleHTML(provider) { completion(self.parsedData?.isValid == true) }
    }
    
    // MARK: - Handle URL Content
    private func handleURL(_ provider: NSItemProvider, completion: @escaping () -> Void = {}) {
        print("🔗 Loading URL content")
        
        let urlIdentifier = provider.hasItemConformingToTypeIdentifier(UTType.url.identifier)
            ? UTType.url.identifier
            : (provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) ? UTType.fileURL.identifier : UTType.url.identifier)
        
        provider.loadItem(forTypeIdentifier: urlIdentifier, options: nil) { [weak self] (item, error) in
            DispatchQueue.main.async {
                defer { completion() }
                
                if let url = item as? URL {
                    print("✅ Loaded URL: \(url)")
                    if url.isFileURL && url.pathExtension.lowercased() == "pdf" {
                        // Extract text from local PDF file
                        if let data = try? Data(contentsOf: url), let doc = PDFDocument(data: data) {
                            var text = ""
                            for i in 0..<doc.pageCount { if let page = doc.page(at: i), let t = page.string { text.append(t + "\n") } }
                            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                self?.parseText(text)
                            } else {
                                self?.lastError = NSError(domain: "EmailParser", code: 7, userInfo: [NSLocalizedDescriptionKey: "PDF contained no extractable text"])
                            }
                        } else {
                            self?.lastError = NSError(domain: "EmailParser", code: 6, userInfo: [NSLocalizedDescriptionKey: "Could not read PDF data"])
                        }
                    } else {
                        self?.parseURL(url)
                    }
                } else if let urlString = item as? String, let url = URL(string: urlString) {
                    print("✅ Loaded URL from string: \(url)")
                    self?.parseURL(url)
                } else if let error = error {
                    print("❌ Error loading URL: \\(error)")
                    self?.lastError = error
                } else {
                    print("❌ No URL content found")
                    self?.lastError = NSError(domain: "EmailParser", code: 3, userInfo: [
                        NSLocalizedDescriptionKey: "Could not extract URL content"
                    ])
                }
            }
        }
    }
    
    // MARK: - Attempt URL
    private func attemptURL(_ provider: NSItemProvider, completion: @escaping (Bool) -> Void) {
        handleURL(provider) { completion(self.parsedData?.isValid == true) }
    }
    
    // MARK: - Handle HTML Content
    private func handleHTML(_ provider: NSItemProvider, completion: @escaping () -> Void = {}) {
        print("🌐 Loading HTML content")
        
        let htmlIdentifier = provider.hasItemConformingToTypeIdentifier(UTType.html.identifier) 
            ? UTType.html.identifier 
            : "public.html"
        
        provider.loadItem(forTypeIdentifier: htmlIdentifier, options: nil) { [weak self] (item, error) in
            DispatchQueue.main.async {
                
                func parseHTMLData(_ data: Data) {
                    if let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .unicode) {
                        print("✅ Loaded HTML from data: \(html.prefix(200))...")
                        let text = self?.stripHTML(html) ?? ""
                        self?.parseText(text)
                    } else {
                        self?.lastError = NSError(domain: "EmailParser", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not decode HTML data"])
                    }
                }
                
                if let html = item as? String {
                    print("✅ Loaded HTML: \(html.prefix(200))...")
                    let text = self?.stripHTML(html) ?? ""
                    self?.parseText(text)
                    completion()
                } else if let data = item as? Data {
                    parseHTMLData(data)
                    completion()
                } else if let error = error {
                    print("⚠️ loadItem HTML failed: \(error). Trying loadDataRepresentation...")
                    // Fallback to data representation
                    (item as Any?); // keep compiler happy if item is unused
                    let providerCopy = provider
                    providerCopy.loadDataRepresentation(forTypeIdentifier: htmlIdentifier) { data, dataError in
                        DispatchQueue.main.async {
                            defer { completion() }
                            if let data = data {
                                parseHTMLData(data)
                            } else {
                                let e = dataError ?? error
                                print("❌ Error loading HTML data: \(String(describing: e))")
                                self?.lastError = e
                            }
                        }
                    }
                } else {
                    print("❌ No HTML content found")
                    self?.lastError = NSError(domain: "EmailParser", code: 4, userInfo: [
                        NSLocalizedDescriptionKey: "Could not extract HTML content"
                    ])
                    completion()
                }
            }
        }
    }
    
    // MARK: - Parse Methods
    private func parseText(_ text: String) {
        print("🔍 Parsing text for subscription info...")
        
        // First try the email parser
        parsedData = emailParser.parseEmail(text)
        
        // If parsing failed, try to extract basic info
        if parsedData?.isValid != true {
            print("⚠️ Email parser didn't find valid data, trying basic extraction...")
            parsedData = extractBasicInfo(from: text)
        }
        
        // Log what we found
        if let data = parsedData {
            print("🎯 Parsed data:")
            print("   Service: \(data.serviceName ?? "none")")
            print("   Duration: \(data.trialDuration ?? 0) days")
            print("   Price: \(data.price ?? 0)")
            print("   Valid: \(data.isValid)")
        } else {
            print("❌ No data could be parsed")
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
        let lowercasedText = text.lowercased()
        
        // Try to get a likely company from the top lines (helps for PDFs)
        let lines = text.split(separator: "\n").map(String.init)
        let topCandidates = lines.prefix(10)
        let blocked = Set(["receipt", "invoice", "summary", "thank you", "order", "purchase", "statement", "gbtattachmentcache", "attachment", "cache", "gmail", "google", "googleusercontent"]) 
        if data.serviceName == nil {
            for line in topCandidates {
                let clean = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard clean.count >= 3 else { continue }
                let lower = clean.lowercased()
                if blocked.contains(lower) { continue }
                if lower.range(of: "[a-z]", options: .regularExpression) != nil,
                   lower.range(of: "\n|\r", options: .regularExpression) == nil,
                   !lower.contains("receipt") && !lower.contains("invoice") {
                    // take first 3 words to avoid long headers
                    let candidate = clean.split(separator: " ").prefix(3).joined(separator: " ")
                    if candidate.count > 2 { data.serviceName = candidate }
                    break
                }
            }
        }
        
        // Expanded list of services
        let services = [
            "Netflix", "Spotify", "Disney+", "Disney Plus", "Amazon Prime", "Prime Video",
            "Apple TV+", "Apple Music", "Apple One", "iCloud", "Apple Fitness",
            "Hulu", "HBO Max", "HBO", "YouTube Premium", "YouTube TV", 
            "Paramount+", "Paramount Plus", "Peacock", "Discovery+", "Discovery Plus",
            "Audible", "Kindle Unlimited", "Xbox Game Pass", "PlayStation Plus",
            "Adobe", "Microsoft 365", "Office 365", "Dropbox", "Google One",
            "Duolingo", "Headspace", "Calm", "MasterClass", "Coursera",
            "LinkedIn Premium", "Medium", "New York Times", "Wall Street Journal"
        ]
        
        for service in services {
            if lowercasedText.contains(service.lowercased()) {
                data.serviceName = service
                break
            }
        }
        
        // If no specific service found, try to extract from common patterns
        if data.serviceName == nil {
            // Look for "Welcome to [Service]"
            if let range = lowercasedText.range(of: "welcome to ") {
                let afterWelcome = String(lowercasedText[range.upperBound...])
                if let firstWord = afterWelcome.split(separator: " ").first {
                    data.serviceName = String(firstWord).capitalized
                }
            }
            // Look for "subscription", "trial", "membership" patterns
            else if lowercasedText.contains("subscription") || 
                    lowercasedText.contains("trial") || 
                    lowercasedText.contains("membership") {
                // Extract the first capitalized word that might be a service name
                let words = text.split(separator: " ")
                for word in words {
                    let wordStr = String(word)
                    if wordStr.first?.isUppercase == true && wordStr.count > 3 {
                        data.serviceName = wordStr
                        break
                    }
                }
            }
        }
        
        // Enhanced duration detection
        let durationPatterns = [
            ("7 day", 7), ("seven day", 7), ("1 week", 7), ("one week", 7),
            ("14 day", 14), ("fourteen day", 14), ("2 week", 14), ("two week", 14),
            ("30 day", 30), ("thirty day", 30), ("1 month", 30), ("one month", 30),
            ("60 day", 60), ("sixty day", 60), ("2 month", 60), ("two month", 60),
            ("90 day", 90), ("ninety day", 90), ("3 month", 90), ("three month", 90),
            ("1 year", 365), ("one year", 365), ("annual", 365)
        ]
        
        for (pattern, days) in durationPatterns {
            if lowercasedText.contains(pattern) {
                data.trialDuration = days
                break
            }
        }
        
        // Try to extract price
        let pricePattern = "\\$([0-9]+\\.?[0-9]*)"
        if let regex = try? NSRegularExpression(pattern: pricePattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)),
           match.numberOfRanges > 1 {
            let range = match.range(at: 1)
            if let swiftRange = Range(range, in: text),
               let price = Double(text[swiftRange]) {
                data.price = price
                data.currency = "USD"
            }
        }
        
        // Default to today's date for start
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
