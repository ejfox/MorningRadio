//
//  BottomControlsView.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/26/24.
//

import SwiftUI

struct BottomControlsView: View {
    let currentIndex: Int
    let totalCount: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onShare: () -> Void
    
    var body: some View {
        HStack {
            // Previous Button
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Progress Indicators
            HStack(spacing: 6) {
                ForEach(0..<totalCount, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color.primary : Color.primary.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
            
            Spacer()
            
            // Share Button
            Button(action: onShare) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}
