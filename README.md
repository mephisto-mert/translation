# 🚀 QuickTrace Pro — Windows Desktop Real-Time Translation Utility

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows_10%2F11_x64-0078D6.svg?logo=windows)](https://microsoft.com)
[![Flutter: Desktop](https://img.shields.io/badge/Flutter-3.x_Windows_Desktop-02569B.svg?logo=flutter)](https://flutter.dev)
[![C++: Win32 Native Hooks](https://img.shields.io/badge/C%2B%2B-Win32_RawInput_%26_Hooks-00599C.svg?logo=cplusplus)](https://microsoft.com)

**QuickTrace Pro** is an open-source real-time input, screen tooltip, and clipboard translation utility for Windows desktop applications, chat programs, and competitive games (such as CS2, Valorant, GTA V, and Rust).

---

## ⚡ Core Features

- **🔒 Secure Credential Storage**: API credentials (Gemini, DeepL) are stored using Windows Data Protection API (DPAPI) via `flutter_secure_storage`. Non-secret preferences remain in `SharedPreferences`. Secrets are masked in the UI (`••••••••1234`) and never logged.
- **🛡️ Target Window Focus Safety**: Captures target `HWND` and Process ID before translation begins (`ForegroundWindowService`). Before injecting backspaces and replacement text, it verifies whether the target window is still in the foreground. If the user switched windows (e.g. via `Alt+Tab`), replacement is cancelled.
- **🔄 Multi-Engine Fallback Architecture**: Modular translation engine pipeline (`GeminiTranslationEngine`, `DeepLTranslationEngine`, `GoogleTranslationEngine`, `MyMemoryTranslationEngine`) coordinated by `TranslationFallbackManager`. Handles HTTP 401/403 authentication failures, 429 rate-limit cooldowns, and 500/503 server errors with automatic fallback. Unconfigured engines are skipped.
- **⚡ Bounded LRU Cache**: Memory-bounded cache (500 max entries) with LRU eviction on access, SHA-256 collision-resistant keys (`source|target|engine|glossaryVersion|normalizedText`), 2-second debounced disk persistence (`quicktrace_lru_cache_v2`), and privacy clearing controls.
- **🎮 Gaming Glossary Protection**: Preserves competitive CS2 & gaming terminology (`A site`, `B site`, `catwalk`, `banana`, `awp`, `crosshair`, `headshot`) using collision-resistant token placeholders (`__QT_GLOSSARY_x__`) restored post-translation. Supports custom user terms.
- **🔤 Punctuation & Slang Transformer**: Protects URLs (`https://`), emails, decimal numbers (`3.14`), version numbers (`v2.1`), and Windows file paths (`C:\Users`). Transforms literal machine translation into natural gamer English.
- **⌨️ DirectInput ScanCode Injection**: Low-level Win32 keyboard hooks + `SendInput` using hardware scan codes (`KEYEVENTF_SCANCODE` & `MapVirtualKey`) for compatibility with full-screen games.
- **🖥️ Multi-Monitor & DPI Aware Tooltips**: Win32 tooltip overlay positioning using `MonitorFromPoint` & `GetMonitorInfoW`.

---

## 🌐 Supported Translation Providers

| Provider | Supported | Requires API Key | Endpoint / Model |
| :--- | :---: | :---: | :--- |
| **Google Translate** | Yes | No | Unofficial public GTX endpoint (`translate.googleapis.com/translate_a/single`) |
| **MyMemory** | Yes | No | Public API (`api.mymemory.translated.net/get`) |
| **Gemini AI** | Yes | Yes | Google Gemini 2.0 Flash REST API (`generativelanguage.googleapis.com`) |
| **DeepL** | Yes | Yes | DeepL API Free REST endpoint (`api-free.deepl.com/v2/translate`) |

---

## ⌨️ Hotkeys & Key Bindings

- **F9**: Global toggle (Enables / disables all hooks and modes) with Windows system beep feedback.
- **Alt + DownArrow**: Cycles target language.
- **Trigger Characters**: `.`, `!`, `?`, `,` (triggers automatic in-line text translation on space press).
- **In-Game Chat Keys**: `Y`, `U`, `Enter` (activates in-game chat text buffer).

---

## 🏗️ Project Architecture

```text
flutter_app/
├── lib/
│   ├── constants/              # Color palette, app constants, locale mappings (AppColors, AppLocales)
│   ├── controllers/            # Feature controllers (TranslationController, InputModeController, BubbleModeController, ClipboardModeController, HotkeyController, HistoryController, SettingsController)
│   ├── models/                 # Immutable domain models (AppSettings, InputEvent, ReplacementState, TranslationRequest, TranslationResult, etc.)
│   ├── services/
│   │   ├── cache/              # BoundedLruCache (500 max entries, SHA-256 keys, debounced persistence & corruption recovery)
│   │   ├── glossary/           # GamingGlossaryService with collision-resistant placeholders
│   │   ├── native/             # ForegroundWindowService (Win32 HWND FFI) & ClipboardService
│   │   ├── punctuation/        # PunctuationEngine (URL/path protection & slang transformation)
│   │   ├── security/           # SecureStorageService (Windows DPAPI)
│   │   └── translation/        # TranslationEngine interface, Gemini, DeepL, Google, MyMemory & FallbackManager
│   └── widgets/
│       ├── settings/           # ApiProviderSettingsCard, GamingGlossarySettingsCard, PrivacySettingsCard
│       └── home_screen.dart    # Main dashboard UI
└── windows/runner/native_hooks.cpp # C++ Win32 Hook Engine (RawInput, LowLevelKeyboardProc, SendInput)
```

---

## 💻 Requirements & Building from Source

### Prerequisites
- **Operating System**: Windows 10 or Windows 11 x64
- **Framework**: [Flutter SDK 3.x](https://flutter.dev)
- **C++ Compiler**: Visual Studio 2022 (with *Desktop development with C++* workload)

### Build Steps

```powershell
# 1. Clone the repository
git clone https://github.com/mephisto-mert/translation.git
cd translation/flutter_app

# 2. Install Dart/Flutter dependencies
flutter pub get

# 3. Run automated test suite
flutter test

# 4. Compile Windows Release Executable
flutter build windows --release
```

The output executable will be created at:
`flutter_app/build/windows/x64/runner/Release/quick_translate_pro.exe`

---

## 🔒 Security & Privacy

- **API Keys**: Stored in Windows DPAPI via `flutter_secure_storage`. Keys are never logged, printed, or saved in plaintext `SharedPreferences`.
- **Telemetry**: Zero analytics, zero external logging.
- **Privacy Controls**: Users can clear LRU cache and translation history at any time from the Privacy Settings panel.
- **Network Data**: When a translation request occurs, text content is sent directly to the selected provider (Google, MyMemory, Gemini, or DeepL).

---

## ⚠️ Known Limitations

- **Administrator Privileges**: To intercept low-level keyboard hooks in games running as Administrator (e.g., CS2, Valorant), QuickTrace Pro must also be launched as Administrator.
- **Public API Limits**: Free endpoints (Google GTX, MyMemory) may impose temporary IP rate limits under heavy continuous use.
- **Mixed-DPI Displays**: Tooltip positioning on multi-monitor setups with different DPI scaling (e.g. 100% + 150%) relies on Windows OS DPI awareness settings.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
