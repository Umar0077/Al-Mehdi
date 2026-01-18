# OAuth Auto-Fill Implementation - Visual Flow Diagrams

## Flow 1: New Google User Sign-Up

```
┌─────────────────────────────────────────────────────────────────┐
│                     User Opens Sign Up Screen                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              User Clicks "Sign in with Google" Button            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│           registerWithGoogle() in AuthProvider Called            │
│  • Google Sign-In UI appears                                     │
│  • User selects Google account                                   │
│  • Google returns: email, displayName, uid                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│               Firebase Auth: signInWithCredential()              │
│  • User authenticated with Firebase                              │
│  • User object created                                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│             _saveOAuthUserData() Stores Data in Firestore        │
│  Collection: oauth_users/{uid}                                   │
│  • uid: user.uid                                                 │
│  • email: user.email                                             │
│  • fullName: user.displayName                                    │
│  • provider: "google"                                            │
│  • createdAt: now                                                │
│  • lastUpdatedAt: now                                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│           Returns: {email, fullName, uid, provider}              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│      User Selects Role: Student or Teacher                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│    Navigate to Student/Teacher Registration Screen              │
│  • Passes: email, fullName, no password (OAuth indicator)       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│        Registration Screen: initState() → _loadOAuthDataIfNeeded()│
│  1. Detects no password = OAuth user                             │
│  2. Sets _isOAuthUser = true                                     │
│  3. Calls getSignupMethod(uid) → returns "google"                │
│  4. Calls getOAuthUserData(uid) → retrieves Firestore data       │
│  5. Pre-fills _fullNameController with fullName                  │
│  6. Sets _oauthEmail = email                                     │
│  7. Sets _isLoadingOAuthData = false                             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   UI Renders with OAuth Data                      │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  ℹ️ Name and email auto-filled from Google Sign In         │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Full Name: [John Doe]  🔒 (Disabled)                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Email: john.doe@gmail.com  🔒                               │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Phone Number: [____________]  ✏️ (Editable)                 │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Country: [____________]  ✏️ (Editable)                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ... other fields ...                                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│        User Fills Remaining Fields and Clicks Register          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│    _submitStudentData() / _submitRegistration() Called          │
│  • Uses OAuth email from _oauthEmail                             │
│  • Uses fullName from _fullNameController                        │
│  • Creates StudentData / TeacherData                             │
│  • Calls registerStudentWithSocial() / registerTeacherWithSocial()│
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              Data Saved to Firestore Collections                 │
│  • students/{uid} or teachers/{uid}                              │
│  • unassigned_students/{uid} or unassigned_teachers/{uid}        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              User Navigates to Dashboard / Wait Screen           │
└─────────────────────────────────────────────────────────────────┘
```

## Flow 2: New Apple User Sign-Up (First Time)

```
┌─────────────────────────────────────────────────────────────────┐
│                     User Opens Sign Up Screen                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              User Clicks "Sign in with Apple" Button             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│           registerWithApple() in AuthProvider Called             │
│  • Apple Sign-In UI appears (Face ID / Touch ID)                 │
│  • User authenticates with Apple                                 │
│  • Apple returns (FIRST TIME ONLY):                              │
│    - email (real or private relay)                               │
│    - givenName                                                   │
│    - familyName                                                  │
│    - userIdentifier                                              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│               Firebase Auth: signInWithCredential()              │
│  • User authenticated with Firebase                              │
│  • User object created                                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│    ⚠️ CRITICAL: _saveOAuthUserData() Stores Data in Firestore   │
│  Collection: oauth_users/{uid}                                   │
│  • uid: user.uid                                                 │
│  • email: user.email (may be private relay)                      │
│  • fullName: givenName + " " + familyName                        │
│  • provider: "apple"                                             │
│  • appleUserId: credential.userIdentifier                        │
│  • createdAt: now                                                │
│  • lastUpdatedAt: now                                            │
│                                                                   │
│  ⭐ This is ESSENTIAL because Apple won't provide this again!    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│           Returns: {email, fullName, uid, provider}              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                     (Same as Google flow)
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│               Registration Screen Shows Apple Data               │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  ℹ️ Name and email auto-filled from Apple Sign In          │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Full Name: [Jane Smith]  🔒 (Disabled)                     │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Email: abc123@privaterelay.appleid.com  🔒                  │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Flow 3: Returning Apple User Sign-In (Subsequent Logins)

```
┌─────────────────────────────────────────────────────────────────┐
│                     User Opens Sign In Screen                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              User Clicks "Sign in with Apple" Button             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│             signInWithApple() in AuthProvider Called             │
│  • Apple Sign-In UI appears                                      │
│  • User authenticates with Apple                                 │
│  ⚠️ • Apple returns (SUBSEQUENT TIMES):                         │
│    - email: NULL or empty  ❌                                    │
│    - givenName: NULL  ❌                                         │
│    - familyName: NULL  ❌                                        │
│    - userIdentifier: Still provided ✅                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│               Firebase Auth: signInWithCredential()              │
│  • User authenticated with Firebase                              │
│  • User object exists                                            │
│  • user.displayName might be NULL                                │
│  • user.email might be empty                                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│             _checkUserStatusAndRole() Checks User                │
│  • User already registered (has role)                            │
│  • Not unassigned                                                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│        ⭐ Saves OAuth Data (If Available) - Graceful Fallback    │
│  if (givenName OR familyName OR email is NOT null) {             │
│    _saveOAuthUserData() updates Firestore                        │
│  }                                                               │
│  else {                                                          │
│    // Skip saving - no new data from Apple                       │
│    // Existing data in oauth_users remains intact                │
│  }                                                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│          User Navigates Directly to Dashboard                    │
│  • No re-registration required                                   │
│  • OAuth data from first sign-up still in Firestore             │
└─────────────────────────────────────────────────────────────────┘
```

## Flow 4: Manual Email/Password Sign-Up (Unchanged)

```
┌─────────────────────────────────────────────────────────────────┐
│                     User Opens Sign Up Screen                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│         User Enters: Email, Password, Full Name Manually         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   User Selects Role and Continues                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│    Navigate to Student/Teacher Registration Screen              │
│  • Passes: email, password, fullName                             │
│  • password != null → Manual user detected                       │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│        Registration Screen: initState() → _loadOAuthDataIfNeeded()│
│  1. Detects password exists = NOT OAuth user                     │
│  2. Sets _isOAuthUser = false                                    │
│  3. Pre-fills name from widget.fullName (if provided)            │
│  4. Sets _isLoadingOAuthData = false                             │
│  5. NO OAuth data fetched                                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│             UI Renders Normally (All Fields Editable)            │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Full Name: [John Doe]  ✏️ (Editable)                        │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Phone Number: [____________]  ✏️ (Editable)                 │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Country: [____________]  ✏️ (Editable)                      │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ... all other fields editable ...                               │
│  No OAuth banner                                                 │
│  No locked email field                                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│        User Fills All Fields and Clicks Register                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│    registerStudent() / registerTeacher() with Email+Password    │
│  • Creates Firebase Auth account                                 │
│  • Saves to Firestore                                            │
│  • NO oauth_users collection entry                               │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│              User Navigates to Dashboard / Wait Screen           │
└─────────────────────────────────────────────────────────────────┘
```

## Data Persistence Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│                    Firestore Collection Structure                │
└─────────────────────────────────────────────────────────────────┘

oauth_users (NEW COLLECTION)
  └── {uid}
      ├── uid: "abc123..."
      ├── email: "user@example.com" or "xyz@privaterelay.appleid.com"
      ├── fullName: "John Doe"
      ├── provider: "google" | "apple"
      ├── appleUserId: "001234.abc..." (Apple only)
      ├── createdAt: Timestamp(...)
      └── lastUpdatedAt: Timestamp(...)

students (EXISTING)
  └── {uid}
      ├── uid: "abc123..."
      ├── email: "user@example.com"
      ├── fullName: "John Doe"
      ├── phoneNumber: "+1234567890"
      ├── country: "United States"
      ├── grade: "10"
      ├── favouriteSubject: "Math"
      ├── assignedTeacherId: null
      └── createdAt: Timestamp(...)

teachers (EXISTING)
  └── {uid}
      ├── uid: "abc123..."
      ├── email: "teacher@example.com"
      ├── fullName: "Jane Smith"
      ├── phoneNumber: "+1234567890"
      ├── country: "Canada"
      ├── degree: "Master"
      ├── degreeProofUrl: "https://..."
      ├── assignedStudentId: null
      └── createdAt: Timestamp(...)
```

## Key Benefits Visualization

```
┌──────────────────────────────────────────────────────────────────┐
│                        Before Implementation                      │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Apple/Google User Journey:                                       │
│                                                                   │
│  1. Sign up with Apple → Provide name & email                    │
│  2. Navigate to registration → Asked AGAIN for name & email  ❌  │
│  3. User frustrated: "I just provided this!"  😞                 │
│  4. User types it again (error-prone, annoying)                   │
│  5. Log out and sign in again → Same problem persists            │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                         After Implementation                      │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  Apple/Google User Journey:                                       │
│                                                                   │
│  1. Sign up with Apple → Provide name & email                    │
│  2. Navigate to registration → Name & email AUTO-FILLED  ✅      │
│  3. User sees: "Name and email auto-filled from Apple"  😊      │
│  4. Fields locked, can't edit (clear visual indicator)            │
│  5. User only fills remaining fields (phone, country, etc.)       │
│  6. Log out and sign in → Data persists, no re-entry needed       │
│  7. Even if Apple returns null → Data loaded from Firestore       │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

---

**Legend:**
- 🔒 = Locked/Disabled field
- ✏️ = Editable field
- ℹ️ = Information banner
- ✅ = Successful operation
- ❌ = Problem/Error
- ⚠️ = Important warning
- ⭐ = Critical step
- 😊 = Happy user
- 😞 = Frustrated user
