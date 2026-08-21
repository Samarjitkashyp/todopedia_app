# TodoPedia — Mobile App

A modern, secure **Flutter** to-do app with a clean neumorphic UI, categories, dashboard
stats, dark/light themes, and secure JWT authentication (including an email-OTP password reset).

> 🖥️ **Backend API repository:** [todo_backend](https://github.com/Samarjitkashyp/todo_backend)
> This app talks to that FastAPI backend. Run both together — see [Connecting to the backend](#-connecting-to-the-backend).

---

## ✨ Features

- 🔐 **Secure auth** — register / login (username or email), JWT tokens stored in encrypted secure storage, auto token-refresh
- 🔑 **Forgot password** — email OTP flow with strong-password enforcement
- ✅ **Tasks** — create, edit, complete, star (important), delete, with optimistic UI updates
- 🗂️ **Categories** — colour-coded, with live pending-task counts
- 🔎 **Filters & search** — all / pending / completed / important / today / text search
- 📊 **Dashboard** — quick stats at a glance
- 🌗 **Dark & light themes** — soft neumorphic design with Google Fonts
- 📱 **Responsive** — adapts to keyboards and system navigation bars

---

## 🧰 Tech Stack

| Concern | Technology |
|---------|-----------|
| Framework | [Flutter](https://flutter.dev/) (Dart) |
| State management | [provider](https://pub.dev/packages/provider) (MVVM pattern) |
| Networking | [dio](https://pub.dev/packages/dio) (with interceptors) |
| Secure storage | [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) |
| Typography | [google_fonts](https://pub.dev/packages/google_fonts) |
| Formatting | [intl](https://pub.dev/packages/intl) |
| UI polish | [shimmer](https://pub.dev/packages/shimmer) |

---

## 📁 Project Structure

```
lib/
├── main.dart                     # App entry, providers, auth gate
├── core/
│   ├── constants/api_endpoints.dart   # Base URL & endpoint paths
│   ├── network/api_client.dart        # Dio client + auth/refresh interceptors
│   ├── storage/secure_storage.dart    # Encrypted token storage
│   └── theme/app_theme.dart           # Colours, gradients, neumorphic styles
├── data/models/                  # User, Todo, Category, Stats models
├── viewmodels/                   # AuthProvider, TodoProvider, ThemeProvider
└── views/
    ├── screens/                  # Login, Home
    └── widgets/                  # Add-task sheet, Forgot-password sheet
```

Architecture: **MVVM** — `views` (UI) ⇄ `viewmodels` (ChangeNotifier state) ⇄ `data`/`core` (models & networking).

---

## 🚀 Getting Started (A → Z)

### 1. Prerequisites
- **Flutter SDK 3.x** — <https://docs.flutter.dev/get-started/install> (run `flutter doctor`)
- An **Android emulator** / iOS simulator, or a physical device
- The **[TodoPedia backend](https://github.com/Samarjitkashyp/todo_backend)** running (see its README)

### 2. Clone the repository
```bash
git clone https://github.com/Samarjitkashyp/todopedia_app.git
cd todopedia_app
```

### 3. Install dependencies
```bash
flutter pub get
```

### 4. Connect to the backend
Open `lib/core/constants/api_endpoints.dart` and set `baseUrl` to your backend address:

| Scenario | URL |
|----------|-----|
| Android emulator → host machine | `http://10.0.2.2:8000/api/` |
| iOS simulator | `http://127.0.0.1:8000/api/` |
| Physical device (same Wi-Fi) | `http://<your-PC-LAN-IP>:8000/api/` (e.g. `http://192.168.0.237:8000/api/`) |

> Find your PC's LAN IP with `ipconfig` (Windows) or `ifconfig` / `ip addr` (macOS/Linux).

### 5. Run the app
```bash
flutter run
```
Pick your target device when prompted. Register a new account (or log in) and you're in.

### 6. Build a release (optional)
```bash
flutter build apk --release      # Android
flutter build ios --release      # iOS (on macOS)
```

---

## 🔗 Connecting to the Backend

This app is the client for the [todo_backend](https://github.com/Samarjitkashyp/todo_backend) API.

1. Start the backend first (`uvicorn main:app --host 0.0.0.0 --port 8000`).
2. Ensure your phone/emulator can reach the backend (same network; correct IP in `api_endpoints.dart`).
3. Run the app.

---

## 🛡️ Security Notes

- Tokens are kept in **encrypted secure storage** (Android EncryptedSharedPreferences / iOS Keychain) — never in plain prefs.
- **Cleartext HTTP is blocked** on Android except for whitelisted local-dev hosts (see `android/app/src/main/res/xml/network_security_config.xml`); use **HTTPS in production**.
- App data backup is disabled (`allowBackup="false"`).
- No secrets are stored in the app; all auth is handled by the backend.

---

## 📄 License

Released under the [MIT License](LICENSE).
