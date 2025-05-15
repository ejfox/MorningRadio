# Integrating the Morning Radio Widget

This document provides step-by-step instructions for integrating the Morning Radio Widget with the main iOS app.

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- WidgetKit framework

## Steps to Integrate

### 1. Add the Widget Extension Target

1. Open the MorningRadio Xcode project
2. Go to File > New > Target...
3. Select "Widget Extension" from the template list
4. Configure the target:
   - Name: "MorningRadioWidget"
   - Interface: SwiftUI
   - Include Live Activity: No (unless you want to add this feature later)
   - Include Lock Screen Widget: Yes
   - Include App Intents: No (unless you want to add configuration options)
5. Click "Finish"

### 2. Copy Files from the MorningRadioWidget Directory

1. Copy all files from the `MorningRadioWidget` directory to the newly created widget target
2. Make sure to add them to the correct target (the widget extension)

### 3. Configure URL Scheme for Widget Taps

1. Go to the main app target's Info tab
2. Add a URL Type:
   - Identifier: com.yourcompany.morningradio
   - URL Schemes: morningradio
3. In your main app's SceneDelegate or App struct, add code to handle the URL:

```swift
// In SwiftUI App
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    
    if url.scheme == "morningradio" {
        if url.host == "latest" {
            // Navigate to the latest scrap
            // This depends on your app's navigation structure
        }
    }
}
```

### 4. Configure App Groups (Optional, for Shared Data)

If you want to share data between the app and widget:

1. Go to the Signing & Capabilities tab for both the iOS app and widget targets
2. Click "+ Capability" and add "App Groups"
3. Create a new app group with an identifier like "group.com.yourcompany.morningradio"
4. Add this app group to both targets
5. Update your data storage to use this shared container

### 5. Test the Widget

1. Run the widget extension scheme in Xcode
2. Add the widget to your home screen in the simulator or device
3. Verify that it displays correctly and updates as expected
4. Test tapping the widget to ensure it opens the app correctly

## Troubleshooting

- **Widget Not Updating**: Check your timeline configuration and make sure your provider is returning valid entries
- **Images Not Loading**: Verify network permissions in the widget's Info.plist
- **Widget Taps Not Working**: Ensure your URL scheme is correctly configured and handled in the main app

## Next Steps

- Consider adding widget configuration options using App Intents
- Implement a medium and large widget with more detailed content
- Add a Live Activity for real-time updates (if applicable)
- Create multiple widget types for different content categories 