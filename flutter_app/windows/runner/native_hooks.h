#ifndef RUNNER_NATIVE_HOOKS_H_
#define RUNNER_NATIVE_HOOKS_H_

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/flutter_engine.h>
#include <windows.h>
#include <string>
#include <mutex>
#include <thread>
#include <atomic>
#include <queue>
#include <set>

// Channel name constant
constexpr char kChannelName[] = "com.quicktrace/native_hooks";

// Method names sent FROM Dart
constexpr char kMethodStartHooks[] = "startHooks";
constexpr char kMethodStopHooks[] = "stopHooks";
constexpr char kMethodGetClipboardText[] = "getClipboardText";
constexpr char kMethodSetClipboardText[] = "setClipboardText";
constexpr char kMethodSimulateBackspace[] = "simulateBackspace";
constexpr char kMethodSimulatePaste[] = "simulatePaste";
constexpr char kMethodSimulateKeyPress[] = "simulateKeyPress";
constexpr char kMethodSimulateCopy[] = "simulateCopy";
constexpr char kMethodGetMousePosition[] = "getMousePosition";
constexpr char kMethodShowBubble[] = "showBubble";
constexpr char kMethodHideBubble[] = "hideBubble";
constexpr char kMethodPollEvents[] = "pollEvents";

// Event names sent TO Dart (used inside pollEvents response)
constexpr char kEventKeyPress[] = "onKeyPress";
constexpr char kEventMouseDragEnd[] = "onMouseDragEnd";

// Bubble window constants
constexpr int kBubblePadding = 16;
constexpr int kBubbleMaxWidth = 400;
constexpr int kBubbleOffsetX = 20;
constexpr int kBubbleOffsetY = 20;
constexpr int kBubbleCornerRadius = 12;
constexpr int kBubbleFontSize = 15;
constexpr COLORREF kBubbleBgColor = RGB(30, 30, 46);
constexpr COLORREF kBubbleTextColor = RGB(205, 214, 244);
constexpr COLORREF kBubbleBorderColor = RGB(69, 71, 90);

// Hook event types for the queue
enum class HookEventType {
  KeyPress,
  MouseDragEnd,
};

struct HookEvent {
  HookEventType type;
  int32_t vkCode = 0;
  std::string character;
  int32_t x = 0;
  int32_t y = 0;
  double distance = 0.0;
};

class NativeHooksPlugin {
 public:
  explicit NativeHooksPlugin(
      std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel);
  ~NativeHooksPlugin();

  void SetupMethodHandler();



 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void StartHooks();
  void StopHooks();
  std::string GetClipboardText();
  void SetClipboardText(const std::string& text);
  void SimulateBackspace(int count);
  void SimulatePaste();
  void SimulateKeyPress(int vk_code);
  void SimulateCopy();
  POINT GetMousePosition();

  // Polling: Dart calls this periodically to get queued events
  flutter::EncodableList PollEvents();

  // Native bubble tooltip
  void ShowBubble(const std::string& text, int x, int y);
  void HideBubble();
  static LRESULT CALLBACK BubbleWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
  void RegisterBubbleClass();
  void PaintBubble(HWND hwnd);

  // Hook callbacks (static for Win32 API)
  static LRESULT CALLBACK LowLevelKeyboardProc(int nCode, WPARAM wParam, LPARAM lParam);
  static LRESULT CALLBACK LowLevelMouseProc(int nCode, WPARAM wParam, LPARAM lParam);

  // Raw Input hidden window (fallback for games like CS2)
  static LRESULT CALLBACK RawInputWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
  void ProcessRawKeyboard(RAWKEYBOARD& rawKb);
  HWND raw_input_hwnd_ = nullptr;
  bool raw_input_class_registered_ = false;
  std::set<USHORT> raw_keys_down_;  // Track key state for keydown detection

  // Thread-safe event queue: hook thread pushes, Dart polls
  void EnqueueEvent(HookEvent event);
  std::queue<HookEvent> event_queue_;
  std::mutex queue_mutex_;

  // Hook thread (dedicated message pump)
  void HookThreadProc();
  std::thread hook_thread_;
  std::atomic<bool> hook_thread_running_{false};
  DWORD hook_thread_id_ = 0;

  // Instance pointer for callbacks
  static NativeHooksPlugin* instance_;

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  HHOOK keyboard_hook_ = nullptr;
  HHOOK mouse_hook_ = nullptr;
  std::atomic<bool> hooks_active_{false};
  bool is_typing_replacement_ = false;

  // Mouse tracking
  POINT mouse_pressed_pos_ = {0, 0};
  bool mouse_left_pressed_ = false;
  static constexpr int kDragThreshold = 15;

  // Bubble window
  HWND bubble_hwnd_ = nullptr;
  bool bubble_class_registered_ = false;
  std::wstring bubble_text_;
  HFONT bubble_font_ = nullptr;

  std::mutex mutex_;
};

#endif  // RUNNER_NATIVE_HOOKS_H_
