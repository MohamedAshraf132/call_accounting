# Call Accounting

A Flutter app for calculating call minutes and tracking call costs by mobile network. Enter the number of people and the amount spent to see the estimated minutes instantly.

## Rates

- Vodafone: EGP 0.50 per minute
- Orange: EGP 0.50 per minute
- Other networks: EGP 2.50 per minute

The dashboard summarizes people, spending, and minutes across all networks. Entries are saved locally on the device.

## Run the app

```bash
flutter pub get
flutter run
```

## Build an Android APK

After installing Flutter and the Android SDK, run:

```bash
flutter build apk --release
```

The APK is typically created at `build/app/outputs/flutter-apk/app-release.apk`.
