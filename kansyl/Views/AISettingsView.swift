//
//  AISettingsView.swift
//  kansyl
//
//  AI settings configuration view
//

import SwiftUI

struct AISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @StateObject private var configManager = AIConfigManager.shared
    @State private var apiKey: String = ""
    @State private var showingAPIKeyInfo = false
    @State private var isTestingConnection = false
    @State private var testResult: String? = nil
    @State private var showingTestAlert = false
    @FocusState private var isAPIKeyFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                aiSettingsHeader
                
                // Settings content
                ScrollView {
                    VStack(spacing: 24) {
                        // AI Receipt Scanning Section
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(title: "AI Receipt Scanning", icon: "camera.viewfinder")
                            
                            VStack(spacing: 12) {
                                infoCard(
                                    title: "Automatic Detection",
                                    description: "Scan receipts to automatically detect subscription services, prices, and billing dates using AI.",
                                    icon: "sparkles"
                                )
                                
                                // API Key Configuration
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("DeepSeek API Key")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(Design.Colors.textPrimary)
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            showingAPIKeyInfo = true
                                        }) {
                                            Image(systemName: "info.circle")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(Design.Colors.textSecondary)
                                        }
                                    }
                                    
                                    SecureField("Enter your DeepSeek API key", text: $apiKey)
                                        .font(.system(size: 15, weight: .regular))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Design.Colors.surfaceSecondary)
                                        .cornerRadius(8)
                                        .focused($isAPIKeyFocused)
                                        .onChange(of: apiKey) { newValue in
                                            configManager.deepSeekAPIKey = newValue.isEmpty ? nil : newValue
                                        }
                                    
                                    if configManager.isAIEnabled {
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.green)
                                            
                                            Text("AI scanning enabled")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.green)
                                        }
                                    } else {
                                        HStack(spacing: 6) {
                                            Image(systemName: "exclamationmark.circle.fill")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.orange)
                                            
                                            Text("API key required for AI scanning")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                                
                                // Test connection button
                                if !apiKey.isEmpty {
                                    Button(action: testConnection) {
                                        HStack(spacing: 8) {
                                            if isTestingConnection {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                    .foregroundColor(.white)
                                            } else {
                                                Image(systemName: "network")
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            
                                            Text(isTestingConnection ? "Testing..." : "Test Connection")
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Design.Colors.primary)
                                        .cornerRadius(8)
                                    }
                                    .disabled(isTestingConnection)
                                }
                            }
                            .padding(16)
                            .background(Design.Colors.surface)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Privacy & Security Section
                        VStack(alignment: .leading, spacing: 16) {
                            sectionHeader(title: "Privacy & Security", icon: "lock.shield")
                            
                            VStack(spacing: 12) {
                                privacyInfoCard(
                                    title: "Secure Storage",
                                    description: "Your API key is stored securely in the device keychain and never shared.",
                                    icon: "key.fill"
                                )
                                
                                privacyInfoCard(
                                    title: "Data Processing",
                                    description: "Receipt images are processed locally. Only text content is sent to AI services for analysis.",
                                    icon: "eye.slash.fill"
                                )
                                
                                privacyInfoCard(
                                    title: "No Data Retention",
                                    description: "DeepSeek does not store or train on data sent via API calls for improved privacy.",
                                    icon: "trash.fill"
                                )
                            }
                            .padding(16)
                            .background(Design.Colors.surface)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
            }
            .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
        }
        .sheet(isPresented: $showingAPIKeyInfo) {
            APIKeyInfoSheet(isPresented: $showingAPIKeyInfo)
        }
        .alert("Connection Test", isPresented: $showingTestAlert) {
            Button("OK") {}
        } message: {
            Text(testResult ?? "")
        }
        .onAppear {
            apiKey = configManager.deepSeekAPIKey ?? ""
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isAPIKeyFocused = false
                }
                .font(.system(size: 17, weight: .regular))
                .foregroundColor(Design.Colors.primary)
            }
        }
    }
    
    // MARK: - Header
    private var aiSettingsHeader: some View {
        HStack {
            Button("Close") {
                dismiss()
            }
            .font(.system(size: 17, weight: .regular))
            .foregroundColor(Design.Colors.primary)
            
            Spacer()
            
            Text("AI Settings")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Design.Colors.textPrimary)
            
            Spacer()
            
            // Invisible placeholder for symmetry
            Text("Close")
                .font(.system(size: 17, weight: .regular))
                .opacity(0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(colorScheme == .dark ? Color(hex: "252525") : Design.Colors.surface)
    }
    
    // MARK: - Section Header
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Design.Colors.primary)
            
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Design.Colors.textPrimary)
            
            Spacer()
        }
    }
    
    // MARK: - Info Card
    private func infoCard(title: String, description: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Design.Colors.primary.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Design.Colors.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Design.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Design.Colors.surfaceSecondary.opacity(0.5))
        .cornerRadius(8)
    }
    
    // MARK: - Privacy Info Card
    private func privacyInfoCard(title: String, description: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Design.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.green.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Test Connection
    private func testConnection() {
        isTestingConnection = true
        
        Task {
            do {
                let testService = AIAnalysisService()
                let testText = "Test connection - Netflix $15.99 monthly subscription"
                let _ = try await testService.analyzeReceiptText(testText)
                
                DispatchQueue.main.async {
                    self.testResult = "Connection successful! AI receipt scanning is ready to use."
                    self.isTestingConnection = false
                    self.showingTestAlert = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.testResult = "Connection failed: \(error.localizedDescription)"
                    self.isTestingConnection = false
                    self.showingTestAlert = true
                }
            }
        }
    }
}

// MARK: - API Key Info Sheet
struct APIKeyInfoSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to Get Your DeepSeek API Key")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Design.Colors.textPrimary)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        stepItem(number: 1, title: "Visit DeepSeek Platform", description: "Go to platform.deepseek.com and sign up or log in to your account.")
                        
                        stepItem(number: 2, title: "Navigate to API Keys", description: "Go to the API Keys section in your account dashboard.")
                        
                        stepItem(number: 3, title: "Create New Key", description: "Click 'Create API Key' and give it a name like 'Kansyl Receipt Scanning'.")
                        
                        stepItem(number: 4, title: "Copy and Paste", description: "Copy the generated API key and paste it into the field above. Keep it secure!")
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Important Notes")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Design.Colors.textPrimary)
                        
                        noteItem(text: "API usage incurs charges based on DeepSeek's pricing (very affordable)")
                        noteItem(text: "Receipt scanning uses minimal tokens (~50-100 per scan, ~$0.001 per scan)")
                        noteItem(text: "Your API key is stored securely on your device")
                        noteItem(text: "You can disable AI features at any time")
                    }
                    .padding(16)
                    .background(Design.Colors.surfaceSecondary.opacity(0.5))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(colorScheme == .dark ? Color(hex: "191919") : Design.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Design.Colors.primary)
                }
            }
        }
    }
    
    private func stepItem(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Design.Colors.primary)
                    .frame(width: 24, height: 24)
                
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Design.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
    
    private func noteItem(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Design.Colors.textSecondary)
                .frame(width: 4, height: 4)
                .padding(.top, 6)
            
            Text(text)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Design.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}