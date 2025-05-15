// This file is intentionally empty.
// It exists to ensure the MorningRadioiOS target has at least one source file.
// The actual functionality is provided by the ScreenCorners dependency.

import Foundation

#if os(iOS)
import ScreenCorners

public struct MorningRadioiOS {
    // This is a wrapper around ScreenCorners functionality
    // that will only be compiled for iOS targets
    
    public static func getDisplayCornerRadius() -> CGFloat {
        return UIScreen.main.displayCornerRadius
    }
}
#endif 