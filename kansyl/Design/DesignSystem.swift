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
            // Primary Brand Colors - Matching landing page
            static let primary = Color(hex: "6B41C7")  // Purple brand color
            static let primaryLight = Color(hex: "A8DE28") // Lime green accent
            static let secondary = Color(hex: "A8DE28") // Lime green for CTAs
            static let buttonPrimary = Color(hex: "6B41C7") // Purple for primary buttons
            static let primaryButtonText = Color.white // White text for purple buttons
            
            // Background Colors - Clean and minimal
            static let background = Color(hex: "FAFAFA") // Light gray background
            static let surface = Color(hex: "FFFFFF")    // Pure white cards
            static let highlightBackground = Color(hex: "6B41C7") // Purple highlight background
            static let surfaceSecondary = Color(hex: "F8F9FA")
            
            // Text Colors - High contrast
            static let textPrimary = Color(hex: "0A0A0A")
            static let textSecondary = Color(hex: "6B7280")
            static let textTertiary = Color(hex: "9CA3AF")
            
            // Semantic Colors - Modern palette
            static let success = Color(hex: "22C55E") // Green for success
            static let warning = Color(hex: "F59E0B") // Amber for warnings
            static let danger = Color(hex: "EF4444")  // Red for danger
            static let neutral = Color(hex: "E5E7EB") // Neutral gray
            
            // Additional
            static let info = Color(hex: "3B82F6")  // Blue for info
            static let border = Color(hex: "E5E7EB")
            static let borderLight = Color(hex: "F3F4F6")
            
            // Status Colors for Trials - Vibrant
            static let active = Color(hex: "6B41C7")  // Purple for active
            static let saved = Color(hex: "22C55E")  // Green for saved
            static let kept = Color(hex: "3B82F6")   // Blue for kept
            static let expired = Color(hex: "EF4444") // Red for expired
        }
        
        // Dark Mode Colors - Modern dark theme
        struct Dark {
            // Primary Brand Colors
            static let primary = Color(hex: "A8DE28")  // Lime green in dark mode
            static let primaryLight = Color(hex: "6B41C7") // Purple accent
            static let secondary = Color(hex: "A8DE28") // Lime green accent
            static let buttonPrimary = Color(hex: "A8DE28") // Lime green buttons
            static let primaryButtonText = Color(hex: "0A0A0A") // Dark text for lime buttons
            
            // Background Colors - True dark
            static let background = Color(hex: "0A0A0A") // Near black background
            static let surface = Color(hex: "141414")    // Slightly lighter surface
            static let highlightBackground = Color(hex: "6B41C7").opacity(0.15) // Purple tinted highlight
            static let surfaceSecondary = Color(hex: "1A1A1A")
            
            // Text Colors
            static let textPrimary = Color(hex: "FAFAFA")
            static let textSecondary = Color(hex: "A1A1AA")
            static let textTertiary = Color(hex: "71717A")
            
            // Semantic Colors - Vibrant for dark mode
            static let success = Color(hex: "22C55E")
            static let warning = Color(hex: "F59E0B")
            static let danger = Color(hex: "EF4444")
            static let neutral = Color(hex: "3F3F46")
            
            // Additional
            static let info = Color(hex: "3B82F6")
            static let border = Color(hex: "27272A")
            static let borderLight = Color(hex: "18181B")
            
            // Status Colors for Trials
            static let active = Color(hex: "A8DE28")  // Lime green for active
            static let saved = Color(hex: "22C55E")  // Green for saved
            static let kept = Color(hex: "3B82F6")   // Blue for kept
            static let expired = Color(hex: "EF4444") // Red for expired
        }
        
        // MARK: - Gradients
        struct Gradients {
            // Brand gradient - Purple to Lime
            static let brand = LinearGradient(
                colors: [Color(hex: "6B41C7"), Color(hex: "A8DE28")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Shiny text gradient for branding
            static let shinyText = LinearGradient(
                colors: [
                    Color(hex: "6B41C7"),
                    Color(hex: "A8DE28"),
                    Color(hex: "6B41C7")
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            
            // Button gradients
            static let purpleGradient = LinearGradient(
                colors: [Color(hex: "6B41C7"), Color(hex: "8B5CF6")],
                startPoint: .leading,
                endPoint: .trailing
            )
            
            static let limeGradient = LinearGradient(
                colors: [Color(hex: "A8DE28"), Color(hex: "84CC16")],
                startPoint: .leading,
                endPoint: .trailing
            )
            
            // Success gradient
            static let success = LinearGradient(
                colors: [Color(hex: "22C55E"), Color(hex: "16A34A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Glass morphism overlay
            static let glassMorphism = LinearGradient(
                colors: [
                    Color.white.opacity(0.1),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
        static let sm = (color: Color.black.opacity(0.04), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let md = (color: Color.black.opacity(0.06), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let lg = (color: Color.black.opacity(0.1), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
        static let xl = (color: Color.black.opacity(0.15), radius: CGFloat(24), x: CGFloat(0), y: CGFloat(12))
        
        static let colored = (color: Design.Colors.primary.opacity(0.15), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(6))
        static let glow = (color: Design.Colors.primaryLight.opacity(0.3), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(0))
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
    var useGlassMorphism: Bool = false
    
    init(padding: CGFloat = Design.Spacing.md, useGlassMorphism: Bool = false, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.useGlassMorphism = useGlassMorphism
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                Group {
                    if useGlassMorphism {
                        RoundedRectangle(cornerRadius: Design.Radius.lg)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: Design.Radius.lg)
                                    .fill(Design.Colors.Gradients.glassMorphism)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: Design.Radius.lg)
                            .fill(Design.Colors.surface)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.lg)
                    .strokeBorder(
                        Design.Colors.border.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Design.Colors.primary.opacity(0.05),
                radius: 10,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Gradient Card
struct GradientCard<Content: View>: View {
    let gradient: LinearGradient
    let content: Content
    var addGlossEffect: Bool = true
    
    init(
        gradient: LinearGradient = Design.Colors.Gradients.brand,
        addGlossEffect: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.gradient = gradient
        self.addGlossEffect = addGlossEffect
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Design.Spacing.lg)
            .foregroundColor(.white)
            .background(
                ZStack {
                    gradient
                    if addGlossEffect {
                        Design.Colors.Gradients.glassMorphism
                    }
                }
            )
            .cornerRadius(Design.Radius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.xl)
                    .strokeBorder(
                        Color.white.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: Design.Colors.primary.opacity(0.2),
                radius: 15,
                x: 0,
                y: 8
            )
    }
}

// MARK: - Modern Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @State private var isPressed = false
    var useLimeGradient: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Design.Typography.headline(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(
                Group {
                    if useLimeGradient {
                        Design.Colors.Gradients.limeGradient
                    } else {
                        Design.Colors.Gradients.purpleGradient
                    }
                }
            )
            .cornerRadius(Design.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(Design.Colors.Gradients.glassMorphism)
                    .opacity(configuration.isPressed ? 0 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(
                color: (useLimeGradient ? Design.Colors.primaryLight : Design.Colors.primary)
                    .opacity(configuration.isPressed ? 0.15 : 0.25),
                radius: configuration.isPressed ? 6 : 12,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Design.Typography.headline(.medium))
            .foregroundColor(Design.Colors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(Design.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Design.Radius.md)
                            .strokeBorder(
                                Design.Colors.primary.opacity(0.3),
                                lineWidth: 1.5
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Glass Button Style
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Design.Typography.headline(.medium))
            .foregroundColor(Design.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Design.Radius.md)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: Design.Radius.md)
                            .strokeBorder(
                                Design.Colors.border.opacity(0.5),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

// MARK: - Shiny Text Component
struct ShinyText: View {
    let text: String
    var font: Font = Design.Typography.title(.bold)
    @State private var shimmerOffset: CGFloat = -1.0
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(
                Design.Colors.Gradients.shinyText
            )
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.5),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.5)
                    .offset(x: geometry.size.width * shimmerOffset)
                    .animation(
                        Animation.linear(duration: 2.5)
                            .repeatForever(autoreverses: false),
                        value: shimmerOffset
                    )
                    .onAppear {
                        shimmerOffset = 1.5
                    }
                }
                .mask(Text(text).font(font))
            )
    }
}

// MARK: - Accent Badge
struct AccentBadge: View {
    let text: String
    var color: Color = Design.Colors.primaryLight
    
    var body: some View {
        Text(text)
            .font(Design.Typography.caption(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, Design.Spacing.xs)
            .padding(.vertical, Design.Spacing.xxs)
            .background(
                Capsule()
                    .fill(color)
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
            )
    }
}

// MARK: - Floating Action Button Style
struct FloatingActionButtonStyle: ButtonStyle {
    var backgroundColor: Color = Design.Colors.primary
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(
                Circle()
                    .fill(backgroundColor)
                    .shadow(
                        color: backgroundColor.opacity(0.3),
                        radius: configuration.isPressed ? 8 : 12,
                        x: 0,
                        y: configuration.isPressed ? 4 : 8
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
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
