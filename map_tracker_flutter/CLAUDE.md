# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get       # Install dependencies
flutter run           # Run the app
flutter test          # Run all tests
flutter test test/widget_test.dart  # Run a single test file
flutter analyze       # Lint/static analysis
dart format lib/      # Format code
flutter build apk     # Build Android APK (or ios, web, windows, linux, macos)
flutter clean         # Clean build artifacts
```

## Architecture

This is a Flutter application. The entry point is `lib/main.dart`. The project currently uses Material Design with a standard Flutter widget tree.

- `lib/` — application source code
- `test/` — widget and unit tests using `flutter_test`
- Platform directories (`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`) contain platform-specific native code — generally avoid editing these directly.

Dart SDK requirement: `^3.11.0`
