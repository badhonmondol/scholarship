# 🎓 ScholarSearch

A Flutter scholarship finder app that helps international students discover Bachelor, Master, and PhD programs across 60+ countries — all powered by Firebase Firestore with real-time sync.

---

## ✨ Features

- **500+ programs** across Bachelor, Master, and PhD levels
- **60+ countries** including USA, UK, Canada, Australia, Germany, Netherlands, Sweden, Denmark, Turkey, Hungary, Japan, South Korea, Singapore, Norway, and more
- **Real-time updates** — Firestore `snapshots()` stream keeps the list live without manual refresh
- **Smart filters** — filter by country, degree level, subject/field, and funding type simultaneously
- **Full-text search** — searches title, university, country, field, tags, and description
- **Save programs** — bookmark any program; saved state persists across app restarts via SharedPreferences
- **Apply direct** — opens the official application portal (BachelorsPortal / MastersPortal / PhDPortal) in the external browser
- **Auto-sync** — seeds and updates Firestore every 6 hours in the background; manual sync available from the app

---

## 📱 Screens

| Screen | Description |
|---|---|
| **Splash** | Animated loading screen shown on first launch |
| **Explore** | Main scholarship list with search bar, degree pills, and filter bar |
| **Saved** | Real-time list of bookmarked programs, persisted locally |
| **Profile** | Browse by country/subject, quick-degree cards, sync button |
| **Detail** | Full program info — funding, deadline, fields, description, tags, apply button |

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart 3) |
| Database | Cloud Firestore (Firebase) |
| Local storage | SharedPreferences |
| URL handling | url_launcher |
| Number formatting | intl |
| State management | `setState` + `StreamBuilder` |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- A Firebase project with Firestore enabled
- FlutterFire CLI (for re-configuring Firebase if needed)

### 1. Clone & install

```bash
git clone https://github.com/your-username/scholar_search.git
cd scholar_search
flutter pub get
```

### 2. Firebase setup

The app ships with pre-configured `lib/firebase_options.dart` for the `scholarship-app-1286b` project. To use your own Firebase project:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure for your project
flutterfire configure
```

Make sure your Firestore security rules allow reads and writes for unauthenticated users (or add Firebase Auth):

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /scholarships/{doc} {
      allow read: if true;
      allow write: if true; // tighten this for production
    }
  }
}
```

### 3. Run the app

```bash
# Android
flutter run

# iOS (requires macOS + Xcode)
flutter run -d ios

# Web
flutter run -d chrome
```

---

## 🔄 How Sync Works

1. On app launch, `SyncEngine.start()` fires immediately and then repeats every 6 hours.
2. Each run calls `_seed()`, which writes all programs from the local `_kData` list to Firestore using `set(merge: true)` — so both new documents and changes to existing ones (deadlines, amounts, descriptions) are applied.
3. The last sync timestamp is stored in SharedPreferences under `_ls` to throttle writes.
4. The "Sync Now" button on the Explore and Profile tabs resets the throttle and forces an immediate full sync.

---

## 📂 Project Structure

```
lib/
├── main.dart            # Entire application (models, screens, widgets, sync engine)
└── firebase_options.dart # Auto-generated Firebase platform config

android/
ios/
pubspec.yaml
```

---

## 🔖 Saved Programs

Bookmarks are stored as a `List<String>` of document IDs in SharedPreferences under the key `saved_ids`. They survive app restarts. The Saved tab uses a Firestore `snapshots()` stream (chunked into groups of 30 to respect Firestore's `whereIn` limit) so changes in Firestore appear live.

---

## 📦 Dependencies

```yaml
firebase_core: ^3.3.0        # Firebase initialization
cloud_firestore: ^5.2.1      # Realtime database
url_launcher: ^6.3.0         # Opens apply URLs
shared_preferences: ^2.3.2   # Persists saved IDs + sync timestamp
intl: ^0.19.0                # Currency/number formatting
```

---

## 🌍 Covered Countries (sample)

🇺🇸 USA · 🇬🇧 UK · 🇨🇦 Canada · 🇦🇺 Australia · 🇩🇪 Germany · 🇳🇱 Netherlands · 🇸🇪 Sweden · 🇩🇰 Denmark · 🇹🇷 Turkey · 🇭🇺 Hungary · 🇯🇵 Japan · 🇰🇷 South Korea · 🇸🇬 Singapore · 🇳🇴 Norway · 🇫🇮 Finland · 🇨🇳 China · 🇸🇦 Saudi Arabia · and 40+ more

---

## 📄 License

MIT — free to use and modify.
