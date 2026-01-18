# Mobile Redirect & Deep Link Implementation

## Overview
This implementation automatically detects when your web app is accessed from a mobile browser and provides options to open the native app or download from app stores. It also handles deep links for seamless app opening.

## Features
- ✅ Automatic mobile browser detection
- ✅ Attempt to open installed native app via deep links
- ✅ Redirect to Play Store / App Store if app not installed
- ✅ PWA detection (skips redirect if already installed as PWA)
- ✅ Remote Config integration for easy enable/disable
- ✅ Beautiful UI with app branding
- ✅ Option to continue to web version

## Files Created

### 1. **MobileRedirectView** (`lib/views/misc/mobile_redirect_view.dart`)
Main view displayed to mobile browser users with:
- App logo and branding
- "Open in App" button
- "Download from Store" button
- "Continue to web" option
- Features list highlighting app benefits
- Automatic deep link attempt on load

### 2. **PlatformDetector** (`lib/services/platform_detector.dart`)
Utility service for detecting:
- Mobile browsers (Android/iOS)
- Specific platforms
- PWA mode
- User agent information

### 3. **MobileRedirectWrapper** (`lib/components/mobile_redirect_wrapper.dart`)
Wrapper widget that conditionally shows mobile redirect based on:
- Platform detection
- Remote Config settings
- PWA status

## Configuration

### Firebase Remote Config Keys
Add these keys to your Firebase Remote Config:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `enable_mobile_redirect` | Boolean | `true` | Enable/disable mobile redirect feature |
| `enable_deep_linking` | Boolean | `true` | Enable/disable deep link attempts |
| `deep_link_scheme_android` | String | `almehdi://` | Android app URL scheme |
| `deep_link_scheme_ios` | String | `almehdi://` | iOS app URL scheme |
| `android_package_name` | String | `com.almehdi.onlineschool` | Android package name |
| `play_store_url` | String | *(see below)* | Full Play Store URL |
| `app_store_url` | String | *(see below)* | Full App Store URL |
| `deep_link_timeout_ms` | Number | `2500` | Timeout before showing UI |

**Default URLs:**
- Play Store: `https://play.google.com/store/apps/details?id=com.almehdi.onlineschool`
- App Store: `https://apps.apple.com/app/id123456789` (update with your app ID)

### Update App Store URL
In [`mobile_redirect_view.dart`](lib/views/misc/mobile_redirect_view.dart):
```dart
static const String _appStoreUrl = 'https://apps.apple.com/app/id123456789';
```
Replace `123456789` with your actual App Store ID.

## How It Works

### Flow Diagram
```
User Opens Web URL
       ↓
Is it a mobile browser? ────NO───→ Show normal web app
       ↓ YES
       ↓
Is it running as PWA? ────YES───→ Show normal web app
       ↓ NO
       ↓
Is redirect enabled? ────NO───→ Show normal web app
       ↓ YES
       ↓
Show Loading Screen
       ↓
Attempt Deep Link (2.5s)
       ↓
   Did app open? ────YES───→ User sees native app
       ↓ NO
       ↓
Show Mobile Redirect View
(with options to download or continue)
```

### Deep Link Handling

**Android:**
1. Tries custom URL scheme: `almehdi://open`
2. Falls back to Android Intent URL
3. Includes Play Store fallback in intent

**iOS:**
1. Tries custom URL scheme: `almehdi://open`
2. If fails, user can click to open App Store

## Usage

### Basic Setup (Already Integrated)
The mobile redirect is automatically active in your app via the `MobileRedirectWrapper` in `main.dart`:

```dart
home: MobileRedirectWrapper(
  child: const AppInitializer(),
),
```

### Manual Control
To force show the redirect view:
```dart
MobileRedirectWrapper(
  forceShowRedirect: true,
  child: YourWidget(),
)
```

### Disable Redirect
Via Remote Config:
1. Set `enable_mobile_redirect` to `false`
2. Changes take effect on next app launch

Or programmatically:
```dart
if (!RemoteConfigService.instance.isMobileRedirectEnabled) {
  // Skip redirect
}
```

### Check Platform
```dart
import 'package:al_mehdi_online_school/services/platform_detector.dart';

// Check if mobile browser
if (PlatformDetector.isMobileBrowser()) {
  print('User is on mobile browser');
}

// Check specific platform
if (PlatformDetector.isAndroidBrowser()) {
  print('Android browser detected');
}

// Check if PWA
if (PlatformDetector.isPWA()) {
  print('Running as PWA');
}
```

## Testing

### Test on Mobile Browser
1. Run your web app: `flutter run -d chrome`
2. Open Chrome DevTools (F12)
3. Toggle device toolbar (Ctrl+Shift+M)
4. Select a mobile device (e.g., iPhone 12)
5. Reload the page
6. You should see the mobile redirect view

### Test Deep Links
**Android:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "almehdi://open" com.almehdi.onlineschool
```

**iOS:**
```bash
xcrun simctl openurl booted "almehdi://open"
```

### Test URL Schemes
Ensure your URL schemes are properly configured:
- [iOS Info.plist](../ios/Runner/Info.plist) - Check `CFBundleURLSchemes`
- [Android Manifest](../android/app/src/main/AndroidManifest.xml) - Check intent filters

## Customization

### Change Colors/Styling
Edit [`mobile_redirect_view.dart`](lib/views/misc/mobile_redirect_view.dart):
```dart
// Primary color
backgroundColor: appGreen  // Change to your color

// Gradient
colors: [
  yourColor.withOpacity(0.1),
  Colors.white,
  yourColor.withOpacity(0.05),
]
```

### Change App Icon
Replace the icon in the view:
```dart
Image.asset(
  'assets/icon/your-icon.png',  // Your icon path
  width: 100,
  height: 100,
)
```

### Modify Features List
Update the features shown:
```dart
_buildFeatureItem(Icons.your_icon, 'Your Feature'),
```

### Change Timeout Duration
In Remote Config or in code:
```dart
await Future.delayed(const Duration(seconds: 3));  // Adjust duration
```

## Troubleshooting

### Redirect Not Showing
1. Check Remote Config: `enable_mobile_redirect` = `true`
2. Verify mobile browser detection
3. Check if PWA mode is active
4. Clear browser cache and test again

### Deep Links Not Working
1. Verify URL schemes in Info.plist (iOS) and AndroidManifest.xml
2. Ensure app is installed on device
3. Check URL scheme format (must match exactly)
4. Test with adb/xcrun commands above

### Store URLs Not Opening
1. Update App Store ID in the code
2. Verify Play Store URL matches your package name
3. Check browser popup blocker settings

## Analytics (Optional)
To track redirect usage, add analytics in [`mobile_redirect_view.dart`](lib/views/misc/mobile_redirect_view.dart):

```dart
void _trackEvent(String event) {
  // Add your analytics here
  FirebaseAnalytics.instance.logEvent(
    name: 'mobile_redirect',
    parameters: {'action': event},
  );
}

// Call in button handlers
void _openStore() {
  _trackEvent('open_store');
  // ... existing code
}
```

## Benefits
- ✅ Better user experience on mobile
- ✅ Higher app install conversion
- ✅ Seamless transition between web and native app
- ✅ Reduced bounce rate on mobile web
- ✅ Professional appearance
- ✅ Easy to enable/disable remotely

## Next Steps
1. Update App Store ID in the code
2. Test on real mobile devices
3. Configure Remote Config in Firebase Console
4. Monitor user behavior and conversion rates
5. Adjust timeout/styling as needed
