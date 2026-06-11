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

## Production configuration

For production, the Flutter web build must receive `API_BASE_URL` through `--dart-define` or Docker build args.

Rules enforced by the repository:

- `APP_ENV=production` requires a non-empty `API_BASE_URL`.
- `API_BASE_URL` for production cannot point to `localhost`, `127.0.0.1`, or `10.0.2.2`.
- Production deployment is expected to happen through containers, not by installing Flutter on the target host.

Example production-oriented container build:

```powershell
docker compose --env-file ..\.env.production.example -f ..\infra\docker\compose.prod.yml build app_web
```

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

