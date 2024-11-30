import SwiftUI

public enum DragState {
    case inactive
    case dragging(translation: CGFloat)
    
    public var translation: CGFloat {
        switch self {
        case .inactive: return 0
        case .dragging(let t): return t
        }
    }
}

public struct DragDismissModifier: ViewModifier {
    public let dragState: DragState
    public let position: CGFloat
    public let geometry: GeometryProxy
    public let isAppearing: Bool
    
    private var dragPercentage: CGFloat {
        let translation = dragState.translation + position
        return min(1, max(0, translation / 200))
    }
    
    public func body(content: Content) -> some View {
        content
            .offset(y: dragState.translation + position)
            .opacity(1.0 - (dragPercentage * 0.3))
            .scaleEffect(1.0 - (dragPercentage * 0.03))
    }
} 