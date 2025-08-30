# MET Predictor iOS App

## Quick Setup Instructions

### Prerequisites
- Xcode 14.0 or later
- iOS 15.0 or later
- iPhone device for testing

### Setup Steps

1. **Open in Xcode:**
   ```bash
   cd ios-app
   open METPredictor.xcodeproj
   ```

2. **Configure Team & Bundle ID:**
   - Select project in navigator
   - Under "Signing & Capabilities", select your team
   - Change Bundle Identifier to unique ID (e.g., com.yourname.metpredictor)

3. **Build & Run:**
   - Connect iPhone
   - Select iPhone as target
   - Press Cmd+R to build and run

### App Features
- ✅ Real-time accelerometer data collection
- ✅ On-device MET classification
- ✅ Daily time tracking per MET class
- ✅ Clean, updating UI
- ✅ Background processing capability

### Key Files
- `ContentView.swift` - Main UI
- `METPredictor.swift` - Core ML model integration
- `AccelerometerManager.swift` - Sensor data handling
- `TimeTracker.swift` - Daily time accumulation

### Deployment Notes
- App uses Core Motion framework (requires device, not simulator)
- Model runs entirely on-device
- No internet connection required
- Automatically requests motion permissions
