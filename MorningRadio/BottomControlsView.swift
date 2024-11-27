//
//  BottomControlsView.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/26/24.
//

import SwiftUI

struct BottomControlsView: View {
    // MARK: - Properties
    let onShare: () -> Void                 // Callback for the share action
    var additionalActions: [ButtonConfig]? // Optional additional buttons
    
    // MARK: - Constants
    private let buttonSize: CGFloat = 44    // Standard button size
    private let padding: CGFloat = 16       // Padding around controls
    
    var body: some View {
        HStack {
            Spacer()
            
            // Dynamic Action Buttons
            if let actions = additionalActions {
                ForEach(actions, id: \.id) { config in
                    ActionButton(config: config)
                }
            }
            
            // Share Button
            Button(action: {
                let impact = UIImpactFeedbackGenerator(style: .soft)
                impact.impactOccurred(intensity: 0.7)
                onShare()
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: buttonSize, height: buttonSize)
                    .background(
                        RoundedRectangle(cornerRadius: buttonSize / 2)
                            .fill(Color.secondary.opacity(0.1))
                    )
            }
            .padding(.trailing, padding)
        }
        .padding(.bottom, padding) // Padding for safe area and spacing
        .background(
            Color(UIColor.systemBackground)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
        )
    }
}

// MARK: - ActionButton Component
struct ActionButton: View {
    let config: ButtonConfig
    
    var body: some View {
        Button(action: {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            config.action()
        }) {
            Image(systemName: config.iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(config.color ?? .primary)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(config.backgroundColor ?? Color.secondary.opacity(0.1))
                )
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - ButtonConfig Struct
struct ButtonConfig {
    let id = UUID()               // Unique identifier for the button
    let iconName: String          // System image name for the icon
    let action: () -> Void        // Action to perform on tap
    let color: Color?             // Optional foreground color
    let backgroundColor: Color?   // Optional background color
}

// MARK: - Preview
#Preview {
    BottomControlsView(
        onShare: { print("Share action triggered") },
        additionalActions: [
            ButtonConfig(
                iconName: "bookmark",
                action: { print("Bookmark action triggered") },
                color: .blue,
                backgroundColor: .blue.opacity(0.2)
            ),
            ButtonConfig(
                iconName: "heart",
                action: { print("Like action triggered") },
                color: .red,
                backgroundColor: .red.opacity(0.2)
            )
        ]
    )
}
