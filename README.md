# Todo App - Flutter Firebase

A full-featured Todo application built with Flutter and Firebase. Users can create, edit, complete, and delete tasks with email/password or Google Sign-In authentication.

---

## 📋 Project Overview

This is a cross-platform mobile Todo app that allows users to:

- **Authenticate** via Email/Password or Google Sign-In
- **Create** tasks with title and description
- **Edit** existing tasks
- **Complete/Incomplete** tasks with confirmation
- **Delete** tasks with confirmation
- **View** task statistics (Total, Completed, Pending)
- **Update** profile (name)
- **Persist** session with local storage

---

## 🛠 Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter (Dart 3.6+) |
| State Management | GetX |
| Backend | Firebase |
| Authentication | Firebase Auth (Email + Google) |
| Database | Firebase Realtime Database |
| Local Storage | SharedPreferences |
| UI | Material Design 3, Google Fonts (Poppins) |

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry, Firebase init, routing
├── firebase_options.dart      # Firebase config (auto-generated)
├── controllers/
│   ├── auth_controller.dart  # Auth logic, user management
│   └── task_controller.dart  # CRUD operations for tasks
├── models/
│   ├── user_model.dart       # User data model
│   └── task_model.dart       # Task data model
└── screens/
    ├── splash_screen.dart    # Initial loading, auth check
    ├── login_screen.dart    # Email/Google login
    ├── signup_screen.dart   # User registration
    ├── home_screen.dart     # Task list, stats, actions
    ├── task_screen.dart     # Add/Edit task form
    └── profile_screen.dart  # User profile, update name
```

---

## 🔥 Firebase Setup (End-to-End)

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project** (or use existing)
3. Enter project name (e.g., `todo-app`)
4. Enable/disable Google Analytics (optional)
5. Click **Create project**

### Step 2: Register Your App

1. In Firebase Console, click the **Android** icon to add an app
2. Enter your **Android package name** (e.g., `com.example.todo_app`)
   - Find it in `android/app/build.gradle` → `applicationId`
3. (Optional) Add app nickname and SHA-1 for Google Sign-In
4. Click **Register app**
5. Download `google-services.json` and place it in `android/app/`

### Step 3: Enable Firebase Services

#### Authentication
1. Go to **Build** → **Authentication** → **Get started**
2. Enable **Email/Password** sign-in method
3. Enable **Google** sign-in method
   - Add support email
   - Download `google-services.json` if not done

#### Realtime Database
1. Go to **Build** → **Realtime Database** → **Create Database**
2. Choose location (e.g., `us-central1`)
3. Start in **Test mode** for development (or set rules for production)
4. Copy the **Database URL** (e.g., `https://your-project-default-rtdb.firebaseio.com`)

### Step 4: Set Database Rules

In Realtime Database → **Rules** tab, use:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    },
    "tasks": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

### Step 5: FlutterFire CLI Setup

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Login to Firebase (if needed):
   ```bash
   firebase login
   ```

3. Configure FlutterFire in your project:
   ```bash
   cd herody_flutter_task
   flutterfire configure
   ```

4. This generates `lib/firebase_options.dart` with your Firebase config.

### Step 6: Android Configuration

- Ensure `google-services.json` is in `android/app/`
- `android/app/build.gradle` should have:
  ```gradle
  plugins {
      id "com.google.gms.google-services"
  }
  ```
- `android/build.gradle` should have Google services classpath
- Set `minSdk = 23` (required by Firebase Auth)

---

## 🗄 Firebase Realtime Database Structure

```
firebase-database/
├── users/
│   └── {userId}/
│       ├── uid: string
│       ├── email: string
│       ├── name: string
│       └── createdAt: string (ISO8601)
└── tasks/
    └── {taskId}/
        ├── title: string
        ├── description: string
        ├── isCompleted: boolean
        ├── createdAt: string
        ├── updatedAt: string
        └── userId: string
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.6+
- Dart 3.6+
- Android Studio / VS Code
- Firebase project (see setup above)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd herody_flutter_task
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add `google-services.json` to `android/app/`
   - Run `flutterfire configure` to generate `firebase_options.dart`

4. **Run the app**
   ```bash
   flutter run
   ```

### Build for Release

```bash
flutter build apk        # Android APK
flutter build appbundle  # Android App Bundle (Play Store)
flutter build ios       # iOS (requires Mac)
```

---

## 📱 App Flow

```
SplashScreen (2s)
    ├── Logged in? → HomeScreen
    └── Not logged in? → LoginScreen
                            ├── Sign up → SignupScreen → LoginScreen
                            ├── Login (Email/Google) → HomeScreen
                            └── Google Sign-In → HomeScreen

HomeScreen
    ├── Add task (+) → TaskScreen (add mode)
    ├── Edit task → TaskScreen (edit mode)
    ├── Checkbox → Confirm → Toggle complete
    ├── Delete → Confirm → Remove task
    ├── Profile icon → ProfileScreen
    └── Logout → LoginScreen
```

---

## 📦 Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| firebase_core | ^4.5.0 | Firebase initialization |
| firebase_auth | ^6.2.0 | Authentication |
| firebase_database | ^12.1.4 | Realtime Database |
| get | ^4.6.6 | State management, routing |
| google_sign_in | ^6.2.1 | Google Sign-In |
| google_fonts | ^6.1.0 | Poppins font |
| shared_preferences | ^2.2.2 | Local session storage |

---

## ⚙️ Key Configuration Files

| File | Purpose |
|------|---------|
| `lib/firebase_options.dart` | Firebase config (API key, project ID, etc.) |
| `android/app/google-services.json` | Android Firebase config |
| `android/app/build.gradle` | minSdk 23, applicationId |
| `pubspec.yaml` | Flutter dependencies |

---

## 🔒 Security Notes

- **Never commit** `google-services.json` or API keys to public repos
- Use **environment-specific** Firebase projects (dev/staging/prod)
- Set **strict Realtime Database rules** for production
- Enable **App Check** for production apps

---

## 📄 License

This project is for educational/demonstration purposes.

---

## 👤 Author

Herody Flutter Task - Todo App with Firebase
