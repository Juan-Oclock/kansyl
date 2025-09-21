//
//  ConfettiView.swift
//  kansyl
//
//  Confetti celebration effect for positive actions
//

import SwiftUI

struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    @Binding var trigger: Bool
    let confettiConfig: ConfettiConfig
    
    init(trigger: Binding<Bool>, config: ConfettiConfig = .default) {
        self._trigger = trigger
        self.confettiConfig = config
    }
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                ConfettiPieceView(piece: piece)
            }
        }
        .onChange(of: trigger) { newValue in
            if newValue {
                startConfetti()
                // Reset trigger after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    trigger = false
                }
            }
        }
    }
    
    private func startConfetti() {
        confettiPieces = []
        
        // Generate confetti pieces
        for i in 0..<confettiConfig.particleCount {
            let piece = ConfettiPiece(
                id: i,
                position: CGPoint(
                    x: CGFloat.random(in: -50...UIScreen.main.bounds.width + 50),
                    y: -20
                ),
                color: confettiConfig.colors.randomElement() ?? .green,
                shape: confettiConfig.shapes.randomElement() ?? .rectangle,
                scale: CGFloat.random(in: 0.4...1.0),
                velocity: CGFloat.random(in: confettiConfig.velocityRange),
                angularVelocity: CGFloat.random(in: -180...180),
                lifetime: Double.random(in: confettiConfig.lifetimeRange)
            )
            confettiPieces.append(piece)
        }
        
        // Remove confetti after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + confettiConfig.duration) {
            confettiPieces = []
        }
    }
}

// MARK: - Confetti Piece Model
struct ConfettiPiece: Identifiable {
    let id: Int
    var position: CGPoint
    let color: Color
    let shape: ConfettiShape
    let scale: CGFloat
    let velocity: CGFloat
    let angularVelocity: CGFloat
    let lifetime: Double
}

enum ConfettiShape {
    case rectangle
    case circle
    case triangle
    case star
}

// MARK: - Single Confetti Piece View
struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var position: CGPoint
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    init(piece: ConfettiPiece) {
        self.piece = piece
        self._position = State(initialValue: piece.position)
    }
    
    var body: some View {
        confettiShape
            .position(position)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: piece.lifetime)) {
                    // Fall down with some horizontal drift
                    position.y = UIScreen.main.bounds.height + 100
                    position.x += CGFloat.random(in: -30...30)
                    rotation = piece.angularVelocity * piece.lifetime
                }
                
                // Fade out near the end
                withAnimation(.easeOut(duration: piece.lifetime * 0.3).delay(piece.lifetime * 0.7)) {
                    opacity = 0
                }
            }
    }
    
    @ViewBuilder
    private var confettiShape: some View {
        switch piece.shape {
        case .rectangle:
            Rectangle()
                .fill(piece.color)
                .frame(width: 10 * piece.scale, height: 10 * piece.scale)
        case .circle:
            Circle()
                .fill(piece.color)
                .frame(width: 10 * piece.scale, height: 10 * piece.scale)
        case .triangle:
            Triangle()
                .fill(piece.color)
                .frame(width: 10 * piece.scale, height: 10 * piece.scale)
        case .star:
            Star()
                .fill(piece.color)
                .frame(width: 10 * piece.scale, height: 10 * piece.scale)
        }
    }
}

// MARK: - Custom Shapes
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Star: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * 0.4
        var path = Path()
        
        for i in 0..<10 {
            let angle = (Double(i) * .pi * 2) / 10 - .pi / 2
            let r = i % 2 == 0 ? radius : innerRadius
            let x = center.x + CGFloat(cos(angle)) * r
            let y = center.y + CGFloat(sin(angle)) * r
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Confetti Configuration
struct ConfettiConfig {
    let particleCount: Int
    let colors: [Color]
    let shapes: [ConfettiShape]
    let velocityRange: ClosedRange<CGFloat>
    let lifetimeRange: ClosedRange<Double>
    let duration: Double
    
    static let `default` = ConfettiConfig(
        particleCount: 50,
        colors: [
            Design.Colors.success,
            Design.Colors.kept,
            Color(hex: "FFD700"), // Gold
            Color(hex: "FF69B4"), // Pink
            Color(hex: "00CED1"), // Turquoise
            Color(hex: "9370DB")  // Purple
        ],
        shapes: [.rectangle, .circle, .triangle, .star],
        velocityRange: 100...400,
        lifetimeRange: 2.0...3.0,
        duration: 3.5
    )
    
    static let savings = ConfettiConfig(
        particleCount: 60,
        colors: [
            Design.Colors.success,
            Color(hex: "00C896"), // Money green
            Color(hex: "50C878"), // Emerald
            Color(hex: "FFD700"), // Gold
            Color(hex: "32CD32"), // Lime green
            Design.Colors.kept
        ],
        shapes: [.rectangle, .circle, .star],
        velocityRange: 150...450,
        lifetimeRange: 2.5...3.5,
        duration: 4.0
    )
}

// MARK: - Emoji Confetti Alternative
struct EmojiConfettiView: View {
    @Binding var trigger: Bool
    let emojis = ["💰", "💵", "💸", "🎉", "✨", "🎊", "💚", "💪", "🎯", "🔥"]
    @State private var particles: [EmojiParticle] = []
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Text(particle.emoji)
                    .font(.system(size: particle.size))
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .rotationEffect(.degrees(particle.rotation))
                    .onAppear {
                        withAnimation(.linear(duration: particle.lifetime)) {
                            particle.position.y = UIScreen.main.bounds.height + 100
                            particle.rotation = Double.random(in: -360...360)
                        }
                        withAnimation(.easeOut(duration: particle.lifetime * 0.3).delay(particle.lifetime * 0.7)) {
                            particle.opacity = 0
                        }
                    }
            }
        }
        .onChange(of: trigger) { newValue in
            if newValue {
                createParticles()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    trigger = false
                }
                
                // Clear particles after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    particles = []
                }
            }
        }
    }
    
    private func createParticles() {
        particles = []
        for i in 0..<30 {
            let particle = EmojiParticle(
                id: i,
                emoji: emojis.randomElement()!,
                position: CGPoint(
                    x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                    y: -50
                ),
                size: CGFloat.random(in: 20...40),
                lifetime: Double.random(in: 2.5...3.5),
                opacity: 1,
                rotation: 0
            )
            particles.append(particle)
        }
    }
}

class EmojiParticle: Identifiable, ObservableObject {
    let id: Int
    let emoji: String
    @Published var position: CGPoint
    let size: CGFloat
    let lifetime: Double
    @Published var opacity: Double
    @Published var rotation: Double
    
    init(id: Int, emoji: String, position: CGPoint, size: CGFloat, lifetime: Double, opacity: Double, rotation: Double) {
        self.id = id
        self.emoji = emoji
        self.position = position
        self.size = size
        self.lifetime = lifetime
        self.opacity = opacity
        self.rotation = rotation
    }
}