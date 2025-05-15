//
//  UtilityViews.swift
//  MorningRadio
//
//  Created by EJ Fox on 11/16/24.
//

import SwiftUI


// MARK: - ErrorView
struct ErrorView: View {
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            Text("Something went wrong.")
                .font(.title3)
                .foregroundColor(.white)
            Button(action: retryAction) {
                Text("Retry")
                    .bold()
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
            }
            Spacer()
        }
        .padding()
        .background(Color.black)
    }
}

// MARK: - BlurView
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - CircularProgressView
struct CircularProgressView: View {
    let progress: Double
    var lineWidth: CGFloat = 4
    var size: CGFloat = 40
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.3)
                .foregroundColor(.gray)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(.blue)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100))%")
    }
}
