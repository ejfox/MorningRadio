import SwiftUI
import Combine

struct LoadingView: View {
    @State private var orbitAngle: Double = 0.0
    @State private var opacity: Double = 0.0
    @State private var loadingText: [String] = Array(repeating: "", count: 6) // 6 elements for "WAKEUP"
    @State private var hudValues: [Double] = Array(repeating: 0, count: 5)
    @State private var subtleOffset: CGSize = .zero
    
    private let orbitDuration: Double = 10.0 // Slower animation for smoothness
    private let circleSize: CGFloat = 200
    private let orbitRadius: CGFloat = 60
    private let word = "WAKEUP"
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    private let subtleAnimation = Animation.easeInOut(duration: 5.0).repeatForever(autoreverses: true)
    
    // Date Formatter
    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d" // Example: Tuesday, Sep 14
        return formatter.string(from: Date())
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Light Background with Subtle Moving Overlay
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color(white: 0.95)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Orbital Visualization
                    ZStack {
                        OrbitalCircle(
                            orbitAngle: orbitAngle,
                            orbitRadius: orbitRadius,
                            circleSize: circleSize,
                            color: Color.black.opacity(0.2)
                        )
                        .animation(
                            Animation.timingCurve(0.25, 0.1, 0.25, 1.0, duration: orbitDuration)
                                .repeatForever(autoreverses: false),
                            value: orbitAngle
                        )
                        
                        CentralAccentCircle(
                            orbitAngle: orbitAngle,
                            orbitRadius: orbitRadius,
                            size: 20,
                            color: Color.red
                        )
                        .animation(
                            Animation.timingCurve(0.25, 0.1, 0.25, 1.0, duration: orbitDuration)
                                .repeatForever(autoreverses: false),
                            value: orbitAngle
                        )
                    }
                    .offset(subtleOffset)
                    .animation(subtleAnimation, value: subtleOffset)
                    
                    // HUD Elements with Subtle Movement
                    HStack(spacing: 30) {
                        // Simplified Bar Charts
                        HUDBarChart(hudValues: hudValues)
                            .offset(subtleOffset)
                            .animation(subtleAnimation, value: subtleOffset)
                        
                        // Loading Text
                        LoadingTextView(
                            loadingText: loadingText,
                            opacity: opacity
                        )
                        .offset(subtleOffset)
                        .animation(subtleAnimation, value: subtleOffset)
                        
                        // Pop of Color Element (Red Circular Indicator) with Subtle Movement
                        AccentIndicator(opacity: opacity)
                            .offset(subtleOffset)
                            .animation(subtleAnimation, value: subtleOffset)
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Metadata Elements as Border Text
                BorderTextView(
                    topText: currentDate,
                    bottomText: "Morning Radio",
                    leftText: "🌅",
                    rightText: "📻"
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .onAppear {
                // Fade In Animation
                withAnimation(Animation.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 1.5)) {
                    opacity = 1
                }
                
                // Start Orbit Animation
                orbitAngle = 360
                
                // Start Subtle Movement Animation
                subtleOffset = CGSize(width: 10, height: 10)
                
                // Animate Loading Text
                animateText()
            }
            .onReceive(timer) { _ in
                updateHUDValues()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func animateText() {
        for (index, _) in word.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                if index < loadingText.count {
                    let char = word[word.index(word.startIndex, offsetBy: index)]
                    loadingText[index] = String(char)
                }
            }
        }
    }
    
    private func updateHUDValues() {
        for i in 0..<hudValues.count {
            hudValues[i] = Double.random(in: 0.3...1.0)
        }
    }
}

// MARK: - Subviews

struct OrbitalCircle: View {
    var orbitAngle: Double
    var orbitRadius: CGFloat
    var circleSize: CGFloat
    var color: Color
    
    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .frame(width: circleSize, height: circleSize)
            .offset(
                x: cos(Angle(degrees: orbitAngle).radians) * orbitRadius,
                y: sin(Angle(degrees: orbitAngle).radians) * orbitRadius
            )
    }
}

struct CentralAccentCircle: View {
    var orbitAngle: Double
    var orbitRadius: CGFloat
    var size: CGFloat
    var color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.6), radius: 4, x: 0, y: 0)
            .offset(
                x: cos(Angle(degrees: orbitAngle).radians) * orbitRadius,
                y: sin(Angle(degrees: orbitAngle).radians) * orbitRadius
            )
    }
}

struct HUDBarChart: View {
    var hudValues: [Double]
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<hudValues.count, id: \.self) { index in
                VStack(spacing: 3) {
                    ForEach(0..<10, id: \.self) { barIndex in
                        Rectangle()
                            .fill(barIndex < Int(hudValues[index] * 10) ? Color.black : Color.black.opacity(0.1))
                            .frame(width: 3, height: 6)
                            .animation(.easeInOut(duration: 0.5), value: hudValues[index])
                    }
                }
            }
        }
    }
}

struct LoadingTextView: View {
    var loadingText: [String]
    var opacity: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(0..<loadingText.count, id: \.self) { index in
                Text(loadingText[index])
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .opacity(opacity)
                    .animation(.easeInOut(duration: 1.0), value: opacity)
            }
        }
    }
}

struct AccentIndicator: View {
    var opacity: Double
    
    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 15, height: 15)
            .scaleEffect(opacity == 1 ? 1.0 : 0.5)
            .shadow(color: Color.red.opacity(0.6), radius: 4, x: 0, y: 0)
            .animation(
                Animation.timingCurve(0.25, 0.1, 0.25, 1.0, duration: 1.0)
                    .repeatForever(autoreverses: true),
                value: opacity
            )
    }
}

struct BorderTextView: View {
    var topText: String
    var bottomText: String
    var leftText: String
    var rightText: String
    
    var body: some View {
        ZStack {
            // Top Border Text
            HStack {
                Spacer()
                Text(topText)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(.black.opacity(0.6))
                    .rotationEffect(.degrees(0))
                Spacer()
            }
            .padding(.top, 5)
            
            // Bottom Border Text
            HStack {
                Spacer()
                Text(bottomText)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(.black.opacity(0.6))
                    .rotationEffect(.degrees(0))
                Spacer()
            }
            .padding(.bottom, 5)
            
            // Left Border Text
            VStack {
                Spacer()
                Text(leftText)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(.black.opacity(0.6))
                    .rotationEffect(.degrees(-90))
                Spacer()
            }
            .padding(.leading, 5)
            
            // Right Border Text
            VStack {
                Spacer()
                Text(rightText)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundColor(.black.opacity(0.6))
                    .rotationEffect(.degrees(90))
                Spacer()
            }
            .padding(.trailing, 5)
        }
    }
}

#Preview {
    LoadingView()
}
