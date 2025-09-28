//
//  TrialLengthSettingsView.swift
//  kansyl
//
//  Settings view for configuring default trial length
//

import SwiftUI

struct TrialLengthSettingsView: View {
    @ObservedObject private var userPreferences = UserSpecificPreferences.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    // Local state for editing
    @State private var length: Int = 0
    @State private var unit: TrialLengthUnit = .days
    @FocusState private var isLengthFieldFocused: Bool
    
    // Common trial lengths for quick selection
    private let quickLengths = [
        (7, TrialLengthUnit.days, "1 Week"),
        (14, TrialLengthUnit.days, "2 Weeks"),
        (30, TrialLengthUnit.days, "1 Month"),
        (60, TrialLengthUnit.days, "2 Months"),
        (90, TrialLengthUnit.days, "3 Months"),
        (1, TrialLengthUnit.months, "1 Month"),
        (3, TrialLengthUnit.months, "3 Months"),
        (6, TrialLengthUnit.months, "6 Months"),
        (1, TrialLengthUnit.weeks, "1 Week"),
        (2, TrialLengthUnit.weeks, "2 Weeks")
    ]
    
    var body: some View {
        Form {
            // Custom Input Section
            Section {
                HStack {
                    Text("Length")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    TextField("30", value: $length, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .keyboardType(.numberPad)
                        .focused($isLengthFieldFocused)
                }
                
                Picker("Unit", selection: $unit) {
                    ForEach(TrialLengthUnit.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Custom Length")
            } footer: {
                Text("Set a custom default length for new subscriptions")
            }
            
            // Quick Selection Section
            Section {
                ForEach(groupedQuickLengths.sorted(by: { $0.key.rawValue < $1.key.rawValue }), id: \.key) { unit, lengths in
                    if !lengths.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(unit.displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                ForEach(lengths, id: \.2) { quickLength in
                                    quickLengthButton(quickLength)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Quick Selection")
            } footer: {
                Text("Tap to quickly set a common trial length")
            }
            
            // Current Setting Display
            Section {
                HStack {
                    Label("Current Setting", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text("\(length) \(unit.displayName)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            } footer: {
                Text("This will be the default length for all new subscriptions")
            }
        }
        .navigationTitle("Trial Length")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    saveSettings()
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .disabled(length <= 0)
            }
            
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isLengthFieldFocused = false
                }
            }
        }
        .onAppear {
            // Load current settings
            length = userPreferences.defaultTrialLength
            unit = userPreferences.defaultTrialLengthUnit
        }
    }
    
    private var groupedQuickLengths: [TrialLengthUnit: [(Int, TrialLengthUnit, String)]] {
        Dictionary(grouping: quickLengths) { $0.1 }
    }
    
    @ViewBuilder
    private func quickLengthButton(_ quickLength: (Int, TrialLengthUnit, String)) -> some View {
        let isSelected = length == quickLength.0 && unit == quickLength.1
        
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                length = quickLength.0
                unit = quickLength.1
                HapticManager.shared.playSelection()
            }
        }) {
            Text(quickLength.2)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : (colorScheme == .dark ? Color(hex: "252525") : Color(UIColor.secondarySystemBackground)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func saveSettings() {
        userPreferences.defaultTrialLength = length
        userPreferences.defaultTrialLengthUnit = unit
    }
}

// Preview
struct TrialLengthSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TrialLengthSettingsView()
        }
    }
}