//
//  CurrencySettingsView.swift
//  kansyl
//
//  Comprehensive currency selection with location-based recommendations
//

import SwiftUI

struct CurrencySettingsView: View {
    @ObservedObject private var userPreferences = UserSpecificPreferences.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var showingLocationDetection = false
    
    private var filteredCurrencies: [CurrencyInfo] {
        let allCurrencies = CurrencyManager.supportedCurrencies  // Use all supported currencies directly
        
        if searchText.isEmpty {
            return CurrencyManager.shared.getRegionalCurrencies()  // Return regional order when not searching
        } else {
            var filtered = allCurrencies.filter { currency in
                currency.name.localizedCaseInsensitiveContains(searchText) ||
                currency.code.localizedCaseInsensitiveContains(searchText) ||
                currency.symbol.localizedCaseInsensitiveContains(searchText)
            }
            
            // Put USD first if it matches the search
            if let usdIndex = filtered.firstIndex(where: { $0.code == "USD" }), usdIndex != 0 {
                let usd = filtered.remove(at: usdIndex)
                filtered.insert(usd, at: 0)
            }
            
            return filtered
        }
    }
    
    private var regionalCurrencies: [CurrencyInfo] {
        var currencies = Array(CurrencyManager.shared.getRegionalCurrencies().prefix(8))
        
        // Ensure USD is always first if it's in the list
        if let usdIndex = currencies.firstIndex(where: { $0.code == "USD" }), usdIndex != 0 {
            let usd = currencies.remove(at: usdIndex)
            currencies.insert(usd, at: 0)
        }
        
        print("🔧 [CurrencySettings] Regional currencies in order:")
        for (index, currency) in currencies.enumerated() {
            print("  \(index): \(currency.code) - \(currency.name)")
        }
        return currencies
    }
    
    var body: some View {
        NavigationView {
            List {
                if searchText.isEmpty {
                    // Location-based detection section
                    Section {
                        Button(action: {
                            detectAndSetCurrency()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Auto-detect Currency")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    if let detectedCurrency = CurrencyManager.shared.detectCurrencyFromLocation() {
                                        Text("Detected: \(detectedCurrency.name) (\(detectedCurrency.symbol))")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Based on your location")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    } header: {
                        Text("Quick Setup")
                    } footer: {
                        Text("Automatically detect your currency based on your device's region")
                    }
                    
                    // Popular currencies for your region
                    Section {
                        ForEach(regionalCurrencies, id: \.code) { currency in
                            CurrencyRow(
                                currency: currency,
                                isSelected: currency.code == userPreferences.currencyCode,
                                onSelect: {
                                    selectCurrency(currency)
                                }
                            )
                        }
                    } header: {
                        Text("Popular in Your Region")
                    }
                }
                
                // All currencies or search results
                Section {
                    ForEach(searchText.isEmpty ? 
                           filteredCurrencies.filter { currency in 
                               !regionalCurrencies.contains(where: { $0.code == currency.code })
                           } : 
                           filteredCurrencies, id: \.code) { currency in
                        CurrencyRow(
                            currency: currency,
                            isSelected: currency.code == userPreferences.currencyCode,
                            onSelect: {
                                selectCurrency(currency)
                            }
                        )
                    }
                } header: {
                    Text(searchText.isEmpty ? "Other Currencies" : "Search Results")
                }
            }
            .searchable(text: $searchText, prompt: "Search currencies...")
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Ensure we have a user context for saving preferences
                userPreferences.ensureUserContext()
                print("🔧 [CurrencySettings] View appeared, ensuring user context")
            }
        }
    }
    
    private func selectCurrency(_ currency: CurrencyInfo) {
        print("🔧 [CurrencySettings] selectCurrency called with: \(currency.code) (\(currency.name))")
        print("🔧 [CurrencySettings] Current currency before change: \(userPreferences.currencyCode)")
        
        withAnimation(.easeInOut(duration: 0.2)) {
            userPreferences.currencyCode = currency.code
            print("🔧 [CurrencySettings] Currency set to: \(userPreferences.currencyCode)")
            HapticManager.shared.selection()
        }
        
        print("🔧 [CurrencySettings] Currency after animation: \(userPreferences.currencyCode)")
        
        // Auto-dismiss after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🔧 [CurrencySettings] About to dismiss, final currency: \(userPreferences.currencyCode)")
            dismiss()
        }
    }
    
    private func detectAndSetCurrency() {
        if let detectedCurrency = CurrencyManager.shared.detectCurrencyFromLocation() {
            selectCurrency(detectedCurrency)
        }
    }
}

struct CurrencyRow: View {
    let currency: CurrencyInfo
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: {
            print("🔧 [CurrencyRow] Tapped row: \(currency.code) - \(currency.name)")
            HapticManager.shared.selection()
            onSelect()
        }) {
            HStack(spacing: 12) {
                // Currency symbol
                Text(currency.symbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 32, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(currency.code)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())  // Make entire row tappable
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CurrencySettingsView()
}