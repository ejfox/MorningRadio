//
//  FactCarouselView.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/26/24.
//

import SwiftUI

struct FactCarouselView: View {
    // MARK: - Properties
    let facts: [String]                      // List of facts to display
    @Binding var currentIndex: Int           // Current fact index
    let onFactChange: ((Int) -> Void)?       // Callback for external handling (optional)
    var animationDuration: Double = 0.3      // Animation duration for transitions
    
    // MARK: - State
    @State private var transitioning = false // Prevents multiple simultaneous transitions
    
    var body: some View {
        VStack {
            // Current Fact
            if !facts.isEmpty {
                Text(facts[currentIndex])
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(currentIndex) // Force update when currentIndex changes
            }
            
            Spacer()
            
            // Navigation and Indicators
            HStack {
                // Previous Button
                Button(action: { navigate(forward: false) }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .padding()
                }
                .disabled(transitioning)
                
                Spacer()
                
                // Progress Indicators
                HStack(spacing: 6) {
                    ForEach(facts.indices, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.primary : Color.primary.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                
                Spacer()
                
                // Next Button
                Button(action: { navigate(forward: true) }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .semibold))
                        .padding()
                }
                .disabled(transitioning)
            }
        }
        .padding()
    }
    
    // MARK: - Navigation Logic
    private func navigate(forward: Bool) {
        guard !transitioning else { return }
        transitioning = true
        
        withAnimation(Animation.easeInOut(duration: animationDuration)) {
            if forward {
                currentIndex = (currentIndex + 1) % facts.count
            } else {
                currentIndex = (currentIndex - 1 + facts.count) % facts.count
            }
        }
        
        onFactChange?(currentIndex)
        
        // Reset transition lock after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            transitioning = false
        }
    }
}

#Preview {
    @State var index = 0
    return FactCarouselView(
        facts: ["Fact 1", "Fact 2", "Fact 3"],
        currentIndex: $index,
        onFactChange: { newIndex in
            print("Changed to fact at index: \(newIndex)")
        }
    )
}
