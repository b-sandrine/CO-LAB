# CO-LAB
ALU Clan & Collaboration is a mobile-first platform designed specifically to support the peer-to-peer learning and entrepreneurial ecosystem at the African Leadership University.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) >= 3.0.0
- Dart >= 3.0.0
- A connected device or emulator (Android / iOS)

Verify your setup:
```bash
flutter doctor
```

## Getting Started

### 1. Install dependencies
```bash
cd frontend
flutter pub get
```

### 2. Run the app
```bash
flutter run
```

To target a specific device:
```bash
flutter run -d <device-id>   # e.g. flutter run -d emulator-5554
```

List available devices:
```bash
flutter devices
```

### 3. Build

**Android APK**
```bash
flutter build apk --release
```

**iOS**
```bash
flutter build ios --release
```

## Project Structure

```
CO-LAB/
└── frontend/          # Flutter app
    ├── lib/
    │   ├── core/      # Theme, database, routing
    │   ├── features/  # Auth, feed, teams, clans, profile
    │   ├── repositories/
    │   └── shared/    # Models, providers, widgets
    └── assets/
        ├── images/
        └── icons/
```
