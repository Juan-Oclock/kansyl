//
//  TutorialView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI

struct TutorialView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    @State private var highlightedArea: TutorialHighlight?
    
    let steps: [TutorialStep] = [
        TutorialStep(
            title: "Welcome to Kansyl!",
            message: "Let's add your first free trial. Tap the + button to get started.",
            highlightArea: .addButton
        ),
        TutorialStep(
            title: "Choose a Service",
            message: "Select from popular services or create a custom trial.",
            highlightArea: .serviceList
        ),
        TutorialStep(
            title: "Set Trial Details",
            message: "Enter the trial duration and any notes to help you remember.",
            highlightArea: .trialForm
        ),
        TutorialStep(
            title: "You're All Set!",
            message: "We'll remind you before your trial ends. You can view all trials here.",
            highlightArea: .trialsList
        )
    ]
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    advanceStep()
                }
            
            // Tutorial tooltip
            VStack {
                if currentStep < steps.count {
                    TutorialTooltip(
                        step: steps[currentStep],
                        currentStep: currentStep,
                        totalSteps: steps.count,
                        onNext: advanceStep,
                        onSkip: {
                            isPresented = false
                        }
                    )
                    .padding()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
        }
    }
    
    private func advanceStep() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        if currentStep < steps.count - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            isPresented = false
        }
    }
}

struct TutorialStep {
    let title: String
    let message: String
    let highlightArea: TutorialHighlight
}

enum TutorialHighlight {
    case addButton
    case serviceList
    case trialForm
    case trialsList
}

struct TutorialTooltip: View {
    let step: TutorialStep
    let currentStep: Int
    let totalSteps: Int
    let onNext: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(step.title)
                    .font(.headline)
                
                Spacer()
                
                Button("Skip") {
                    onSkip()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Text(step.message)
                .font(.body)
                .foregroundColor(.secondary)
            
            // Progress and button
            HStack {
                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                
                Spacer()
                
                Button(action: onNext) {
                    Text(currentStep < totalSteps - 1 ? "Next" : "Done")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.accentColor)
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 10)
        )
        .frame(maxWidth: 340)
    }
}

// MARK: - Tutorial Overlay Modifier
struct TutorialOverlay: ViewModifier {
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var showTutorial = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if showTutorial {
                        TutorialView(isPresented: $showTutorial)
                    }
                }
            )
            .onAppear {
                if !hasSeenTutorial {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showTutorial = true
                        hasSeenTutorial = true
                    }
                }
            }
    }
}

extension View {
    func tutorialOverlay() -> some View {
        modifier(TutorialOverlay())
    }
}

// MARK: - Preview
struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
            TutorialView(isPresented: .constant(true))
        }
    }
}
