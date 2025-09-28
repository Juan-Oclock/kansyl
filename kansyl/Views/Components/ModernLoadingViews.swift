//
//  ModernLoadingViews.swift
//  kansyl
//
//  Modern loading animations matching the landing page aesthetic
//

import SwiftUI

// MARK: - Pulse Loading View
struct PulseLoadingView: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.3
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Design.Colors.Gradients.brand)
                    .frame(width: 100, height: 100)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.5),
                        value: scale
                    )
            }
        }
        .onAppear {
            scale = 2.0
            opacity = 0.0
        }
    }
}

// MARK: - Dots Loading View
struct DotsLoadingView: View {
    @State private var showDot = [false, false, false]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Design.Colors.primary)
                    .frame(width: 12, height: 12)
                    .scaleEffect(showDot[index] ? 1.0 : 0.6)
                    .opacity(showDot[index] ? 1.0 : 0.6)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: showDot[index]
                    )
            }
        }
        .onAppear {
            for index in 0..<3 {
                showDot[index] = true
            }
        }
    }
}

// MARK: - Gradient Bar Loading View
struct GradientBarLoadingView: View {
    @State private var progress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Design.Colors.border.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Design.Colors.Gradients.brand)
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: progress
                    )
            }
        }
        .frame(height: 8)
        .onAppear {
            progress = 0.8
        }
    }
}

// MARK: - Morphing Shape Loading View
struct MorphingShapeLoadingView: View {
    @State private var morph = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: morph ? 60 : 20)
                .fill(Design.Colors.Gradients.brand)
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(morph ? 360 : 0))
                .scaleEffect(morph ? 0.8 : 1.0)
        }
        .animation(
            Animation.easeInOut(duration: 2)
                .repeatForever(autoreverses: true),
            value: morph
        )
        .onAppear {
            morph = true
        }
    }
}

// MARK: - Advanced Loading View with Multiple Elements
struct AdvancedLoadingView: View {
    @State private var isAnimating = false
    @State private var textOpacity = 0.5
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Design.Colors.background,
                    Design.Colors.primary.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Main spinner
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            Design.Colors.Gradients.brand,
                            lineWidth: 3
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 3)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    // Inner ring
                    Circle()
                        .stroke(
                            Design.Colors.Gradients.limeGradient,
                            lineWidth: 2
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isAnimating ? -360 : 0))
                        .animation(
                            .linear(duration: 2)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    // Center pulse
                    Circle()
                        .fill(Design.Colors.primary.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 1)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                VStack(spacing: 12) {
                    ShinyText(text: "Kansyl", font: Design.Typography.largeTitle())
                    
                    Text("Getting everything ready")
                        .font(Design.Typography.callout())
                        .foregroundColor(Design.Colors.textSecondary)
                        .opacity(textOpacity)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                            value: textOpacity
                        )
                }
            }
        }
        .onAppear {
            isAnimating = true
            textOpacity = 1.0
        }
    }
}

// MARK: - Minimalist Loading View
struct MinimalistLoadingView: View {
    @State private var offset: CGFloat = -100
    
    var body: some View {
        ZStack {
            Design.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 50) {
                // Animated line
                GeometryReader { geometry in
                    ZStack {
                        Rectangle()
                            .fill(Design.Colors.border.opacity(0.1))
                            .frame(height: 2)
                        
                        Rectangle()
                            .fill(Design.Colors.Gradients.brand)
                            .frame(width: 150, height: 2)
                            .offset(x: offset)
                            .animation(
                                .linear(duration: 1.5)
                                .repeatForever(autoreverses: false),
                                value: offset
                            )
                    }
                    .onAppear {
                        offset = geometry.size.width
                    }
                }
                .frame(height: 2)
                
                Text("kansyl")
                    .font(Design.Typography.title2())
                    .foregroundColor(Design.Colors.primary)
                    .tracking(2)
            }
            .padding(40)
        }
    }
}

// MARK: - Preview
struct ModernLoadingViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PulseLoadingView()
                .previewDisplayName("Pulse")
            
            VStack {
                DotsLoadingView()
                GradientBarLoadingView()
                    .padding(.horizontal, 50)
            }
            .previewDisplayName("Dots & Bar")
            
            MorphingShapeLoadingView()
                .previewDisplayName("Morphing")
            
            AdvancedLoadingView()
                .previewDisplayName("Advanced")
            
            MinimalistLoadingView()
                .previewDisplayName("Minimalist")
        }
        .preferredColorScheme(.light)
    }
}