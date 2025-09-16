//
//  AppIconGenerator.swift
//  kansyl
//
//  Created on 9/12/25.
//  Temporary App Icon Generator
//

import SwiftUI

struct AppIconView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.4, blue: 1.0),
                    Color(red: 0.1, green: 0.2, blue: 0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Main icon content
            VStack(spacing: size * 0.02) {
                // Clock/Calendar icon representing trials
                ZStack {
                    // Outer circle
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: size * 0.015)
                        .frame(width: size * 0.55, height: size * 0.55)
                    
                    // Inner circle
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: size * 0.45, height: size * 0.45)
                    
                    // Icon symbol
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.system(size: size * 0.28, weight: .medium))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                }
                
                // App name
                Text("K")
                    .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    .offset(y: -size * 0.05)
            }
        }
        .frame(width: size, height: size)
    }
}

// Alternative minimalist design
struct AppIconMinimalView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Solid background
            Color(red: 0.15, green: 0.35, blue: 0.95)
            
            // Letter K with check mark
            ZStack {
                Text("K")
                    .font(.system(size: size * 0.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Small checkmark badge
                Circle()
                    .fill(Color.green)
                    .frame(width: size * 0.22, height: size * 0.22)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: size * 0.12, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: size * 0.18, y: -size * 0.15)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2237))
    }
}

// Preview for different icon sizes
struct AppIconGenerator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("App Icon Designs")
                .font(.title)
                .padding()
            
            HStack(spacing: 20) {
                VStack {
                    Text("Design 1")
                    AppIconView(size: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                        .shadow(radius: 5)
                }
                
                VStack {
                    Text("Design 2")
                    AppIconMinimalView(size: 180)
                        .shadow(radius: 5)
                }
            }
            
            Text("Use screenshot to export")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

#if DEBUG
// Helper to export icon at different sizes
extension View {
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}

// Function to generate all required icon sizes
func generateAppIcons() {
    let sizes = [
        (name: "20x20", size: 20, scale: [2, 3]),
        (name: "29x29", size: 29, scale: [2, 3]),
        (name: "40x40", size: 40, scale: [2, 3]),
        (name: "60x60", size: 60, scale: [2, 3]),
        (name: "76x76", size: 76, scale: [1, 2]),
        (name: "83.5x83.5", size: 83.5, scale: [2]),
        (name: "1024x1024", size: 1024, scale: [1])
    ]
    
    // This would generate all required sizes
    // You can run this in a playground or test app
    for sizeConfig in sizes {
        for scale in sizeConfig.scale {
            let actualSize = sizeConfig.size * CGFloat(scale)
            let icon = AppIconMinimalView(size: actualSize)
            // Save or export the icon
            _ = icon.snapshot()
            print("Generated icon: \(sizeConfig.name)@\(scale)x - \(actualSize)x\(actualSize)px")
        }
    }
}
#endif
