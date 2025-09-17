//
//  EndingSoonBadge.swift
//  kansyl
//
//  Minimal badge indicator for subscriptions ending soon
//

import SwiftUI

struct EndingSoonBadge: View {
    var body: some View {
        Text("Ending Soon")
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "EF4444"),  // Red
                        Color(hex: "F97316")   // Orange
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(6)
            .shadow(color: Color(hex: "EF4444").opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// Alternative minimal dot indicator
struct EndingSoonDot: View {
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "EF4444"),
                        Color(hex: "F97316")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1.5)
            )
            .shadow(color: Color(hex: "EF4444").opacity(0.5), radius: 3, x: 0, y: 1)
    }
}

// Alternative corner ribbon style
struct EndingSoonRibbon: View {
    var body: some View {
        ZStack {
            // Ribbon shape
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 65, y: 0))
                path.addLine(to: CGPoint(x: 55, y: 20))
                path.addLine(to: CGPoint(x: 0, y: 20))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "EF4444"),
                        Color(hex: "F97316")
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            Text("Soon")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .offset(x: -5)
        }
        .frame(width: 65, height: 20)
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

// Preview
struct EndingSoonBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            EndingSoonBadge()
            EndingSoonDot()
            EndingSoonRibbon()
        }
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}