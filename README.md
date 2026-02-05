# Persistent Cloud Anchor Example

An iOS AR application demonstrating Google ARCore Cloud Anchors with persistent storage using Firebase Realtime Database and visual line rendering between anchors.

## Features

- **Cloud Anchor Creation**: Create and host AR anchors in physical space that persist across sessions
- **Firebase Integration**: Store and retrieve cloud anchors from Firebase Realtime Database
- **Cross-Device Sharing**: Anchors can be resolved on any device with the anchor ID
- **Line Rendering**: Visualize connections between resolved anchors with directional chevron arrows
- **Quality Indicators**: Real-time feedback on anchor hosting quality

## Requirements

- iOS 15.0+
- Xcode 14.0+
- ARCore SDK 1.52.0
- Firebase account with Realtime Database enabled
- Physical iOS device with ARKit support (iPhone 6s or newer)

## Setup

### 1. Install Dependencies

The project uses CocoaPods for dependency management:

```bash
cd PersistentCloudAnchorExample
pod install
```

Always open `PersistentCloudAnchorExample.xcworkspace` (not `.xcodeproj`) after installing pods.

### 2. Configure Firebase

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add an iOS app to your Firebase project
3. Download `GoogleService-Info.plist`
4. Replace the existing `GoogleService-Info.plist` in the `PersistentCloudAnchorExample` folder
5. Enable Firebase Realtime Database:
   - Go to Database section in Firebase Console
   - Create a Realtime Database
   - Start in **test mode** for development (update rules for production)

### 3. Configure ARCore Cloud Anchors

1. Enable the ARCore API in Google Cloud Console
2. Create an API key for your iOS app
3. Add API key restrictions for iOS apps (optional but recommended)

## Project Structure

```
PersistentCloudAnchorExample/
├── CloudAnchorManager.swift      # Core AR anchor management and Firebase sync
├── LineRenderer.swift             # 3D line and arrow visualization
├── ARViewContainer.swift          # SwiftUI ARView wrapper
├── CloudAnchorView.swift          # Main AR view with hosting UI
├── ResolvePickerView.swift        # Anchor selection and resolution UI
├── ContentView.swift              # App entry point
├── AnchorInfo.swift               # Data model for cloud anchors
├── QualityIndicator.swift         # Hosting quality UI component
└── GoogleService-Info.plist       # Firebase configuration
```

## Usage

### Creating Cloud Anchors

1. Launch the app and grant camera permissions
2. Tap anywhere in the AR view to place an anchor
3. Enter a name for the anchor when prompted
4. Wait for the quality indicator to reach "SUFFICIENT" or "GOOD"
5. The anchor will be automatically hosted and saved to Firebase

### Resolving Cloud Anchors

1. Tap the "View anchors" button in the top right
2. See a list of available anchors (local + Firebase)
3. Select one or more anchors to resolve
4. Tap **"Resolve"** to place the anchors in AR
5. Tap **"Draw Lines"** to visualize connections between resolved anchors with directional arrows

### Line Visualization

When you resolve 2+ anchors and tap "Draw Lines":

- Purple semi-transparent lines connect anchors in sequence
- White chevron arrows indicate direction from first to last anchor
- Lines are rendered flat on the ground plane for better visibility

## Firebase Database Structure

```json
{
  "cloudAnchors": {
    "{cloudAnchorId}": {
      "anchorId": "ua_xxx...",
      "name": "My Anchor",
      "timestamp": 1738598400000
    }
  }
}
```

Anchors older than 24 hours are automatically filtered out when fetching.

## Technical Details

### Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **ARKit**: Apple's augmented reality framework
- **RealityKit**: 3D rendering and entity management
- **ARCore SDK**: Google's cross-platform AR solution
- **Firebase Realtime Database**: Cloud storage for anchor data
- **CocoaPods**: Dependency management

### Line Rendering Implementation

- Uses RealityKit `ModelEntity` with box meshes for lines and arrows
- Flat geometry (thin height) for 2D appearance on ground plane
- Quaternion-based rotation for proper orientation
- Semi-transparent materials to avoid obscuring AR content
- Vertical offset to prevent z-fighting with ground

## Android Companion App

A companion Android app is available here:

```
https://github.com/walkeknow/arcore-cloud-anchor-nav-android
```

Android and iOS apps can share cloud anchors through Firebase, enabling cross-platform AR experiences.

## License

This project uses the ARCore SDK which is subject to the [ARCore SDK Terms of Service](https://developers.google.com/ar/develop/terms).

## Resources

- [ARCore Cloud Anchors Guide](https://developers.google.com/ar/develop/ios/cloud-anchors/overview-ios)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [RealityKit Documentation](https://developer.apple.com/documentation/realitykit/)
- [ARKit Documentation](https://developer.apple.com/documentation/arkit/)
