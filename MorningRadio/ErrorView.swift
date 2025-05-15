import SwiftUI

struct ErrorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var settings: UserSettings
    
    let retryAction: () -> Void
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .accessibilityHidden(true)
                
                Text("Unable to Load Content")
                    .dynamicFont(.title2)
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                
                Text("There was a problem connecting to the server. Please check your internet connection and try again.")
                    .dynamicFont(.body)
                    .foregroundColor(textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: retryAction) {
                    Text("Try Again")
                        .dynamicFont(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .padding(.top, 16)
                .accessibilityHint("Attempts to reload the content")
            }
            .padding()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error loading content")
    }
}

#Preview {
    ErrorView(retryAction: {})
        .environmentObject(UserSettings.shared)
} 