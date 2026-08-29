# 🚀 QuickTrace Pro — Production-Grade Windows Real-Time Translation Utility

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https.mit-license.org)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows_10%2F11_x64-0078D6.svg?logo=windows)](https://microsoft.com)
[![Flutter: Desktop](https://img.shields.io/badge/Flutter-3.x_Windows_Desktop-02569B.svg?logo=flutter)](https://flutter.dev)
[![C++: Win32 Native Hooks](https://img.shields.io/badge/C%2B%2B-Win32_RawInput_%26_Hooks-00599C.svg?logo=cplusplus)](https://microsoft.com)

**QuickTrace Pro** is a high-performance, production-grade Windows desktop application for real-time input, screen, and clipboard translation designed especially for competitive gaming (CS2, Valorant, GTA V, Rust), chat apps, browsers, and desktop software.

---

## ⚡ Master Architecture & Engineering Highlights

- **🔒 Zero Hardcoded Secrets & Security Hardening**: All API credentials (Gemini, DeepL) are protected using Windows DPAPI via `flutter_secure_storage`. Secrets are never logged or stored in plain text.
- **🛡️ Target Foreground Window Safety**: Captures target `HWND`/PID before translation and re-verifies active focus before executing keystrokes (`SendInput`). If focus switches, replacement is cancelled automatically.
- **🔄 Fault-Tolerant Translation Resiliency**: Pluggable engine hierarchy (Gemini 2.0 Flash, DeepL, Google Translate, MyMemory) with per-engine circuit breakers, exponential backoff, rate-limiting, and automatic fallback.
- **⚡ Bounded LRU Cache**: Sub-millisecond SHA-256 collision-resistant LRU cache with debounced 2s async disk persistence.
- **🎮 Gaming Glossary Tokenizer**: Protects CS2 & gaming terminology (`A site`, `B site`, `catwalk`, `awp`, `crosshair`) using collision-resistant token placeholders (`__QT_GLOSSARY_x__`).
- **🔤 Deterministic Punctuation & Natural Gamer Slang Engine**: Protects URLs, emails, decimals, versions, file paths, and converts literal machine translations (`ok i am coming brother`) into natural gamer English (`Got it, on my way bro!`).
- **🖥️ Hardware ScanCode In-Game Keyboard Simulation**: Direct Win32 Low-Level Hooks + `SendInput` with hardware scan codes (`KEYEVENTF_SCANCODE`) & extended key flags for 100% full-screen game compatibility.
- **📱 Multi-Monitor & DPI Aware Native Tooltips**: Win32 tooltip bubble positioning powered by `MonitorFromPoint` & `GetMonitorInfoW`.

---

## 🏗️ Technical Architecture

```
QuickTrace Pro Core Architecture
├── lib/
│   ├── models/ (Immutable domain models: AppSettings, ReplacementState, TranslationResult, InputEvent)
│   ├── services/
│   │   ├── security/ (SecureStorageService backed by Windows DPAPI)
│   │   ├── translation/ (Gemini, DeepL, Google, MyMemory & FallbackManager)
│   │   ├── cache/ (BoundedLruCache with SHA-256 keys)
│   │   ├── glossary/ (GamingGlossaryService with token placeholders)
│   │   ├── punctuation/ (PunctuationEngine with URL/path protection)
│   │   └── native/ (ForegroundWindowService & ClipboardService)
│   ├── controllers/ (Translation, InputMode, BubbleMode, ClipboardMode, Hotkey, History, Settings)
│   └── widgets/ (ApiProviderSettingsCard, GamingGlossarySettingsCard, PrivacySettingsCard)
└── windows/runner/native_hooks.cpp (C++ Win32 Hook Engine, RawInput, SendInput ScanCodes)
```

---

## 💻 Building from Source

### Prerequisites
- Windows 10/11 x64
- [Flutter SDK 3.x](https://flutter.dev)
- Visual Studio 2022 (with Desktop Development with C++)

### Build & Run
```powershell
# 1. Clone repository
git clone https://github.com/mephisto-mert/translation.git
cd translation/flutter_app

# 2. Install dependencies
flutter pub get

# 3. Run tests
flutter test

# 4. Build Release Executable
flutter build windows --release
```

Release binary will be located at:
`flutter_app/build/windows/x64/runner/Release/quick_translate_pro.exe`

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
