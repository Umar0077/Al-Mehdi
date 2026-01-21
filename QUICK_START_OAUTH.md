# Quick Start Guide: OAuth Auto-Fill Setup

## Prerequisites

✅ Your app already has:
- Firebase Authentication configured
- Apple Sign In configured
- Google Sign In configured
- Firestore database

## Step 1: Add Firestore Security Rules

Add these rules to your Firestore security rules (Firebase Console):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ... your existing rules ...
    
    // OAuth users collection - users can read/write their own data
    match /oauth_users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 2: No Code Changes Needed!

All code changes have been implemented. The following files were modified:

1. ✅ `lib/models/oauth_user_data.dart` - NEW
2. ✅ `lib/providers/auth/auth_provider.dart` - UPDATED
3. ✅ `lib/views/authentication/student_registeration_view.dart` - UPDATED
4. ✅ `lib/views/authentication/teacher_registration_view.dart` - UPDATED
5. ✅ `lib/components/Custom_Textfield.dart` - UPDATED

## Step 3: Test the Implementation

### Test 1: Google Sign-Up (New User)
1. Open your app
2. Go to Sign Up/Register screen
3. Click "Sign in with Google"
4. Select your Google account
5. Choose role (Teacher or Student)
6. **Verify:**
   - Name is pre-filled from Google
   - Email is shown in a locked field with lock icon
   - Info banner shows "Name and email auto-filled from Google Sign In"
   - Name field is disabled (grayed out)
   - Other fields (phone, country, etc.) are editable
7. Complete registration
8. **Result:** Registration successful, user sees dashboard

### Test 2: Apple Sign-Up (New User - MUST use physical iOS device)
1. Open your app on a **physical iOS device** (not simulator)
2. Go to Sign Up/Register screen
3. Click "Sign in with Apple"
4. Complete Apple authentication
5. Choose role (Teacher or Student)
6. **Verify:**
   - Name is pre-filled from Apple
   - Email is shown (may be private relay email)
   - OAuth banner shows "Name and email auto-filled from Apple Sign In"
   - Fields are locked
7. Complete registration
8. **Result:** Registration successful

### Test 3: Apple Sign-In (Returning User)
1. Sign out from your app
2. Sign in again with Apple
3. **Verify:**
   - Login successful
   - User goes directly to dashboard (no re-registration)
4. Check Firestore `oauth_users` collection
5. **Verify:** User's OAuth data is stored with:
   - uid
   - email
   - fullName
   - provider: "apple"
   - appleUserId
   - timestamps

### Test 4: Manual Sign-Up (Should work as before)
1. Go to Sign Up/Register screen
2. Enter email and password manually
3. Choose role
4. **Verify:**
   - No OAuth banner
   - All fields are editable
   - No locked fields
5. Complete registration
6. **Result:** Works exactly as before

## Step 4: Verify Firestore Data

1. Open Firebase Console
2. Go to Firestore Database
3. Look for `oauth_users` collection
4. **Verify each OAuth user has:**
   ```
   {
     uid: "...",
     email: "...",
     fullName: "...",
     provider: "google" or "apple",
     appleUserId: "..." (Apple only),
     createdAt: Timestamp,
     lastUpdatedAt: Timestamp
   }
   ```

## Troubleshooting

### Problem: "Apple Sign In not available on this platform"
**Solution:** 
- Apple Sign In doesn't work on iOS Simulator
- Test on a physical iOS device
- Or test with Google Sign In instead

### Problem: Fields not auto-filling
**Check:**
1. User signed up with OAuth (not manual email/password)
2. Check browser console / device logs for errors
3. Verify Firestore security rules are deployed
4. Check if `oauth_users` collection exists in Firestore

### Problem: Email showing as empty
**Check:**
1. For Apple: First sign-in should provide email
2. For subsequent Apple sign-ins: Data loaded from Firestore
3. Check Firestore `oauth_users/{userId}` document

### Problem: App crash on registration screen
**Check:**
1. Run `flutter pub get` to ensure all dependencies
2. Check error logs
3. Verify all imports are correct

## Important Notes

### Apple Sign In Behavior
- **First Sign-In**: Apple provides name and email
- **Subsequent Sign-Ins**: Apple may return `null` for name/email
- **Solution**: We store data in Firestore on first sign-in and retrieve it later

### Private Relay Email (Apple)
- Apple users can hide their real email
- They get a private relay email like `abc123@privaterelay.appleid.com`
- This is normal and expected behavior
- The app handles it correctly

### Manual Users
- No changes to manual email/password signup
- Works exactly as before
- No OAuth data stored for manual users

## Testing Checklist

- [ ] Google Sign-Up works
- [ ] Google Sign-In works (returning user)
- [ ] Apple Sign-Up works (physical device)
- [ ] Apple Sign-In works (returning user)
- [ ] Manual Sign-Up still works
- [ ] Manual Sign-In still works
- [ ] Firestore `oauth_users` collection created
- [ ] OAuth data stored correctly
- [ ] Security rules deployed
- [ ] No console errors
- [ ] Name fields locked for OAuth users
- [ ] Email fields locked for OAuth users
- [ ] Info banners showing correctly
- [ ] Other fields remain editable

## Success Criteria

✅ OAuth users see pre-filled name and email  
✅ Fields are locked/disabled for OAuth data  
✅ Clear visual indicator (info banner) shown  
✅ Manual users unaffected  
✅ Data persists across sessions  
✅ Apple private relay emails handled  
✅ No crashes or errors  

## Support

If you encounter issues:
1. Check the comprehensive documentation in `OAUTH_AUTO_FILL_IMPLEMENTATION.md`
2. Review debug logs (search for "OAuth")
3. Verify Firebase configuration
4. Test on different platforms

---

**Ready to Test?** Start with Test 1 (Google Sign-Up) as it's the easiest to verify!
