# mobile_app

Role-based Flutter prototype for SaaaS GYM.

## Run on Windows

```powershell
cd mobile_app
flutter pub get
flutter run -d windows
```

## Run as web preview

```powershell
cd mobile_app
flutter pub get
flutter run -d chrome
```

## Build and deploy with Docker

```powershell
cd mobile_app
docker compose up --build -d
```

The app is published on `http://localhost:8282`.

## Layout summary

- `lib/app.dart`: role shell and topbar tabs.
- `lib/features/`: feature entrypoints grouped by auth and role.
- `lib/screens/`: current screen implementations used by the feature exports.
- `lib/data/`: mock data for workouts, products, logs and cashiers.
- `lib/widgets/`: reusable UI helpers.
- `lib/core/`: API and local storage services.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

