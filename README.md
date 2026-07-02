# 💊 MediCare  Smart Medicine Reminder & Stock Tracker

A modern, fully-offline Flutter app that lets you and your family track medicines, manage stock, and schedule reminders  backed by a local SQLite database and secured by per-account login.

## ✨ What's new in this version

This is a full rebuild of the original project. Highlights:

- 🔐 **Login & Registration**  email + password with strength meter, validation, "remember me", and SHA-256 + per-user salt hashing (no plain-text passwords).
- 🗄️ **Reliable persistence**  schema-versioned SQLite database with foreign-key cascades and indexes. All data is scoped to the signed-in user.
- 🎨 **Modern, professional UI**  Material 3, Inter via `google_fonts`, gradient hero headers, consistent spacing, animated transitions, accessible color contrast.
- ⚙️ **Project ready for VS Code**  proper `pubspec.yaml`, `analysis_options.yaml`, `.vscode/launch.json`, Android Gradle Kotlin DSL config, iOS `Info.plist`, Podfile, launcher icons, and `.gitignore`.
- 🐛 **All compile/runtime bugs fixed**  `notification_service.dart` import order, missing `profile.dart` import in `home_screen.dart`, deprecated `CardTheme`/`background:` color scheme keys, and the broken `assets/images/` reference in `pubspec.yaml`.



## 📱 Features

| Feature | Description |

| 🔐 Authentication | Email/password login & registration with input validation |
| 👤 User-scoped data | Two accounts on one device never see each other's data |
| 💊 Medicine management | Add, edit, delete medicines with type, dosage, color, notes |
| 📦 Stock tracker | Current vs. total stock with progress bar and refill flow |
| ⚠️ Low stock alerts | In-app banner + local notification when stock runs low |
| ⏰ Smart reminders | Daily or specific-day reminders with exact local notifications |
| 👨‍👩‍👧 Family profiles | Track medicines separately for each family member |
| 📊 History & adherence | Full intake log with taken/skipped/missed and adherence % |
| 🎨 Polished dark UI | Animated, accessible, Material 3 design |

---

## 🚀 Quick start

### 1. Install Flutter
- Flutter 3.19 or later. Install from <https://flutter.dev/docs/get-started/install>.
- Run `flutter doctor` and make sure all checkmarks are green for the platforms you plan to target.

### 2. Open in VS Code
```bash
code medicare
```
The folder ships with `.vscode/launch.json`, `.vscode/settings.json`, and the Flutter VS Code extension will be auto-detected.

### 3. Fetch dependencies
```bash
flutter pub get
```

### 4. Run it
```bash
flutter devices       # confirm an emulator or device is connected
flutter run           # debug
# or hit F5 in VS Code
```

---

## 📁 Project structure

```
medicare/
├── lib/
│   ├── main.dart                          # App entry point & routes
│   ├── theme.dart                         # Material 3 design system
│   ├── models/
│   │   ├── user.dart                      # Authenticated user
│   │   ├── profile.dart                   # Family profile + MedicineLog
│   │   ├── medicine.dart                  # Medicine
│   │   └── reminder.dart                  # Reminder
│   ├── database/
│   │   └── database_helper.dart           # SQLite (schema v2, FK cascades)
│   ├── services/
│   │   ├── auth_service.dart              # Salted SHA-256, "remember me"
│   │   ├── app_provider.dart              # ChangeNotifier  single source of state
│   │   └── notification_service.dart      # Local notifications & scheduling
│   ├── utils/
│   │   └── validators.dart                # Form validators + password strength
│   ├── screens/
│   │   ├── splash_screen.dart             # Splash + session restore
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   ├── home_screen.dart               # Dashboard, Medicines, Reminders, History, Family
│   │   ├── add_medicine_screen.dart       # Add / edit medicine form
│   │   └── medicine_detail_screen.dart    # Overview / Reminders / History tabs
│   └── widgets/
│       ├── medicine_card.dart
│       └── stat_card.dart
├── android/                               # Gradle KTS + AndroidManifest + icons
├── ios/                                   # Info.plist, AppDelegate, Podfile
├── test/widget_test.dart                  # Validator + theme tests
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```

---

## 🛠 Tech stack

| Area | Library / approach |
|---|---|
| Framework | Flutter 3.19+ (Dart 3.3+) |
| State management | `provider` (`ChangeNotifier`) |
| Local database | `sqflite` with versioned schema |
| Auth | `crypto` for SHA-256 + per-user salt, `shared_preferences` for the session |
| Notifications | `flutter_local_notifications` + `timezone` |
| Charts | `fl_chart` |
| Animations | `animate_do` |
| Fonts | `google_fonts` (Inter) |

---

## 🔐 Authentication notes

Passwords are never stored in plain text. On registration:

1. A 16-byte cryptographically random salt is generated per user.
2. The password is concatenated with the salt and hashed with SHA-256.
3. Both the hash and salt are stored in the `users` table.
4. On login, the same hash is recomputed and compared.

"Remember me" stores only the user's row ID in `shared_preferences`, never the password.

> This is a fully offline app. Password recovery is intentionally disabled  for a production app you would forward this through a backend and a verified email flow.

---

## 🗄 Database schema (v2)

```
users        (id, name, email[unique], passwordHash, salt, avatar, createdAt)
profiles     (id, name, relation, age, avatar, userId → users.id, createdAt)
medicines    (id, name, dosage, type, totalStock, currentStock, lowStockAlert,
              color, profileId → profiles.id, notes, createdAt)
reminders    (id, medicineId → medicines.id, medicineName, time, days,
              isActive, dose, createdAt)
medicine_logs (id, medicineId, medicineName, profileId, profileName, status,
               takenAt, dose)
```

All foreign keys use `ON DELETE CASCADE`. Deleting a user removes their profiles, which removes their medicines, which removes their reminders.

---

## 🐛 Bug fixes from the original

| File | Issue | Fix |
|---|---|---|
| `lib/services/notification_service.dart` | `import` statement placed *after* class definition (Dart syntax error) | Moved all imports to the top of the file |
| `lib/screens/home_screen.dart` | Used `Profile(...)` but never imported `models/profile.dart` | Added the import |
| `lib/theme.dart` | Used deprecated `CardTheme` and `background:` `ColorScheme` key | Switched to `CardThemeData` + Material 3 `surface` key |
| `pubspec.yaml` | Declared `assets/images/` folder that didn't exist (runtime failure) | Removed the broken declaration |
| `lib/database/database_helper.dart` | No FK enforcement, no migrations, no per-user scoping | Added `PRAGMA foreign_keys = ON`, `_onUpgrade` migration, indexes, user FK |
| `lib/services/app_provider.dart` | Data was global; all users saw the same medicines | Scoped every query through `currentUser.id` |
| Project root | No Gradle config, missing `MainActivity.kt`, empty `ios/Runner/` | Added full Android (KTS) + iOS scaffolding so it opens & runs in VS Code |

---

## ✅ Running the tests

```bash
flutter test


1. **Splash**  animated logo, restores session if you were signed in.
2. **Login / Register**  validated, animated, password strength meter.
3. **Dashboard**  adherence %, stat cards, low-stock banner, today's medicines.
4. **Medicines**  search + filter chips, take/refill actions.
5. **Medicine Detail**  Overview (pie chart), Reminders, History tabs.
6. **Reminders**  toggle on/off per reminder, delete.
7. **History**  full intake log grouped chronologically.
8. **Family Profiles**  add/select/delete family members.

---

Made with ❤️  MediCare
