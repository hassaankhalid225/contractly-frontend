# Contractly — Frontend

Flutter mobile app for Contractly (Android, iOS, Web, Windows).

**Backend repo:** [contractly-backend](https://github.com/hassaankhalid225/contractly-backend)

## Quick Start

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

- **Android emulator:** `10.0.2.2` points to your machine's localhost.
- **Physical device / iOS:** use your PC's LAN IP, e.g. `http://192.168.1.10:8000/api/v1`.

Start the API first (see the backend repo).

## Test login (phone OTP)

- `+923001234567` or `+923009876543`
- OTP: `123456`

## Project structure

```
lib/
├── core/       # API, models, providers, router, services
├── ui/         # components + screens
└── util/       # helpers, extensions, mixins
```
