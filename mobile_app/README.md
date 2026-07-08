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
cd ..
docker compose --env-file .env -f infra/docker/compose.local.yml up -d --build app-web
```

The app is published on `http://localhost:8383`.

## Production configuration

For backend mode on mobile/desktop, the app must receive `API_BASE_URL` through `--dart-define`. Flutter web can also receive it through Docker build args.

Rules enforced by the repository:

- Mobile/desktop backend mode requires a non-empty `API_BASE_URL`.
- Android emulator can use `http://10.0.2.2:3000/api/v1`.
- Physical devices on local WiFi must use `http://<PC_LAN_IP>:3000/api/v1`.
- `APP_ENV=production` requires a public HTTPS `API_BASE_URL`.
- `API_BASE_URL` for production cannot point to `localhost`, `127.0.0.1`, or `10.0.2.2`.
- Production deployment is expected to happen through containers, not by installing Flutter on the target host.

Example production-oriented container build:

```powershell
docker compose --env-file ..\.env.production.example -f ..\infra\docker\compose.prod.yml build app-web
```

## Android release 0.1

The Android baseline release version is `0.1.0+1`.

Local backend APK runbook:

- See `docs/qa-apk-local.md` for the controlled local QA matrix.
- Use `APP_MODE=backend` and a LAN API URL such as `http://192.168.1.7:3000/api/v1`.
- Do not use `APP_MODE=demo` for local backend APK validation.

Production APK build:

```powershell
cd mobile_app
flutter build apk --flavor prod --release --build-name 0.1.0 --build-number 1 --dart-define=APP_ENV=production --dart-define=APP_MODE=backend --dart-define=API_BASE_URL=https://api.sas-gym.qpsecure.cloud/api/v1
```

ADB install flow for a connected Redmi device:

```powershell
C:\Users\yoset\AppData\Local\Android\Sdk\platform-tools\adb.exe devices -l
C:\Users\yoset\AppData\Local\Android\Sdk\platform-tools\adb.exe install -r D:\proyectos\sas_gym\release\<fecha>_v0.1\sas-gym-v0.1.0-<fecha>.apk
```

## Layout summary

- `lib/app.dart`: role shell and topbar tabs.
- `lib/features/`: feature entrypoints grouped by auth and role.
- `lib/screens/`: current screen implementations used by the feature exports.
- `lib/data/`: app state, backend mapping and isolated demo seed data.
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
