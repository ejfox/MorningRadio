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
    
    // MARK: - Layout Constants
    private let horizontalPadding: CGFloat = 24
    private let verticalPadding: CGFloat = 40
    private let minFontSize: CGFloat = 16
    private let maxFontSize: CGFloat = 36
    private let shortTextThreshold = 20
    private let longTextThreshold = 400
    private let lineSpacing: CGFloat = 1.3
    
    // Dynamic font sizing based on content length
    private func calculateFontSize(for text: String) -> CGFloat {
        let length = text.count
        
        if length <= shortTextThreshold {
            return maxFontSize
        } else if length >= longTextThreshold {
            return minFontSize
        }
        
        // Linear interpolation between max and min font sizes
        let ratio = CGFloat(length - shortTextThreshold) / CGFloat(longTextThreshold - shortTextThreshold)
        return maxFontSize + (minFontSize - maxFontSize) * ratio
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                if !facts.isEmpty {
                    // Fact Content
                    Text(facts[currentIndex])
                        .font(.system(
                            size: calculateFontSize(for: facts[currentIndex]),
                            weight: .regular,
                            design: .serif
                        ))
                        .lineSpacing(lineSpacing)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
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
                    
                    // Bottom Controls
                    VStack(spacing: 12) {
                        Text("Tap to continue")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                            .opacity(0.6)
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
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        withAnimation(.easeInOut(duration: animationDuration)) {
            if forward {
                currentIndex = (currentIndex + 1) % facts.count
            } else {
                currentIndex = (currentIndex - 1 + facts.count) % facts.count
            }
            onFactChange?(currentIndex)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            transitioning = false
        }
    }
}

#Preview {
    FactCarouselView(
        facts: [
            "# Main Fact\nThis is a *styled* fact with **bold** text",
            "## Secondary Fact\nAnother fact with [a link](https://example.com)",
            "A plain fact with no styling"
        ],
        currentIndex: .constant(0),
        onFactChange: { newIndex in
            print("Changed to fact at index: \(newIndex)")
        }
    )
}
