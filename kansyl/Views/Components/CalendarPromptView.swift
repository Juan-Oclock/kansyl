//
//  CalendarPromptView.swift
//  kansyl
//
//  Calendar integration prompt with smart UX
//

import SwiftUI

struct CalendarPromptView: View {
    @Binding var isPresented: Bool
    let subscription: Subscription
    let onConfirm: () -> Void
    
    @AppStorage("calendarIntegrationPreference") private var calendarPref = CalendarPreference.ask.rawValue
    @State private var dontAskAgain = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.blue)
                .padding(.top, 20)
            
            // Title
            Text("Add to Calendar?")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Design.Colors.textPrimary)
            
            // Description
            Text("We'll add a reminder for \(subscription.name ?? "this subscription") on \(formattedDate)")
                .font(.system(size: 16))
                .foregroundColor(Design.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Don't ask again option
            Toggle("Always add to calendar", isOn: $dontAskAgain)
                .font(.system(size: 14))
                .foregroundColor(Design.Colors.textSecondary)
                .padding(.horizontal, 30)
            
            // Action buttons
            HStack(spacing: 16) {
                Button("Not Now") {
                    if dontAskAgain {
                        calendarPref = CalendarPreference.never.rawValue
                    }
                    isPresented = false
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Design.Colors.surfaceSecondary)
                .foregroundColor(Design.Colors.textSecondary)
                .cornerRadius(12)
                
                Button("Add to Calendar") {
                    if dontAskAgain {
                        calendarPref = CalendarPreference.always.rawValue
                    }
                    onConfirm()
                    isPresented = false
                    
                    // Haptic feedback
                    HapticManager.shared.playButtonTap()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Design.Colors.success)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: 360)
        .background(Design.Colors.surface)
        .cornerRadius(20)
        .shadow(radius: 20)
        .padding(20)
    }
    
    private var formattedDate: String {
        guard let endDate = subscription.endDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: endDate)
    }
}

enum CalendarPreference: String {
    case always = "always"
    case never = "never"
    case ask = "ask"
}