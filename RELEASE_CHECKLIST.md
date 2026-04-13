# Hazaribagh Pulse Release Checklist

## Build Configuration

- Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` with `--dart-define` for every production build.
- Copy `android/key.properties.example` to `android/key.properties` and fill in the real keystore values.
- Place the Android upload keystore at the path referenced by `storeFile`.
- Confirm iOS signing team, bundle identifier, and provisioning profile are correct in Xcode.

## App Metadata

- Confirm the final Android application ID: `com.hazaribaghpulse.hazaribagh_pulse`.
- Confirm the final iOS bundle identifier: `com.hazaribaghpulse.hazaribaghPulse`.
- Verify the store listing name is `Hazaribagh Pulse`.
- Verify version/build numbers in `pubspec.yaml` before each release.

## Assets

- Verify launcher icons on Android and iOS render cleanly on device.
- Verify the Android splash uses the dark background and centered icon.
- Verify the iOS launch screen uses the dark background and centered launch image.

## Permissions

- Verify internet access works in Android release builds.
- Verify photo library permission prompt appears only when selecting an image on iOS.
- Re-check any future camera usage before adding `NSCameraUsageDescription`.

## Backend Safety

- Confirm no `service_role` key is bundled in the Flutter app.
- Confirm Supabase anon key and URL come only from build-time defines.
- Confirm delete-account edge function is deployed in production.
- Confirm production Supabase RLS policies are enabled and tested.

## Release QA

- Smoke test signup, login, logout, delete account, edit profile, create listing, like/save, search, and reopen app in release mode.
- Smoke test image upload flows on both Android and iOS.
- Verify no debug banners, debug logs, or placeholder copy remain in key paths.
- Verify crash reporting and analytics strategy, if any, before launch.

## Distribution

- Build Android App Bundle for Play Store submission.
- Build iOS archive in Xcode for App Store Connect submission.
- Keep a copy of the exact `--dart-define` values used for the release build in your secure deployment notes.
