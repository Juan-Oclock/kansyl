//
//  DesignSystem.swift
//  kansyl
//
//  Created on 9/13/25.
//  Modern Design System for Kansyl
//

import SwiftUI

// MARK: - Design System
struct Design {
    
    // MARK: - Colors
    struct Colors {
        // Light Mode Colors
        struct Light {
            // Primary Brand Colors
            static let primary = Color(hex: "1E1E1E")  // Main text, active states
            static let primaryLight = Color(hex: "4CAF50") // For compatibility
            static let secondary = Color(hex: "4CAF50") // Accent, CTA actions
            static let buttonPrimary = Color(hex: "16A34A") // Green CTA buttons
            
            // Background Colors
            static let background = Color(hex: "F8FAFC") // App background
            static let surface = Color(hex: "FFFFFF")    // Card background
            static let highlightBackground = Color(hex: "0F172A") // Dark savings card background
            static let surfaceSecondary = Color(hex: "F5F5FB")
            
            // Text Colors
            static let textPrimary = Color(hex: "0F172A")
            static let textSecondary = Color(hex: "64748B")
            static let textTertiary = Color(hex: "9CA3AF")
            
            // Semantic Colors
            static let success = Color(hex: "22C55E") // Positive status, savings
            static let warning = Color(hex: "FACC15") // Mild alerts, reminders
            static let danger = Color(hex: "EF4444")  // Expiring soon, critical alerts
            static let neutral = Color(hex: "CBD5E1") // Borders, inactive elements
            
            // Additional
            static let info = Color(hex: "00B8FF")
            static let border = Color(hex: "E5E7EB")
            static let borderLight = Color(hex: "F3F4F6")
            
            // Status Colors for Trials
            static let active = Color(hex: "5B67FF")
            static let saved = Color(hex: "00C896")
            static let kept = Color(hex: "00B8FF")
            static let expired = Color(hex: "FF3B5C")
        }
        
        // Dark Mode Colors
        struct Dark {
            // Primary Brand Colors
            static let primary = Color(hex: "FFFFFF")  // Main text, active states
            static let primaryLight = Color(hex: "66BB6A") // For compatibility
            static let secondary = Color(hex: "66BB6A") // Accent, CTA actions
            static let buttonPrimary = Color(hex: "22C55E") // Green CTA buttons
            
            // Background Colors
            static let background = Color(hex: "0F0F0F") // App background
            static let surface = Color(hex: "1A1A1A")    // Card background
            static let highlightBackground = Color(hex: "2A2A2A") // Dark savings card background
            static let surfaceSecondary = Color(hex: "252525")
            
            // Text Colors
            static let textPrimary = Color(hex: "F5F5F5")
            static let textSecondary = Color(hex: "A8A8A8")
            static let textTertiary = Color(hex: "6B6B6B")
            
            // Semantic Colors
            static let success = Color(hex: "34D399") // Positive status, savings
            static let warning = Color(hex: "FCD34D") // Mild alerts, reminders
            static let danger = Color(hex: "F87171")  // Expiring soon, critical alerts
            static let neutral = Color(hex: "4B5563") // Borders, inactive elements
            
            // Additional
            static let info = Color(hex: "60A5FA")
            static let border = Color(hex: "374151")
            static let borderLight = Color(hex: "1F2937")
            
            // Status Colors for Trials
            static let active = Color(hex: "818CF8")
            static let saved = Color(hex: "34D399")
            static let kept = Color(hex: "60A5FA")
            static let expired = Color(hex: "FB7185")
        }
    }
    
    // MARK: - Typography
    struct Typography {
        // Font Weights
        enum Weight {
            case regular, medium, semibold, bold
            
            var value: Font.Weight {
                switch self {
                case .regular: return .regular
                case .medium: return .medium
                case .semibold: return .semibold
                case .bold: return .bold
                }
            }
        }
        
        // Font Sizes
        static func largeTitle(_ weight: Weight = .bold) -> Font {
            .system(size: 34, weight: weight.value, design: .rounded)
        }
        
        static func title(_ weight: Weight = .bold) -> Font {
            .system(size: 28, weight: weight.value, design: .rounded)
        }
        
        static func title2(_ weight: Weight = .semibold) -> Font {
            .system(size: 22, weight: weight.value, design: .rounded)
        }
        
        static func title3(_ weight: Weight = .semibold) -> Font {
            .system(size: 20, weight: weight.value, design: .rounded)
        }
        
        static func headline(_ weight: Weight = .semibold) -> Font {
            .system(size: 17, weight: weight.value, design: .rounded)
        }
        
        static func body(_ weight: Weight = .regular) -> Font {
            .system(size: 17, weight: weight.value, design: .default)
        }
        
        static func callout(_ weight: Weight = .regular) -> Font {
            .system(size: 16, weight: weight.value, design: .default)
        }
        
        static func subheadline(_ weight: Weight = .regular) -> Font {
            .system(size: 15, weight: weight.value, design: .default)
        }
        
        static func footnote(_ weight: Weight = .regular) -> Font {
            .system(size: 13, weight: weight.value, design: .default)
        }
        
        static func caption(_ weight: Weight = .regular) -> Font {
            .system(size: 12, weight: weight.value, design: .default)
        }
        
        static func caption2(_ weight: Weight = .regular) -> Font {
            .system(size: 11, weight: weight.value, design: .default)
        }
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
    }
    
    // MARK: - Radius
    struct Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let round: CGFloat = 100
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let sm = (color: Color.black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let md = (color: Color.black.opacity(0.08), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let lg = (color: Color.black.opacity(0.12), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
        static let xl = (color: Color.black.opacity(0.16), radius: CGFloat(24), x: CGFloat(0), y: CGFloat(12))
        
        static let colored = (color: Design.Colors.primary.opacity(0.2), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(6))
    }
    
    // MARK: - Animation
    struct Animation {
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let bounce = SwiftUI.Animation.interpolatingSpring(stiffness: 300, damping: 15)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Modern Card Component
struct ModernCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = Design.Spacing.md
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Design.Colors.surface)
            .cornerRadius(Design.Radius.lg)
            .shadow(
                color: Design.Shadow.sm.color,
                radius: Design.Shadow.sm.radius,
                x: Design.Shadow.sm.x,
                y: Design.Shadow.sm.y
            )
    }
}

// MARK: - Gradient Card
struct GradientCard<Content: View>: View {
    let gradient: LinearGradient
    let content: Content
    
    init(
        gradient: LinearGradient = LinearGradient(
            colors: [Design.Colors.primary, Design.Colors.primaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        ),
        @ViewBuilder content: () -> Content
    ) {
        self.gradient = gradient
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Design.Spacing.lg)
            .background(gradient)
            .cornerRadius(Design.Radius.xl)
            .shadow(
                color: Design.Shadow.colored.color,
                radius: Design.Shadow.colored.radius,
                x: Design.Shadow.colored.x,
                y: Design.Shadow.colored.y
            )
    }
}

// MARK: - Modern Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @State private var isPressed = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Design.Typography.headline())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(
                LinearGradient(
                    colors: [Design.Colors.primary, Design.Colors.primaryLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(Design.Radius.md)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .shadow(
                color: Design.Colors.primary.opacity(configuration.isPressed ? 0.2 : 0.3),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Design.Typography.headline())
            .foregroundColor(Design.Colors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(Design.Colors.primary.opacity(0.1))
            .cornerRadius(Design.Radius.md)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Design.Typography.headline())
            .foregroundColor(Design.Colors.primary)
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [Design.Colors.primary, Design.Colors.primaryLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(
                    color: Design.Colors.primary.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 6
                )
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Modern Text Field
struct ModernTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: Design.Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(Design.Colors.textTertiary)
                    .frame(width: 20)
            }
            
            TextField(placeholder, text: $text)
                .font(Design.Typography.body())
        }
        .padding(Design.Spacing.md)
        .background(Design.Colors.surfaceSecondary)
        .cornerRadius(Design.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: Design.Radius.md)
                .stroke(Design.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase * 200 - 100)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
