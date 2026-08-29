# Changelog

All notable changes to the **QuickTrace** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v1.0.2] - 2026-08-29

### 🛠️ Windows MSVC Toolchain & CI Environment Fix
- **Fixed CMake Visual Studio Detection Failure**: Resolved `CMake Error: Generator Visual Studio 16 2019 could not find any instance of Visual Studio` in GitHub Actions by pinning runner to `windows-2022` and adding `ilammy/msvc-dev-cmd@v1` Developer Command Prompt setup before Windows compilation.

---

## [v1.0.1] - 2026-08-29

### 🔧 CI Build Stability & Dependency Hardening
- **Pinned Flutter SDK Version**: Fixed GitHub Actions release workflow by explicitly pinning Flutter SDK version to `3.19.6` (`channel: 'stable'`) to align local environment, CI pipeline, and release build environment.
- **Locked `google_fonts` Dependency**: Pinned `google_fonts: 6.2.1` in `pubspec.yaml` to prevent constant evaluation failures (`FontWeight` operator `==`) occurring on newer unpinned Dart SDKs.
- **Resolved Async Context Warnings**: Eliminated all `use_build_context_synchronously` analyzer issues in `api_provider_settings_card.dart` by storing controller instances before async gaps and adding proper `mounted` checks.
- **Maintained 100% Test Pass Rate**: Verified static analysis (`dart analyze`: 0 errors) and automated test suite (`flutter test`: 17/17 passed).

---

## [v1.0.0] - 2026-08-29

### 🚀 Initial Public Windows Release
- **Instant Desktop Input Translation**: Real-time keyboard input buffering and replacement across games and desktop applications.
- **Mouse Hover & Selection Bubble**: Floating translation tooltip near cursor upon text selection.
- **Clipboard Monitor**: Instant background translation notification for copied text.
- **Multi-Provider Fallback Engine**: Coordinated translation via Google Gemini 2.0 Flash, DeepL API, Google Translate (GTX), and MyMemory.
- **Gaming Glossary Protection**: Collision-resistant placeholders (`__QT_GLOSSARY_x__`) for CS2 and competitive gaming terms.
- **Punctuation & Slang Transformer**: Preserves URLs, emails, file paths, and transforms literal machine translation into natural gamer English.
- **Bounded LRU Cache**: 500-entry memory-bounded cache with SHA-256 keys, automatic corruption recovery, and debounced disk persistence.
- **Windows DPAPI Security**: API credentials stored using Windows Data Protection API via `flutter_secure_storage`.
- **Target Window Focus Verification**: `ForegroundWindowService` HWND/PID validation prevents accidental text injection when switching windows.
- **DirectInput Hardware ScanCodes**: C++ Win32 hook engine (`SendInput` with `KEYEVENTF_SCANCODE`) compatible with full-screen games.
