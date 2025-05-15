//
//  FactCarouselView.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/26/24.
//

import SwiftUI
import SwiftyMarkdown

struct FactCarouselView: View {
    // MARK: - Properties
    let facts: [String]
    @Binding var currentIndex: Int
    let onFactChange: ((Int) -> Void)?
    var animationDuration: Double = 0.3
    
    // MARK: - State
    @State private var transitioning = false
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var settings: UserSettings
    
    // MARK: - Layout Constants
    private let horizontalPadding: CGFloat = 24
    private let verticalPadding: CGFloat = 40
    private let lineSpacing: CGFloat = 1.3
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if !facts.isEmpty {
                    // Fact Content
                    Text(facts[currentIndex])
                        .dynamicFont(.title2)
                        .lineSpacing(lineSpacing)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, horizontalPadding)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity,
                            alignment: .center
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .id(currentIndex)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Fact \(currentIndex + 1) of \(facts.count)")
                        .accessibilityValue(facts[currentIndex])
                        .accessibilityHint("Tap to continue to the next fact")
                    
                    // Bottom Controls
                    VStack(spacing: 12) {
                        Text("Tap to continue")
                            .dynamicFont(.caption)
                            .foregroundColor(.secondary)
                            .opacity(0.6)
                            .accessibilityHidden(true)
                    }
                    .padding(.bottom, verticalPadding)
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .contentShape(Rectangle())
            .onTapGesture {
                navigate(forward: true)
            }
        }
    }
    
    // MARK: - Navigation Logic
    private func navigate(forward: Bool) {
        guard !transitioning else { return }
        transitioning = true
        
        if settings.useHaptics {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
        
        let newIndex = forward ? 
            min(currentIndex + 1, facts.count - 1) : 
            max(currentIndex - 1, 0)
        
        if newIndex != currentIndex {
            withAnimation(.easeInOut(duration: animationDuration)) {
                currentIndex = newIndex
            }
            
            onFactChange?(currentIndex)
            
            // Reset transitioning state after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration + 0.1) {
                transitioning = false
            }
        } else {
            transitioning = false
        }
    }
}

// MARK: - Preview
#Preview {
    FactCarouselView(
        facts: [
            "This is the first fact about something interesting.",
            "Here's a second, longer fact that contains more information and details about the topic at hand.",
            "And finally, a third fact to round things out."
        ],
        currentIndex: .constant(0),
        onFactChange: nil
    )
    .environmentObject(UserSettings())
}
