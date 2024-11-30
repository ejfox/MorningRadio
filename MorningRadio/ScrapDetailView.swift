import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

public struct ScrapDetailView: View {
    // MARK: - Properties
    let scrap: Scrap
    let uiImage: UIImage?
    let dismissAction: () -> Void
    
    // MARK: - State
    @State private var showShareSheet = false
    @State private var isAppearing = false
    @State private var currentFactIndex = 0
    @Environment(\.colorScheme) private var colorScheme
    @GestureState private var dragState = DragState.inactive
    @State private var position: CGFloat = 0
    
    // MARK: - Constants
    private let navigationBarHeight: CGFloat = 0.08
    private let horizontalPadding: CGFloat = 24
    private let verticalSpacing: CGFloat = 24
    
    // Animation timing curves
    private let appearanceAnimation = Animation.easeOut(duration: 0.8)
    private let carouselAnimation = Animation.easeInOut(duration: 0.3)
    private let springAnimation = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    // MARK: - Helper Properties
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.1, green: 0.1, blue: 0.2) : Color(red: 0.95, green: 0.95, blue: 0.97)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var facts: [String] {
        processFacts(from: scrap.summary)
    }
    
    // MARK: - View Body
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Title section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(scrap.content.sanitizedHTML())
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(textColor)
                            .multilineTextAlignment(.leading)
                            .padding(.top, geometry.size.height * navigationBarHeight)
                        
                        if let url = scrap.url {
                            Text(url)
                                .font(.system(size: 14, weight: .regular, design: .monospaced))
                                .foregroundColor(textColor.opacity(0.6))
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    
                    // Facts Content Area
                    if !facts.isEmpty {
                        FactCarouselView(
                            facts: facts,
                            currentIndex: $currentFactIndex,
                            onFactChange: { _ in
                                HapticFeedback.light()
                            }
                        )
                        .frame(height: geometry.size.height * 0.6)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(carouselAnimation) {
                                if currentFactIndex == facts.count - 1 {
                                    dismissAction()
                                } else {
                                    currentFactIndex = (currentFactIndex + 1) % facts.count
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom Controls
                    BottomControlsView(
                        currentIndex: currentFactIndex,
                        totalCount: facts.count,
                        onPrevious: { navigateFacts(forward: false) },
                        onNext: { navigateFacts(forward: true) },
                        onShare: { showShareSheet = true }
                    )
                }
            }
            .gesture(makeDismissGesture(geometry: geometry))
            .offset(y: dragState.translation + position)
            .animation(.interactiveSpring(), value: dragState.translation)
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(scrap: scrap)
        }
    }
    
    // MARK: - Helper Functions
    private func processFacts(from summary: String?) -> [String] {
        guard let summary = summary else { return [] }
        return summary.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    private func navigateFacts(forward: Bool) {
        withAnimation(carouselAnimation) {
            if forward && currentFactIndex == facts.count - 1 {
                dismissAction()
            } else {
                currentFactIndex = (currentFactIndex + (forward ? 1 : -1) + facts.count) % facts.count
            }
        }
    }
    
    private func makeDismissGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .updating($dragState) { value, state, _ in
                state = .dragging(translation: value.translation.height)
            }
            .onEnded { value in
                let verticalVelocity = value.predictedEndLocation.y - value.location.y
                let shouldDismiss = value.translation.height > 100 || verticalVelocity > 500
                
                withAnimation(springAnimation) {
                    position = shouldDismiss ? geometry.size.height : 0
                    if shouldDismiss {
                        dismissAction()
                    }
                }
            }
    }
}
