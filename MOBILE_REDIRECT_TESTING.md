# Testing the Mobile Redirect View

## Quick Test on Desktop Browser

### Using Chrome DevTools

1. **Run your Flutter web app:**
   ```bash
   flutter run -d chrome
   ```

2. **Open Chrome DevTools:**
   - Press `F12` or right-click and select "Inspect"

3. **Toggle Device Toolbar:**
   - Press `Ctrl+Shift+M` (Windows/Linux) or `Cmd+Shift+M` (Mac)
   - Or click the device icon in DevTools toolbar

4. **Select a Mobile Device:**
   - Choose from the dropdown: iPhone 12, Pixel 5, etc.
   - Or create a custom device

5. **Reload the Page:**
   - Press `Ctrl+R` or `Cmd+R`
   - You should now see the Mobile Redirect View!

### Expected Behavior
- ✅ Shows loading screen for ~2 seconds
- ✅ Then displays the mobile redirect view with:
  - App logo
  - "Open in App" button
  - "Get it on Play Store" or "Download on App Store" button
  - "Continue to web version" link
  - Features list at bottom

## Testing Deep Links

### Android (Using ADB)

**Prerequisites:**
- Android device/emulator connected
- App installed on device
- USB debugging enabled

**Test Command:**
```bash
adb shell am start -W -a android.intent.action.VIEW \
  -d "almehdi://open" com.almehdi.onlineschool
```

**Expected Result:**
- App should open to the home screen
- If app not installed, nothing happens

### iOS (Using Simulator)

**Prerequisites:**
- iOS Simulator running
- App installed on simulator

**Test Command:**
```bash
xcrun simctl openurl booted "almehdi://open"
```

**Expected Result:**
- App should open to the home screen
- If app not installed, Safari may open

### Test from Mobile Browser

1. **Deploy to test server or use Firebase Hosting:**
   ```bash
   flutter build web
   firebase deploy --only hosting
   ```

2. **Open URL on physical mobile device**

3. **Expected Flow:**
   - Loading screen appears
   - Attempts to open native app
   - If app installed → Opens app
   - If app not installed → Shows redirect view with store buttons

## Testing Remote Config Toggle

### Enable/Disable Mobile Redirect

1. **Go to Firebase Console:**
   - Navigate to Remote Config section
   - Find `enable_mobile_redirect` parameter

2. **Toggle Value:**
   - Set to `false` to disable mobile redirect
   - Set to `true` to enable mobile redirect

3. **Test:**
   - Close and reopen app
   - Mobile redirect should respect the config value

### Test in Debug Mode

Update Remote Config fetch interval for faster testing:
```dart
// In remote_config_service.dart (already set)
minimumFetchInterval: kDebugMode 
    ? const Duration(minutes: 1)  // 1 minute in debug
    : const Duration(hours: 1)     // 1 hour in production
```

## Browser Compatibility Testing

### Recommended Browsers to Test

**Android:**
- ✅ Chrome
- ✅ Firefox
- ✅ Samsung Internet
- ✅ Edge

**iOS:**
- ✅ Safari
- ✅ Chrome (uses Safari engine)
- ✅ Firefox (uses Safari engine)

### User Agent Strings Detected

The view detects these user agents:
- `android`
- `iphone`
- `ipad`
- `ipod`
- `mobile`

## PWA Testing

### Install as PWA

1. **On Mobile Chrome:**
   - Open your web app
   - Tap the menu (⋮)
   - Select "Add to Home Screen"
   - Confirm installation

2. **Expected Behavior:**
   - When opened from home screen
   - Should NOT show mobile redirect
   - Goes directly to main app

### Verify PWA Detection

In browser console:
```javascript
// Check if running as PWA
window.matchMedia('(display-mode: standalone)').matches
// Should return true if PWA, false if browser
```

## Troubleshooting

### Issue: Redirect Not Showing

**Check:**
1. Are you using mobile device mode in DevTools?
2. Is `enable_mobile_redirect` set to `true` in Remote Config?
3. Is the app running as PWA? (shouldn't show redirect)
4. Clear browser cache and try again

**Debug:**
```dart
// Add to PlatformDetector
print('Is Mobile: ${PlatformDetector.isMobileBrowser()}');
print('Is PWA: ${PlatformDetector.isPWA()}');
print('User Agent: ${PlatformDetector.getUserAgent()}');
```

### Issue: Deep Links Not Working

**Check:**
1. Is URL scheme configured in Info.plist (iOS)?
2. Is intent filter configured in AndroidManifest.xml?
3. Is the app actually installed?
4. Does URL scheme match exactly? (`almehdi://`)

**Debug:**
```bash
# Android - Check if URL scheme is registered
adb shell dumpsys package com.almehdi.onlineschool | grep scheme

# iOS - Check URL schemes in installed app
xcrun simctl get_app_container booted com.almehdi.onlineschool
```

### Issue: Buttons Not Working

**Check:**
1. Are store URLs configured correctly?
2. Check browser console for errors (F12)
3. Is popup blocker enabled? (may block store opening)

**Test Store URLs:**
```javascript
// In browser console
window.open('https://play.google.com/store/apps/details?id=com.almehdi.onlineschool', '_blank');
```

## Performance Testing

### Load Time
- Loading screen: ~500ms
- Deep link attempt: ~2000ms
- UI display: Immediate after timeout

### Expected Timeline
```
0ms     - Component mounted
500ms   - Start deep link attempt
2500ms  - Timeout, show UI
```

### Optimize If Needed
Adjust timeout in [`mobile_redirect_view.dart`](lib/views/misc/mobile_redirect_view.dart):
```dart
await Future.delayed(const Duration(seconds: 2));  // Change this
```

## User Experience Testing

### Test Scenarios

1. **First-time mobile user (app not installed)**
   - Should see: Loading → Redirect view → Click store button → Redirect to store

2. **Returning mobile user (app installed)**
   - Should see: Loading → App opens directly

3. **Desktop user**
   - Should see: Normal web app (no redirect)

4. **PWA user**
   - Should see: Normal web app (no redirect)

5. **User who clicks "Continue to web"**
   - Should see: Main web app interface

## Automated Testing (Optional)

Create widget tests:
```dart
testWidgets('Mobile redirect shows on mobile', (WidgetTester tester) async {
  await tester.pumpWidget(const MobileRedirectView());
  await tester.pumpAndSettle();
  
  expect(find.text('Al-Mehdi Online School'), findsOneWidget);
  expect(find.text('Open in App'), findsOneWidget);
});
```

## Analytics Tracking (Recommended)

Add to track user behavior:
```dart
// When user clicks "Open in App"
FirebaseAnalytics.instance.logEvent(name: 'mobile_redirect_open_app');

// When user clicks store button
FirebaseAnalytics.instance.logEvent(name: 'mobile_redirect_to_store');

// When user continues to web
FirebaseAnalytics.instance.logEvent(name: 'mobile_redirect_continue_web');
```

## Checklist

Before deploying to production:

- [ ] Tested on physical Android device
- [ ] Tested on physical iOS device
- [ ] Verified deep links work on both platforms
- [ ] Updated App Store ID in code
- [ ] Configured Remote Config parameters
- [ ] Tested with PWA installation
- [ ] Verified "Continue to web" works
- [ ] Store URLs open correctly
- [ ] UI looks good on various screen sizes
- [ ] No console errors in browser DevTools
- [ ] Remote Config toggle works
- [ ] Loading timeout feels appropriate
