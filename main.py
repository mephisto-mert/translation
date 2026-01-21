import customtkinter as ctk
import threading
from pynput import mouse, keyboard
from pynput.keyboard import Key, Controller
from translator_service import TranslationService
import utils
import sys
import time
import math
import pyperclip
import queue

# --- LOADING INDICATOR ---
class LoadingIndicator(ctk.CTkToplevel):
    def __init__(self, x, y):
        super().__init__()
        self.withdraw()
        self.overrideredirect(True)
        self.attributes('-topmost', True)
        self.attributes('-alpha', 0.9)
        if sys.platform.startswith("win"):
            self.wm_attributes("-toolwindow", True)

        # Center dot near mouse
        self.geometry(f"24x24+{x+20}+{y+20}")
        self.configure(fg_color="transparent")
        
        self.dot = ctk.CTkFrame(self, width=16, height=16, corner_radius=8, fg_color="#FACC15") # Yellow indicator
        self.dot.pack(expand=True)
        self.deiconify()

# --- MODERN SCROLLABLE TOOLTIP ---
class Tooltip(ctk.CTkToplevel):
    def __init__(self, translated_text, x=0, y=0):
        super().__init__()
        self.withdraw()
        self.overrideredirect(True)
        self.attributes('-topmost', True)
        self.attributes('-alpha', 0.95)
        
        if sys.platform.startswith("win"):
            self.wm_attributes("-toolwindow", True)
        
        # Pro Max Slate colors
        bg_color = "#0f172a"  
        self.configure(fg_color=bg_color, corner_radius=14)
        
        main_frame = ctk.CTkFrame(self, fg_color="transparent", corner_radius=14)
        main_frame.pack(padx=2, pady=2, fill="both", expand=True)
        
        # Click to close
        main_frame.bind("<Button-1>", lambda e: self.safe_destroy())
        self.bind("<Button-1>", lambda e: self.safe_destroy())

        # Dynamic size calculation
        target_width = min(700, max(400, len(translated_text) * 10))
        chars_per_line = target_width / 9 
        est_lines = math.ceil(len(translated_text) / chars_per_line)
        newline_count = translated_text.count('\n')
        total_lines = est_lines + newline_count
        target_height = int((total_lines * 26) + 60)
        
        if target_height > 500: target_height = 500

        # Position (center near mouse if possible, or screen center)
        screen_width = self.winfo_screenwidth()
        screen_height = self.winfo_screenheight()
        center_x = max(20, min(screen_width - target_width - 20, x + 15))
        center_y = max(20, min(screen_height - target_height - 20, y + 15))
        self.geometry(f"{target_width}x{target_height}+{center_x}+{center_y}")

        self.scroll_frame = ctk.CTkScrollableFrame(main_frame, fg_color="#1e293b", corner_radius=12)
        self.scroll_frame.pack(padx=1, pady=1, fill="both", expand=True)
        
        translation_label = ctk.CTkLabel(
            self.scroll_frame, 
            text=translated_text, 
            font=("Segoe UI", 14),
            text_color="#f1f5f9",
            justify="left",
            wraplength=target_width - 60, 
            anchor="w"
        )
        translation_label.pack(padx=20, pady=20, fill="x", expand=True)
        translation_label.bind("<Button-1>", lambda e: self.safe_destroy())
        
        self.deiconify()
        self.after(15000, self.safe_destroy) # 15 sec auto-close
    
    def safe_destroy(self):
        try: self.destroy()
        except: pass

class SettingCard(ctk.CTkFrame):
    def __init__(self, master, title, **kwargs):
        super().__init__(master, fg_color="#1e293b", corner_radius=12, **kwargs)
        self.label = ctk.CTkLabel(self, text=title, font=("Segoe UI", 12, "bold"), text_color="#64748b")
        self.label.pack(anchor="w", padx=16, pady=(12, 4))
        self.content = ctk.CTkFrame(self, fg_color="transparent")
        self.content.pack(fill="x", padx=4, pady=4)

class translationApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.title("Quick Translate Pro")
        self.geometry("450x580")
        ctk.set_appearance_mode("Dark")
        self.configure(fg_color="#0f172a") # Slate 950
        
        self.translator = TranslationService(source='auto', target='tr')
        self.languages = {
            "Auto Detect": "auto", "Turkish": "tr", "English": "en", "German": "de", 
            "French": "fr", "Spanish": "es", "Italian": "it", "Russian": "ru", 
            "Japanese": "ja", "Chinese": "zh-CN", "Arabic": "ar"
        }
        
        self.active_tooltip = None
        self.loading_indicator = None
        self.is_running = True
        self.bubble_mode = ctk.BooleanVar(value=True)
        self.input_mode = ctk.BooleanVar(value=False)
        self.typed_buffer = ""
        self.is_typing_replacement = False 
        self.last_text = ""
        self.last_trigger_time = 0
        self.kb_controller = Controller()
        self.translation_queue = queue.Queue()
        threading.Thread(target=self.process_queue, daemon=True).start()

        self.mouse_pressed_pos = None
        self.drag_threshold = 10 

        self.setup_ui()
        self.start_mouse_listener()
        self.start_keyboard_listener()
        self.check_status()

    def setup_ui(self):
        self.main_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.main_frame.pack(fill="both", expand=True, padx=24, pady=24)

        # Header with Pro Badge
        header_row = ctk.CTkFrame(self.main_frame, fg_color="transparent")
        header_row.pack(fill="x", pady=(0, 20))
        
        self.title_label = ctk.CTkLabel(header_row, text="Quick Trace", font=("Segoe UI", 26, "bold"), text_color="white")
        self.title_label.pack(side="left")
        
        self.badge = ctk.CTkLabel(header_row, text="PRO", font=("Segoe UI", 10, "bold"), 
                                fg_color="#3b82f6", text_color="white", corner_radius=6, width=35)
        self.badge.pack(side="left", padx=10)

        # Internet Status
        self.status_frame = ctk.CTkFrame(self.main_frame, fg_color="#1e293b", corner_radius=8, height=30)
        self.status_frame.pack(fill="x", pady=(0, 16))
        self.status_dot = ctk.CTkLabel(self.status_frame, text="●", font=("Arial", 14), text_color="#94a3b8")
        self.status_dot.pack(side="left", padx=(10, 5))
        self.status_label = ctk.CTkLabel(self.status_frame, text="Checking connection...", font=("Segoe UI", 11))
        self.status_label.pack(side="left")

        # Source Lang Card
        self.src_card = SettingCard(self.main_frame, title="SOURCE LANGUAGE")
        self.src_card.pack(fill="x", pady=(0, 12))
        self.src_menu = ctk.CTkOptionMenu(self.src_card.content, values=list(self.languages.keys()),
                                        command=self.change_source, fg_color="#334155", button_color="#475569")
        self.src_menu.pack(fill="x", padx=12, pady=10)
        self.src_menu.set("Auto Detect")

        # Target Lang Card
        self.tgt_card = SettingCard(self.main_frame, title="TARGET LANGUAGE")
        self.tgt_card.pack(fill="x", pady=(0, 12))
        self.tgt_menu = ctk.CTkOptionMenu(self.tgt_card.content, values=list(self.languages.keys()),
                                        command=self.change_target, fg_color="#334155", button_color="#475569")
        self.tgt_menu.pack(fill="x", padx=12, pady=10)
        self.tgt_menu.set("Turkish")

        # Modes Card
        self.modes_card = SettingCard(self.main_frame, title="ACTIVE MODES")
        self.modes_card.pack(fill="x", pady=(0, 16))
        self.bubble_switch = ctk.CTkSwitch(self.modes_card.content, text="Bubble Mode (Mouse)", variable=self.bubble_mode, progress_color="#3b82f6")
        self.bubble_switch.pack(pady=8, padx=16, anchor="w")
        self.input_switch = ctk.CTkSwitch(self.modes_card.content, text="Input Mode (Keyboard)", variable=self.input_mode, progress_color="#10b981")
        self.input_switch.pack(pady=(0, 8), padx=16, anchor="w")

        # Footer
        self.minimize_btn = ctk.CTkButton(self.main_frame, text="Minimize to Tray", command=self.iconify,
                                        fg_color="transparent", border_width=1, border_color="#334155", hover_color="#1e293b")
        self.minimize_btn.pack(side="bottom", fill="x")

    def check_status(self):
        if utils.check_internet_connection():
            self.status_dot.configure(text_color="#10b981")
            self.status_label.configure(text="System Online & Ready")
        else:
            self.status_dot.configure(text_color="#ef4444")
            self.status_label.configure(text="Offline - Check Connection")
        self.after(10000, self.check_status)

    def change_source(self, choice): self.translator.set_source_language(self.languages[choice])
    def change_target(self, choice): self.translator.set_target_language(self.languages[choice])

    def process_queue(self):
        while True:
            try:
                text, is_enter = self.translation_queue.get()
                if text: self.process_input_translation(text, is_enter)
                self.translation_queue.task_done()
            except Exception: pass

    def start_mouse_listener(self):
        def on_click(x, y, button, pressed):
            if not self.is_running: return
            if pressed:
                self.typed_buffer = ""
                self.after(0, self.hide_tooltip)
                if button == mouse.Button.left: self.mouse_pressed_pos = (x, y)
            elif button == mouse.Button.left:
                if self.mouse_pressed_pos:
                    dist = math.hypot(x - self.mouse_pressed_pos[0], y - self.mouse_pressed_pos[1])
                    self.mouse_pressed_pos = None
                    if self.bubble_mode.get() and dist > self.drag_threshold:
                        threading.Timer(0.15, self.perform_translation).start()
        self.mouse_listener = mouse.Listener(on_click=on_click)
        self.mouse_listener.start()

    def start_keyboard_listener(self):
        def on_press(key):
            if not self.is_running or not self.input_mode.get(): return
            
            # CRITICAL: If we are already replacing, ignore and potentially count
            if self.is_typing_replacement:
                return

            try:
                char = getattr(key, "char", None)
                triggers = [".", "!", "?"]
                
                # Navigation Keys Reset
                nav_keys = [keyboard.Key.left, keyboard.Key.right, keyboard.Key.up, keyboard.Key.down, 
                            keyboard.Key.home, keyboard.Key.end]
                if key in nav_keys:
                    self.typed_buffer = ""
                    return

                if key == keyboard.Key.enter or (char and char in triggers):
                    # SAFETY LOCK: Lock listener IMMEDIATELY before pushing to queue
                    now = time.time()
                    if now - self.last_trigger_time < 0.3: return # Debounce
                    self.last_trigger_time = now
                    
                    text_to_translate = self.typed_buffer
                    self.typed_buffer = ""
                    
                    # Lock input while this specific task is being handled
                    self.is_typing_replacement = True
                    self.translation_queue.put((text_to_translate, key == keyboard.Key.enter))
                
                elif key == keyboard.Key.backspace:
                    if len(self.typed_buffer) > 0: self.typed_buffer = self.typed_buffer[:-1]
                elif char: 
                    self.typed_buffer += char
                elif key == keyboard.Key.space: 
                    self.typed_buffer += " "
            except: pass
        self.kb_listener = keyboard.Listener(on_press=on_press)
        self.kb_listener.start()

    def show_loading(self):
        try:
            x, y = utils.get_mouse_position()
            self.loading_indicator = LoadingIndicator(x, y)
        except: pass

    def hide_loading(self):
        if self.loading_indicator:
            try: self.loading_indicator.destroy()
            except: pass
            self.loading_indicator = None

    def process_input_translation(self, text, is_enter):
        if not text or len(text) < 1: 
            self.is_typing_replacement = False
            return
            
        self.after(0, self.show_loading)
        
        # 1. SETTLING DELAY (Crucial to prevent 'sHello' residual characters)
        # Give the OS a moment to process the trigger key and user to stop typing
        time.sleep(0.1)

        try:
            # 2. Start Translation
            translation_result = {"text": None, "target": self.translator.target}
            def run_translation():
                try:
                    res, target = self.translator.translate(text) # Don't strip here yet
                    translation_result["text"] = res
                    translation_result["target"] = target
                except: pass
            t_trans = threading.Thread(target=run_translation)
            t_trans.start()

            # 3. DELETE EXACTLY WHAT WAS TYPED (Pinpoint Accuracy)
            # (+1 for the trigger key)
            delete_count = len(text) + 1
            
            for _ in range(delete_count):
                self.kb_controller.tap(keyboard.Key.backspace)
                time.sleep(0.015) 
            
            t_trans.join(timeout=3)
            translated = translation_result["text"]
            used_target = translation_result["target"]

            if not translated: 
                final_text = text
            else:
                # Format ONLY after translation
                final_text = utils.fix_punctuation_input_mode(utils.smart_capitalize(translated.strip()), used_target)

            old_clip = utils.get_clipboard_safe()
            pyperclip.copy(final_text)
            
            # Paste with small delay to ensure clipboard is ready
            time.sleep(0.05)
            if sys.platform == "darwin":
                with self.kb_controller.pressed(keyboard.Key.cmd): self.kb_controller.tap('v')
            else:
                with self.kb_controller.pressed(keyboard.Key.ctrl): self.kb_controller.tap('v')
            
            time.sleep(0.1)
            if is_enter: self.kb_controller.tap(keyboard.Key.enter)
            else: self.kb_controller.type(" ") 
            
            time.sleep(0.1)
            if old_clip: pyperclip.copy(old_clip)

        except Exception: pass
        finally:
            self.after(0, self.hide_loading)
            self.is_typing_replacement = False

    def perform_translation(self):
        raw_text = utils.get_selected_text()  
        if not raw_text or len(raw_text.strip()) < 2: return
        
        cleaned = utils.clean_text_for_translation(raw_text)
        if cleaned == self.last_text: return
        self.last_text = cleaned

        translated, _ = self.translator.translate(cleaned)
        if translated: self.after(0, lambda: self.show_tooltip(translated))

    def hide_tooltip(self):
        if self.active_tooltip:
            self.active_tooltip.safe_destroy()
            self.active_tooltip = None

    def show_tooltip(self, translated_text):
        self.hide_tooltip()
        try:
            x, y = utils.get_mouse_position()
            self.active_tooltip = Tooltip(translated_text, x, y)
        except: pass

    def on_closing(self):
        self.is_running = False
        try:
            self.mouse_listener.stop()
            self.kb_listener.stop()
        except: pass
        self.destroy()
        sys.exit()

if __name__ == "__main__":
    app = translationApp()
    app.protocol("WM_DELETE_WINDOW", app.on_closing)
    app.mainloop()
