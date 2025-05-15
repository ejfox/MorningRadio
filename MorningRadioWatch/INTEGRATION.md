# Integrating the Watch Extension

This document provides step-by-step instructions for integrating the Morning Radio Watch extension with the main iOS app.

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ deployment target for the main app
- watchOS 10.0+ deployment target for the Watch extension

## Steps to Integrate

### 1. Add the Watch Extension Target

1. Open the MorningRadio Xcode project
2. Go to File > New > Target...
3. Select "Watch App" from the template list
4. Configure the target:
   - Name: "MorningRadio Watch"
   - Interface: SwiftUI
   - Language: Swift
   - Include Notification Scene: Optional
   - Include Complication: Yes
5. Click "Finish"

### 2. Copy Files from the MorningRadioWatch Directory

1. Copy all files from the `MorningRadioWatch/Sources` directory to the newly created Watch app target
2. Make sure to add them to the correct target (the Watch app)

### 3. Configure App Groups (for Shared Data)

1. Go to the Signing & Capabilities tab for both the iOS app and Watch app targets
2. Click "+ Capability" and add "App Groups"
3. Create a new app group with an identifier like "group.com.yourcompany.morningradio"
4. Add this app group to both targets

### 4. Update Bundle Identifiers

1. Ensure the Watch app's bundle identifier is related to the main app's identifier
   - Main app: com.yourcompany.MorningRadio
   - Watch app: com.yourcompany.MorningRadio.watchapp

### 5. Configure Watch Connectivity (Optional)

If you need to communicate between the iOS app and Watch app:

1. Add the following code to both apps:

```swift
import WatchConnectivity

class ConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = ConnectivityManager()
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle activation
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session on iOS
        WCSession.default.activate()
    }
    #endif
    
    // Send data to counterpart
    func sendMessage(_ message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil)
        }
    }
}
```

### 6. Test the Integration

1. Select the Watch scheme in Xcode
2. Run the app on a paired Watch simulator or device
3. Verify that the app launches correctly and can fetch data

## Troubleshooting

- **Connectivity Issues**: Ensure both devices are paired and the Watch app is installed
- **Data Sharing Issues**: Verify app group configuration is correct
- **Build Errors**: Make sure all required frameworks are linked correctly

## Next Steps

- Consider adding complications for quick access to the latest content
- Implement background refresh for up-to-date information
- Add support for notifications to alert users of new content 