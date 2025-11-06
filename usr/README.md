# Location to SMS App

A Flutter application that intercepts location shares from WhatsApp, extracts GPS coordinates, copies them to clipboard, and opens the SMS app with the coordinates pre-filled.

## Features

- 🌍 **Automatic Location Detection**: Recognizes multiple location formats (Google Maps URLs, geo: URIs, direct coordinates)
- 📋 **Auto-Copy**: Automatically copies coordinates to clipboard when received
- 💬 **SMS Integration**: Opens SMS app with pre-filled message containing coordinates and Google Maps link
- 📜 **History**: Maintains a list of recently shared locations
- ♻️ **Manual Actions**: Re-copy coordinates or re-open SMS app from the app interface

## How to Use

1. **Share a location from WhatsApp**:
   - Open WhatsApp and find a location message
   - Long-press the location
   - Select "Share" or "Forward"
   - Choose "Location to SMS" from the share menu

2. **Automatic Actions**:
   - The app will automatically extract coordinates
   - Coordinates are copied to your clipboard
   - SMS app opens with a pre-filled message

3. **Manual Controls**:
   - View extracted coordinates in the app
   - Tap copy icon to copy again
   - Tap message icon to open SMS again

## Supported Location Formats

- Google Maps URLs: `https://maps.google.com/?q=LAT,LON`
- Geo URIs: `geo:LAT,LON`
- Direct coordinates: `LAT, LON`

## Platform Requirements

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 33+
- Permissions: Query SMS intent (declared in manifest)

### iOS
- iOS 12.0+
- URL schemes configured for sharing
- SMS scheme query permission

## Dependencies

- `receive_sharing_intent`: ^1.8.0 - Intercepts shared content from other apps
- `url_launcher`: ^6.3.1 - Opens SMS app and URLs
- `clipboard`: ^0.1.3 - Manages clipboard operations

## Setup

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. For Android: No additional setup needed
4. For iOS: Run `pod install` in the ios directory
5. Run the app: `flutter run`

## Configuration Files

- **Android**: `android/app/src/main/AndroidManifest.xml` - Configured with SEND intent filter
- **iOS**: `ios/Runner/Info.plist` - Configured with URL schemes and query schemes

## Testing

1. Install the app on a physical device (simulators may not support sharing between apps)
2. Open WhatsApp
3. Find or send a location message
4. Share the location and select this app
5. Verify coordinates are copied and SMS app opens

## Notes

- The app must be installed on the device to appear in the share menu
- First time sharing may require app selection from share sheet
- SMS app will open with message pre-filled but no recipient selected
- Users can manually select recipient and edit message before sending

## Future Enhancements

- [ ] Support for multiple coordinate formats (DMS, UTM)
- [ ] Custom SMS message templates
- [ ] Contact selection within the app
- [ ] Location history with map view
- [ ] Export coordinates to different formats
- [ ] Share to multiple messaging apps (WhatsApp, Telegram, etc.)

## License

This project is a Flutter application template.
