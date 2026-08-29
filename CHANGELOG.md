# Changelog

All notable changes to the **QuickTrace** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [v1.0.0] - 2026-08-29

### 🚀 Initial Public Windows Release

#### Features
- **Instant Desktop Input Translation**: Real-time keyboard input buffering and replacement across games and desktop applications.
- **Mouse Hover & Selection Bubble**: Floating translation tooltip near cursor upon text selection.
- **Clipboard Monitor**: Instant background translation notification for copied text.
- **Multi-Provider Fallback Engine**: Coordinated translation via Google Gemini 2.0 Flash, DeepL API, Google Translate (GTX), and MyMemory.
- **Gaming Glossary Protection**: Collision-resistant placeholders (`__QT_GLOSSARY_x__`) for CS2 and competitive gaming terms.
- **Punctuation & Slang Transformer**: Preserves URLs, emails, file paths, and transforms literal machine translation into natural gamer English.
- **Bounded LRU Önbellek**: 500-entry memory-bounded cache with SHA-256 keys, automatic corruption recovery, and debounced disk persistence.
- **Windows DPAPI Security**: API credentials stored using Windows Data Protection API via `flutter_secure_storage`.
- **Target Window Focus Verification**: `ForegroundWindowService` HWND/PID validation prevents accidental text injection when switching windows.
- **DirectInput Hardware ScanCodes**: C++ Win32 hook engine (`SendInput` with `KEYEVENTF_SCANCODE`) compatible with full-screen games.
