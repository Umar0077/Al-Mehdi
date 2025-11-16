# Web Troubleshooting Guide

## 🔍 Common Web Issues & Solutions

### 1. **Project Not Opening on Web**

**Try these steps in order:**

#### Step 1: Clean and Rebuild
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

#### Step 2: Check Flutter Web Support
```bash
flutter doctor
```
Make sure web support is enabled.

#### Step 3: Enable Web Support (if not enabled)
```bash
flutter config --enable-web
```

#### Step 4: Check Dependencies
Make sure these web dependencies are in `pubspec.yaml`:
```yaml
dependencies:
  firebase_core_web: ^2.23.0
  firebase_auth_web: ^5.14.3
  firebase_messaging_web: ^3.9.8
  google_sign_in_web: ^0.12.4+4
```

### 2. **Firebase Web Issues**

#### Check Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: `sample-firebase-ai-app-456c6`
3. Go to **Project Settings > General**
4. Scroll down to **Your apps** section
5. Make sure web app is registered

#### Reconfigure Firebase for Web
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 3. **Browser Console Errors**

#### Check Browser Console
1. Open browser developer tools (F12)
2. Go to Console tab
3. Look for error messages
4. Common errors:
   - CORS issues
   - Firebase configuration errors
   - Missing dependencies

### 4. **CORS Issues**

If you see CORS errors:
1. Check Firebase Auth domain settings
2. Add your domain to authorized domains in Firebase Console
3. For local development, make sure `localhost` is in authorized domains

### 5. **Web-Specific Code Issues**

#### Notification Service
- ✅ Already fixed to skip on web platform
- ✅ Web-compatible initialization

#### Firebase Initialization
- ✅ Added error handling
- ✅ Web-specific persistence settings

### 6. **Performance Issues**

#### Optimize for Web
1. Use `kIsWeb` checks for platform-specific code
2. Lazy load heavy components
3. Use web-optimized packages

### 7. **Build Issues**

#### Debug Build
```bash
flutter build web --debug
```

#### Release Build
```bash
flutter build web --release
```

### 8. **Common Error Messages**

#### "Firebase not initialized"
- Check Firebase configuration
- Verify web app is registered in Firebase Console

#### "Package not found"
- Run `flutter pub get`
- Check package versions in pubspec.yaml

#### "CORS error"
- Add domain to Firebase authorized domains
- Check Firebase Auth settings

### 9. **Testing Steps**

1. **Clean build:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Run in debug mode:**
   ```bash
   flutter run -d chrome --web-port 8080
   ```

3. **Check console logs:**
   - Look for Firebase initialization messages
   - Check for any error messages

4. **Test basic functionality:**
   - App loads without errors
   - Firebase Auth works
   - Navigation works

### 10. **Alternative Solutions**

#### If web still doesn't work:
1. Try different browser (Chrome, Firefox, Edge)
2. Clear browser cache
3. Try incognito mode
4. Check if antivirus is blocking
5. Try different port: `flutter run -d chrome --web-port 8081`

### 11. **Next Steps**

If you're still having issues:
1. Share the exact error message from browser console
2. Share the output of `flutter doctor`
3. Share any build errors
4. Check if the issue is specific to your browser/OS

## 🚀 Quick Fix Commands

```bash
# Complete reset
flutter clean
flutter pub get
flutter run -d chrome

# If that doesn't work
flutter config --enable-web
flutter doctor
flutter run -d chrome
``` 