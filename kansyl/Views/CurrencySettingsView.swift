//
//  CurrencySettingsView.swift
//  kansyl
//
//  Comprehensive currency selection with location-based recommendations
//

import SwiftUI

struct CurrencySettingsView: View {
    @ObservedObject private var appPreferences = AppPreferences.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var showingLocationDetection = false
    
    private var filteredCurrencies: [CurrencyInfo] {
        let allCurrencies = CurrencyManager.shared.getRegionalCurrencies()
        
        if searchText.isEmpty {
            return allCurrencies
        } else {
            return allCurrencies.filter { currency in
                currency.name.localizedCaseInsensitiveContains(searchText) ||
                currency.code.localizedCaseInsensitiveContains(searchText) ||
                currency.symbol.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var regionalCurrencies: [CurrencyInfo] {
        Array(CurrencyManager.shared.getRegionalCurrencies().prefix(8))
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
                                isSelected: currency.code == appPreferences.currencyCode,
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
                           Array(filteredCurrencies.dropFirst(regionalCurrencies.count)) : 
                           filteredCurrencies, id: \.code) { currency in
                        CurrencyRow(
                            currency: currency,
                            isSelected: currency.code == appPreferences.currencyCode,
                            onSelect: {
                                selectCurrency(currency)
                            }
                        )
                    }
                } header: {
                    Text(searchText.isEmpty ? "All Currencies" : "Search Results")
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
        }
    }
    
    private func selectCurrency(_ currency: CurrencyInfo) {
        withAnimation(.easeInOut(duration: 0.2)) {
            appPreferences.currencyCode = currency.code
            HapticManager.shared.selection()
        }
        
        // Auto-dismiss after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
        Button(action: onSelect) {
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
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CurrencySettingsView()
}