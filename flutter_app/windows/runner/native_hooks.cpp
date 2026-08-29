#include "native_hooks.h"
#include <flutter/encodable_value.h>
#include <cmath>
#include <vector>

// Static instance for hook callbacks
NativeHooksPlugin* NativeHooksPlugin::instance_ = nullptr;

// Raw Input hidden window class name
static constexpr wchar_t kRawInputClassName[] = L"QuickTraceRawInput";

// Hook thread'den baloncuğu kapatmak için özel mesaj (tüm dosyada kullanılıyor)
static constexpr UINT WM_BUBBLE_DISMISS = WM_USER + 100;

NativeHooksPlugin::NativeHooksPlugin(
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel)
    : channel_(std::move(channel)) {
  instance_ = this;
}

NativeHooksPlugin::~NativeHooksPlugin() {
  StopHooks();
  HideBubble();
  if (bubble_font_) {
    DeleteObject(bubble_font_);
    bubble_font_ = nullptr;
  }
  if (instance_ == this) {
    instance_ = nullptr;
  }
}

void NativeHooksPlugin::SetupMethodHandler() {
  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        this->HandleMethodCall(call, std::move(result));
      });
}

void NativeHooksPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = method_call.method_name();

  if (method == kMethodStartHooks) {
    StartHooks();
    result->Success(flutter::EncodableValue(hooks_active_.load()));
  } else if (method == kMethodStopHooks) {
    StopHooks();
    result->Success(flutter::EncodableValue(true));
  } else if (method == kMethodGetClipboardText) {
    std::string text = GetClipboardText();
    result->Success(flutter::EncodableValue(text));
  } else if (method == kMethodSetClipboardText) {
    const auto* args = std::get_if<std::string>(method_call.arguments());
    if (args) {
      SetClipboardText(*args);
      result->Success(flutter::EncodableValue(true));
    } else {
      result->Error("INVALID_ARG", "Expected string argument");
    }
  } else if (method == kMethodSimulateBackspace) {
    const auto* args = std::get_if<int32_t>(method_call.arguments());
    int count = args ? *args : 1;
    SimulateBackspace(count);
    result->Success(flutter::EncodableValue(true));
  } else if (method == kMethodSimulatePaste) {
    SimulatePaste();
    result->Success(flutter::EncodableValue(true));
  } else if (method == kMethodSimulateKeyPress) {
    const auto* args = std::get_if<int32_t>(method_call.arguments());
    if (args) {
      SimulateKeyPress(*args);
      result->Success(flutter::EncodableValue(true));
    } else {
      result->Error("INVALID_ARG", "Expected int argument");
    }
  } else if (method == kMethodSimulateCopy) {
    SimulateCopy();
    result->Success(flutter::EncodableValue(true));
  } else if (method == kMethodGetMousePosition) {
    POINT pos = GetMousePosition();
    flutter::EncodableMap map;
    map[flutter::EncodableValue("x")] = flutter::EncodableValue(static_cast<int32_t>(pos.x));
    map[flutter::EncodableValue("y")] = flutter::EncodableValue(static_cast<int32_t>(pos.y));
    result->Success(flutter::EncodableValue(map));
  } else if (method == kMethodPollEvents) {
    auto events = PollEvents();
    result->Success(flutter::EncodableValue(events));
  } else if (method == kMethodShowBubble) {
    const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (args) {
      auto textIt = args->find(flutter::EncodableValue("text"));
      auto xIt = args->find(flutter::EncodableValue("x"));
      auto yIt = args->find(flutter::EncodableValue("y"));
      if (textIt != args->end() && xIt != args->end() && yIt != args->end()) {
        std::string text = std::get<std::string>(textIt->second);
        int x = std::get<int32_t>(xIt->second);
        int y = std::get<int32_t>(yIt->second);
        ShowBubble(text, x, y);
        result->Success(flutter::EncodableValue(true));
      } else {
        result->Error("INVALID_ARG", "Expected map with text, x, y");
      }
    } else {
      result->Error("INVALID_ARG", "Expected map argument");
    }
  } else if (method == kMethodHideBubble) {
    HideBubble();
    result->Success(flutter::EncodableValue(true));
  } else {
    result->NotImplemented();
  }
}

// ═══════════════════════════════════════════════════════
// THREAD-SAFE EVENT QUEUE + POLLING
// ═══════════════════════════════════════════════════════

void NativeHooksPlugin::EnqueueEvent(HookEvent event) {
  std::lock_guard<std::mutex> lock(queue_mutex_);
  event_queue_.push(std::move(event));
}

flutter::EncodableList NativeHooksPlugin::PollEvents() {
  flutter::EncodableList events;

  std::queue<HookEvent> local_queue;
  {
    std::lock_guard<std::mutex> lock(queue_mutex_);
    std::swap(local_queue, event_queue_);
  }

  while (!local_queue.empty()) {
    auto& ev = local_queue.front();

    flutter::EncodableMap map;
    if (ev.type == HookEventType::KeyPress) {
      map[flutter::EncodableValue("type")] =
          flutter::EncodableValue(std::string("key"));
      map[flutter::EncodableValue("vkCode")] =
          flutter::EncodableValue(ev.vkCode);
      map[flutter::EncodableValue("char")] =
          flutter::EncodableValue(ev.character);
    } else if (ev.type == HookEventType::MouseDragEnd) {
      map[flutter::EncodableValue("type")] =
          flutter::EncodableValue(std::string("mouse"));
      map[flutter::EncodableValue("x")] =
          flutter::EncodableValue(ev.x);
      map[flutter::EncodableValue("y")] =
          flutter::EncodableValue(ev.y);
      map[flutter::EncodableValue("distance")] =
          flutter::EncodableValue(ev.distance);
    }

    events.push_back(flutter::EncodableValue(map));
    local_queue.pop();
  }

  return events;
}

// ═══════════════════════════════════════════════════════
// RAW INPUT — Works with CS2 and other games
// Uses RIDEV_INPUTSINK to receive input even in background
// ═══════════════════════════════════════════════════════

LRESULT CALLBACK NativeHooksPlugin::RawInputWndProc(
    HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
  if (msg == WM_INPUT && instance_ && !instance_->is_typing_replacement_) {
    UINT dwSize = 0;
    GetRawInputData(reinterpret_cast<HRAWINPUT>(lParam),
                    RID_INPUT, nullptr, &dwSize, sizeof(RAWINPUTHEADER));

    if (dwSize > 0) {
      std::vector<BYTE> rawBuffer(dwSize);
      if (GetRawInputData(reinterpret_cast<HRAWINPUT>(lParam),
                          RID_INPUT, rawBuffer.data(), &dwSize,
                          sizeof(RAWINPUTHEADER)) == dwSize) {
        RAWINPUT* raw = reinterpret_cast<RAWINPUT*>(rawBuffer.data());
        if (raw->header.dwType == RIM_TYPEKEYBOARD) {
          instance_->ProcessRawKeyboard(raw->data.keyboard);
        }
      }
    }
    return 0;
  }
  return DefWindowProc(hwnd, msg, wParam, lParam);
}

void NativeHooksPlugin::ProcessRawKeyboard(RAWKEYBOARD& rawKb) {
  // Only process key down events (WM_KEYDOWN or WM_SYSKEYDOWN)
  bool isDown = !(rawKb.Flags & RI_KEY_BREAK);
  USHORT vk = rawKb.VKey;
  USHORT scanCode = rawKb.MakeCode;

  if (isDown) {
    // Prevent duplicate events — only fire on first press
    if (raw_keys_down_.count(vk)) return;
    raw_keys_down_.insert(vk);

    // Karakter dönüşümü için klavye durumunu hazırla
    BYTE keyboardState[256] = {0};
    if (GetKeyState(VK_SHIFT) & 0x8000) keyboardState[VK_SHIFT] = 0x80;
    if (GetKeyState(VK_CAPITAL) & 0x0001) keyboardState[VK_CAPITAL] = 0x01;
    if (GetKeyState(VK_CONTROL) & 0x8000) keyboardState[VK_CONTROL] = 0x80;
    if (GetKeyState(VK_MENU) & 0x8000) keyboardState[VK_MENU] = 0x80;

    WCHAR unicodeChar[5] = {0};
    // ToUnicodeEx kullanarak mevcut klavye düzenine göre karakteri al
    int result = ToUnicode(vk, scanCode, keyboardState, unicodeChar, 4, 0);

    HookEvent ev;
    ev.type = HookEventType::KeyPress;
    ev.vkCode = static_cast<int32_t>(vk);

    if (result > 0) {
      int utf8_len = WideCharToMultiByte(
          CP_UTF8, 0, unicodeChar, result, nullptr, 0, nullptr, nullptr);
      std::string utf8_str(utf8_len, 0);
      WideCharToMultiByte(
          CP_UTF8, 0, unicodeChar, result,
          &utf8_str[0], utf8_len, nullptr, nullptr);
      ev.character = utf8_str;
    } else {
      // Karakter gelmese bile VK koduyla boşluk ve Enter gibi tuşları işle
      if (vk == VK_SPACE) ev.character = " ";
    }

    EnqueueEvent(std::move(ev));
  } else {
    // Key up — remove from tracking set
    raw_keys_down_.erase(vk);
  }
}

// ═══════════════════════════════════════════════════════
// HOOK THREAD — LL Hooks + Raw Input in one thread
// ═══════════════════════════════════════════════════════

void NativeHooksPlugin::HookThreadProc() {
  // 1. Install standard LL hooks (works for normal apps)
  keyboard_hook_ = SetWindowsHookEx(
      WH_KEYBOARD_LL, LowLevelKeyboardProc, nullptr, 0);
  mouse_hook_ = SetWindowsHookEx(
      WH_MOUSE_LL, LowLevelMouseProc, nullptr, 0);

  // 2. Create hidden window for Raw Input (works for games like CS2)
  if (!raw_input_class_registered_) {
    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(WNDCLASSEXW);
    wc.lpfnWndProc = RawInputWndProc;
    wc.hInstance = GetModuleHandle(nullptr);
    wc.lpszClassName = kRawInputClassName;
    if (RegisterClassExW(&wc)) {
      raw_input_class_registered_ = true;
    }
  }

  raw_input_hwnd_ = CreateWindowExW(
      0, kRawInputClassName, L"", 0,
      0, 0, 0, 0, HWND_MESSAGE, nullptr,
      GetModuleHandle(nullptr), nullptr);

  if (raw_input_hwnd_) {
    // Register for keyboard raw input with INPUTSINK
    // This allows receiving WM_INPUT even when our app is NOT focused
    RAWINPUTDEVICE rid = {};
    rid.usUsagePage = 0x01;  // HID_USAGE_PAGE_GENERIC
    rid.usUsage = 0x06;      // HID_USAGE_GENERIC_KEYBOARD
    rid.dwFlags = RIDEV_INPUTSINK;
    rid.hwndTarget = raw_input_hwnd_;
    RegisterRawInputDevices(&rid, 1, sizeof(rid));
  }

  hooks_active_.store(
      (keyboard_hook_ != nullptr || raw_input_hwnd_ != nullptr) &&
      mouse_hook_ != nullptr);

  // Message pump — serves both LL hooks AND Raw Input
  MSG msg;
  while (hook_thread_running_.load()) {
    DWORD result = MsgWaitForMultipleObjects(0, nullptr, FALSE, 50, QS_ALLINPUT);
    if (result == WAIT_OBJECT_0) {
      while (PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE)) {
        if (msg.message == WM_QUIT) {
          hook_thread_running_.store(false);
          break;
        }
        TranslateMessage(&msg);
        DispatchMessage(&msg);
      }
    }
  }

  // Cleanup hooks
  if (keyboard_hook_) {
    UnhookWindowsHookEx(keyboard_hook_);
    keyboard_hook_ = nullptr;
  }
  if (mouse_hook_) {
    UnhookWindowsHookEx(mouse_hook_);
    mouse_hook_ = nullptr;
  }

  // Cleanup raw input
  if (raw_input_hwnd_) {
    RAWINPUTDEVICE rid = {};
    rid.usUsagePage = 0x01;
    rid.usUsage = 0x06;
    rid.dwFlags = RIDEV_REMOVE;
    rid.hwndTarget = nullptr;
    RegisterRawInputDevices(&rid, 1, sizeof(rid));
    DestroyWindow(raw_input_hwnd_);
    raw_input_hwnd_ = nullptr;
  }

  hooks_active_.store(false);
}

void NativeHooksPlugin::StartHooks() {
  if (hook_thread_running_.load()) return;

  hook_thread_running_.store(true);
  hook_thread_ = std::thread([this]() {
    hook_thread_id_ = GetCurrentThreadId();
    HookThreadProc();
  });

  // Wait deterministically for hook thread readiness (Section 30: remove Sleep(100))
  int retries = 0;
  while (!hooks_active_.load() && retries < 20) {
    std::this_thread::sleep_for(std::chrono::milliseconds(5));
    retries++;
  }
}

void NativeHooksPlugin::StopHooks() {
  if (!hook_thread_running_.load()) return;

  hook_thread_running_.store(false);

  if (hook_thread_id_ != 0) {
    PostThreadMessage(hook_thread_id_, WM_QUIT, 0, 0);
  }

  if (hook_thread_.joinable()) {
    hook_thread_.join();
  }
  hook_thread_id_ = 0;
}

// ═══════════════════════════════════════════════════════
// LL KEYBOARD HOOK CALLBACK
// Still used for normal apps — provides better character detection
// ═══════════════════════════════════════════════════════

LRESULT CALLBACK NativeHooksPlugin::LowLevelKeyboardProc(
    int nCode, WPARAM wParam, LPARAM lParam) {
  if (nCode == HC_ACTION && instance_ && !instance_->is_typing_replacement_) {
    KBDLLHOOKSTRUCT* kb = reinterpret_cast<KBDLLHOOKSTRUCT*>(lParam);

    if (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN) {
      // LL hook fired — skip Raw Input for this key to avoid duplicates
      // Mark this VK as "handled by LL hook"
      BYTE keyboardState[256];
      GetKeyboardState(keyboardState);

      WCHAR unicodeChar[5] = {0};
      int result = ToUnicode(
          kb->vkCode, kb->scanCode, keyboardState,
          unicodeChar, 4, 0);

      HookEvent ev;
      ev.type = HookEventType::KeyPress;
      ev.vkCode = static_cast<int32_t>(kb->vkCode);

      if (result > 0) {
        int utf8_len = WideCharToMultiByte(
            CP_UTF8, 0, unicodeChar, result, nullptr, 0, nullptr, nullptr);
        std::string utf8_str(utf8_len, 0);
        WideCharToMultiByte(
            CP_UTF8, 0, unicodeChar, result,
            &utf8_str[0], utf8_len, nullptr, nullptr);
        ev.character = utf8_str;
      }

      instance_->EnqueueEvent(std::move(ev));

      // Mark in raw_keys_down_ so Raw Input skips this key
      instance_->raw_keys_down_.insert(static_cast<USHORT>(kb->vkCode));
    }
  }
  return CallNextHookEx(nullptr, nCode, wParam, lParam);
}

// ═══════════════════════════════════════════════════════
// LL MOUSE HOOK CALLBACK
// ═══════════════════════════════════════════════════════

LRESULT CALLBACK NativeHooksPlugin::LowLevelMouseProc(
    int nCode, WPARAM wParam, LPARAM lParam) {
  if (nCode == HC_ACTION && instance_) {
    MSLLHOOKSTRUCT* ms = reinterpret_cast<MSLLHOOKSTRUCT*>(lParam);

    // Herhangi bir tıklama olduğunda baloncuğu kapat
    // NOT: Hook ayrı thread'de çalıştığı için DestroyWindow direkt çağrılamaz
    // PostMessage ile pencereye mesaj gönderip doğru thread'de kapatıyoruz
    if (instance_->bubble_hwnd_ &&
        (wParam == WM_LBUTTONDOWN || wParam == WM_RBUTTONDOWN || wParam == WM_MBUTTONDOWN)) {
      PostMessage(instance_->bubble_hwnd_, WM_BUBBLE_DISMISS, 0, 0);
    }

    switch (wParam) {
      case WM_LBUTTONDOWN:
        instance_->mouse_left_pressed_ = true;
        instance_->mouse_pressed_pos_ = ms->pt;
        break;

      case WM_LBUTTONUP:
        if (instance_->mouse_left_pressed_) {
          instance_->mouse_left_pressed_ = false;
          double dist = sqrt(
              pow(static_cast<double>(ms->pt.x - instance_->mouse_pressed_pos_.x), 2) +
              pow(static_cast<double>(ms->pt.y - instance_->mouse_pressed_pos_.y), 2));

          if (dist > kDragThreshold) {
            HookEvent ev;
            ev.type = HookEventType::MouseDragEnd;
            ev.x = static_cast<int32_t>(ms->pt.x);
            ev.y = static_cast<int32_t>(ms->pt.y);
            ev.distance = dist;

            instance_->EnqueueEvent(std::move(ev));
          }
        }
        break;
    }
  }
  return CallNextHookEx(nullptr, nCode, wParam, lParam);
}

// ═══════════════════════════════════════════════════════
// CLIPBOARD OPERATIONS
// ═══════════════════════════════════════════════════════

std::string NativeHooksPlugin::GetClipboardText() {
  std::string text;
  if (OpenClipboard(nullptr)) {
    HANDLE hData = GetClipboardData(CF_UNICODETEXT);
    if (hData) {
      WCHAR* pszText = static_cast<WCHAR*>(GlobalLock(hData));
      if (pszText) {
        int utf8_len = WideCharToMultiByte(
            CP_UTF8, 0, pszText, -1, nullptr, 0, nullptr, nullptr);
        text.resize(utf8_len - 1);
        WideCharToMultiByte(
            CP_UTF8, 0, pszText, -1, &text[0], utf8_len, nullptr, nullptr);
        GlobalUnlock(hData);
      }
    }
    CloseClipboard();
  }
  return text;
}

void NativeHooksPlugin::SetClipboardText(const std::string& text) {
  int wide_len = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
  if (wide_len <= 0) return;

  HGLOBAL hMem = GlobalAlloc(GMEM_MOVEABLE, wide_len * sizeof(WCHAR));
  if (!hMem) return;

  WCHAR* pMem = static_cast<WCHAR*>(GlobalLock(hMem));
  if (pMem) {
    MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, pMem, wide_len);
    GlobalUnlock(hMem);

    if (OpenClipboard(nullptr)) {
      EmptyClipboard();
      SetClipboardData(CF_UNICODETEXT, hMem);
      CloseClipboard();
    } else {
      GlobalFree(hMem);
    }
  } else {
    GlobalFree(hMem);
  }
}

// ═══════════════════════════════════════════════════════
// INPUT SIMULATION — Hardware Scan Code mode
// CS2 ve diğer oyunlar wVk yerine donanım scan kodlarını okur.
// KEYEVENTF_SCANCODE flag'i ile wVk=0 yaparak donanım seviyesinde
// tuş basımı simüle ediyoruz.
// ═══════════════════════════════════════════════════════

static void SetKeyDown(INPUT& input, WORD vk) {
  input.type = INPUT_KEYBOARD;
  input.ki.wVk = 0;  // Oyunlar bunu okumaz, scan code kullanacağız
  input.ki.wScan = static_cast<WORD>(MapVirtualKey(vk, MAPVK_VK_TO_VSC));
  input.ki.dwFlags = KEYEVENTF_SCANCODE;
}

static void SetKeyUp(INPUT& input, WORD vk) {
  input.type = INPUT_KEYBOARD;
  input.ki.wVk = 0;
  input.ki.wScan = static_cast<WORD>(MapVirtualKey(vk, MAPVK_VK_TO_VSC));
  input.ki.dwFlags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP;
}

void NativeHooksPlugin::SimulateBackspace(int count) {
  is_typing_replacement_ = true;
  
  // Scan code for Backspace = 0x0E
  const WORD scanBack = 0x0E;
  
  for (int i = 0; i < count; i += 10) {
    int batchSize = (count - i > 10) ? 10 : (count - i);
    std::vector<INPUT> inputs;
    inputs.reserve(batchSize * 2);

    for (int j = 0; j < batchSize; j++) {
      INPUT down = {};
      down.type = INPUT_KEYBOARD;
      down.ki.wVk = 0;
      down.ki.wScan = scanBack;
      down.ki.dwFlags = KEYEVENTF_SCANCODE;
      inputs.push_back(down);

      INPUT up = {};
      up.type = INPUT_KEYBOARD;
      up.ki.wVk = 0;
      up.ki.wScan = scanBack;
      up.ki.dwFlags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP;
      inputs.push_back(up);
    }

    UINT sent = SendInput(static_cast<UINT>(inputs.size()), inputs.data(), sizeof(INPUT));
    if (sent != inputs.size()) {
      OutputDebugStringA("[NativeHooks] SendInput backspace failed or partial injection!\n");
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(2));
  }
  std::this_thread::sleep_for(std::chrono::milliseconds(15));
}

void NativeHooksPlugin::SimulatePaste() {
  // Ctrl scan code = 0x1D, V scan code = 0x2F
  INPUT inputs[4] = {};

  // Ctrl down
  inputs[0].type = INPUT_KEYBOARD;
  inputs[0].ki.wVk = 0;
  inputs[0].ki.wScan = 0x1D;
  inputs[0].ki.dwFlags = KEYEVENTF_SCANCODE;

  // V down
  inputs[1].type = INPUT_KEYBOARD;
  inputs[1].ki.wVk = 0;
  inputs[1].ki.wScan = 0x2F;
  inputs[1].ki.dwFlags = KEYEVENTF_SCANCODE;

  // V up
  inputs[2].type = INPUT_KEYBOARD;
  inputs[2].ki.wVk = 0;
  inputs[2].ki.wScan = 0x2F;
  inputs[2].ki.dwFlags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP;

  // Ctrl up
  inputs[3].type = INPUT_KEYBOARD;
  inputs[3].ki.wVk = 0;
  inputs[3].ki.wScan = 0x1D;
  inputs[3].ki.dwFlags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP;

  UINT sent = SendInput(4, inputs, sizeof(INPUT));
  if (sent != 4) {
    OutputDebugStringA("[NativeHooks] SendInput paste failed or partial injection!\n");
  }
  std::this_thread::sleep_for(std::chrono::milliseconds(50));
  is_typing_replacement_ = false;
}

void NativeHooksPlugin::SimulateKeyPress(int vk_code) {
  INPUT inputs[2] = {};
  WORD scan = static_cast<WORD>(MapVirtualKey(vk_code, MAPVK_VK_TO_VSC));

  inputs[0].type = INPUT_KEYBOARD;
  inputs[0].ki.wVk = 0;
  inputs[0].ki.wScan = scan;
  inputs[0].ki.dwFlags = KEYEVENTF_SCANCODE;

  inputs[1].type = INPUT_KEYBOARD;
  inputs[1].ki.wVk = 0;
  inputs[1].ki.wScan = scan;
  inputs[1].ki.dwFlags = KEYEVENTF_SCANCODE | KEYEVENTF_KEYUP;

  UINT sent = SendInput(2, inputs, sizeof(INPUT));
  if (sent != 2) {
    OutputDebugStringA("[NativeHooks] SendInput keypress failed!\n");
  }
}

void NativeHooksPlugin::SimulateCopy() {
  is_typing_replacement_ = true;
  INPUT inputs[4] = {};
  SetKeyDown(inputs[0], VK_CONTROL);
  SetKeyDown(inputs[1], 0x43);
  SetKeyUp(inputs[2], 0x43);
  SetKeyUp(inputs[3], VK_CONTROL);

  SendInput(4, inputs, sizeof(INPUT));
  Sleep(30);
  is_typing_replacement_ = false;
}

POINT NativeHooksPlugin::GetMousePosition() {
  POINT pt;
  GetCursorPos(&pt);
  return pt;
}

// ═══════════════════════════════════════════════════════
// NATIVE BUBBLE TOOLTIP WINDOW
// ═══════════════════════════════════════════════════════

static constexpr wchar_t kBubbleClassName[] = L"QuickTraceBubble";
static constexpr UINT_PTR kBubbleTimerId = 1001;
static constexpr int kBubbleAutoHideMs = 8000;

void NativeHooksPlugin::RegisterBubbleClass() {
  if (bubble_class_registered_) return;

  WNDCLASSEXW wc = {};
  wc.cbSize = sizeof(WNDCLASSEXW);
  wc.style = CS_HREDRAW | CS_VREDRAW;
  wc.lpfnWndProc = BubbleWndProc;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  wc.hbrBackground = nullptr;
  wc.lpszClassName = kBubbleClassName;

  if (RegisterClassExW(&wc)) {
    bubble_class_registered_ = true;
  }
}

LRESULT CALLBACK NativeHooksPlugin::BubbleWndProc(
    HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
  // WM_BUBBLE_DISMISS: Hook thread'den gelen kapatma isteği
  if (msg == WM_BUBBLE_DISMISS) {
    if (instance_) instance_->HideBubble();
    return 0;
  }

  switch (msg) {
    case WM_PAINT:
      if (instance_) {
        instance_->PaintBubble(hwnd);
      }
      return 0;

    case WM_TIMER:
      if (wParam == kBubbleTimerId && instance_) {
        instance_->HideBubble();
      }
      return 0;

    case WM_LBUTTONDOWN:
    case WM_RBUTTONDOWN:
    case WM_MBUTTONDOWN:
      if (instance_) {
        instance_->HideBubble();
      }
      return 0;

    case WM_CLOSE:
      if (instance_) {
        instance_->HideBubble();
      }
      return 0;

    case WM_DESTROY:
      KillTimer(hwnd, kBubbleTimerId);
      return 0;
  }
  return DefWindowProc(hwnd, msg, wParam, lParam);
}

void NativeHooksPlugin::PaintBubble(HWND hwnd) {
  PAINTSTRUCT ps;
  HDC hdc = BeginPaint(hwnd, &ps);

  RECT rc;
  GetClientRect(hwnd, &rc);

  HDC memDC = CreateCompatibleDC(hdc);
  HBITMAP memBitmap = CreateCompatibleBitmap(hdc, rc.right, rc.bottom);
  HBITMAP oldBitmap = (HBITMAP)SelectObject(memDC, memBitmap);

  HBRUSH bgBrush = CreateSolidBrush(kBubbleBgColor);
  HPEN borderPen = CreatePen(PS_SOLID, 1, kBubbleBorderColor);
  HBRUSH oldBrush = (HBRUSH)SelectObject(memDC, bgBrush);
  HPEN oldPen = (HPEN)SelectObject(memDC, borderPen);

  RoundRect(memDC, 0, 0, rc.right, rc.bottom,
            kBubbleCornerRadius * 2, kBubbleCornerRadius * 2);

  SelectObject(memDC, oldBrush);
  SelectObject(memDC, oldPen);
  DeleteObject(bgBrush);
  DeleteObject(borderPen);

  if (!bubble_font_) {
    bubble_font_ = CreateFontW(
        -kBubbleFontSize, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_SWISS, L"Segoe UI");
  }

  HFONT oldFont = (HFONT)SelectObject(memDC, bubble_font_);
  SetTextColor(memDC, kBubbleTextColor);
  SetBkMode(memDC, TRANSPARENT);

  RECT textRect = rc;
  textRect.left += kBubblePadding;
  textRect.top += kBubblePadding;
  textRect.right -= kBubblePadding;
  textRect.bottom -= kBubblePadding;

  DrawTextW(memDC, bubble_text_.c_str(), -1, &textRect,
            DT_LEFT | DT_TOP | DT_WORDBREAK | DT_NOPREFIX);

  SelectObject(memDC, oldFont);

  BitBlt(hdc, 0, 0, rc.right, rc.bottom, memDC, 0, 0, SRCCOPY);

  SelectObject(memDC, oldBitmap);
  DeleteObject(memBitmap);
  DeleteDC(memDC);

  EndPaint(hwnd, &ps);
}

void NativeHooksPlugin::ShowBubble(const std::string& text, int x, int y) {
  HideBubble();
  RegisterBubbleClass();

  int wide_len = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
  bubble_text_.resize(wide_len - 1);
  MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, &bubble_text_[0], wide_len);

  if (!bubble_font_) {
    bubble_font_ = CreateFontW(
        -kBubbleFontSize, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
        DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
        CLEARTYPE_QUALITY, DEFAULT_PITCH | FF_SWISS, L"Segoe UI");
  }

  HDC screenDC = GetDC(nullptr);
  HFONT oldFont = (HFONT)SelectObject(screenDC, bubble_font_);

  RECT calcRect = {0, 0, kBubbleMaxWidth - (kBubblePadding * 2), 0};
  DrawTextW(screenDC, bubble_text_.c_str(), -1, &calcRect,
            DT_CALCRECT | DT_WORDBREAK | DT_NOPREFIX);

  SelectObject(screenDC, oldFont);
  ReleaseDC(nullptr, screenDC);

  int wndWidth = calcRect.right + (kBubblePadding * 2);
  int wndHeight = calcRect.bottom + (kBubblePadding * 2);

  if (wndWidth < 120) wndWidth = 120;
  if (wndHeight < 40) wndHeight = 40;

  POINT pt = {x, y};
  HMONITOR hMonitor = MonitorFromPoint(pt, MONITOR_DEFAULTTONEAREST);
  MONITORINFO mi = { sizeof(MONITORINFO) };
  GetMonitorInfoW(hMonitor, &mi);
  RECT workArea = mi.rcWork;

  int posX = x + kBubbleOffsetX;
  int posY = y + kBubbleOffsetY;

  if (posX + wndWidth > workArea.right) posX = x - wndWidth - kBubbleOffsetX;
  if (posY + wndHeight > workArea.bottom) posY = y - wndHeight - kBubbleOffsetY;
  if (posX < workArea.left) posX = workArea.left + 10;
  if (posY < workArea.top) posY = workArea.top + 10;

  bubble_hwnd_ = CreateWindowExW(
      WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE,
      kBubbleClassName, L"", WS_POPUP,
      posX, posY, wndWidth, wndHeight,
      nullptr, nullptr, GetModuleHandle(nullptr), nullptr);

  if (bubble_hwnd_) {
    ShowWindow(bubble_hwnd_, SW_SHOWNOACTIVATE);
    SetWindowPos(bubble_hwnd_, HWND_TOPMOST,
                 posX, posY, wndWidth, wndHeight,
                 SWP_NOACTIVATE | SWP_SHOWWINDOW);
    UpdateWindow(bubble_hwnd_);
    SetTimer(bubble_hwnd_, kBubbleTimerId, kBubbleAutoHideMs, nullptr);
  }
}

void NativeHooksPlugin::HideBubble() {
  if (bubble_hwnd_) {
    KillTimer(bubble_hwnd_, kBubbleTimerId);
    DestroyWindow(bubble_hwnd_);
    bubble_hwnd_ = nullptr;
  }
}


