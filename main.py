import tkinter
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
from PIL import Image
import os
from locales import STRINGS, NAME_TO_CODE_TR, NAME_TO_CODE_EN
from constants import (
    Colors, Fonts, Dimensions, Timers, Limits, Defaults,
    SUPPORTED_FLAG_CODES, FLAG_ASSETS_DIR,
    PLATFORM_WINDOWS_PREFIX, PLATFORM_DARWIN, INPUT_TRIGGER_CHARS,
)


# --- LOADING INDICATOR ---
class LoadingIndicator(ctk.CTkToplevel):
    def __init__(self, x, y):
        super().__init__()
        self.withdraw()
        self.overrideredirect(True)
        self.attributes('-topmost', True)
        self.attributes('-alpha', Limits.LOADING_ALPHA)
        if sys.platform.startswith(PLATFORM_WINDOWS_PREFIX):
            self.wm_attributes("-toolwindow", True)
        pos_x = x + Dimensions.LOADING_OFFSET
        pos_y = y + Dimensions.LOADING_OFFSET
        self.geometry(f"{Dimensions.LOADING_SIZE}x{Dimensions.LOADING_SIZE}+{pos_x}+{pos_y}")
        self.configure(fg_color=Colors.TRANSPARENT)
        self.dot = ctk.CTkFrame(
            self,
            width=Dimensions.LOADING_DOT_SIZE,
            height=Dimensions.LOADING_DOT_SIZE,
            corner_radius=Dimensions.LOADING_DOT_RADIUS,
            fg_color=Colors.ACCENT_YELLOW,
        )
        self.dot.pack(expand=True)
        self.deiconify()


# --- MODERN SCROLLABLE TOOLTIP ---
class Tooltip(ctk.CTkToplevel):
    def __init__(self, translated_text, x=0, y=0):
        super().__init__()
        self.withdraw()
        self.overrideredirect(True)
        self.attributes('-topmost', True)
        self.attributes('-alpha', Limits.TOOLTIP_ALPHA)
        if sys.platform.startswith(PLATFORM_WINDOWS_PREFIX):
            self.wm_attributes("-toolwindow", True)
        self.configure(fg_color=Colors.BG_PRIMARY, corner_radius=Dimensions.TOOLTIP_CORNER_RADIUS)
        main_frame = ctk.CTkFrame(
            self, fg_color=Colors.TRANSPARENT, corner_radius=Dimensions.TOOLTIP_CORNER_RADIUS
        )
        main_frame.pack(padx=2, pady=2, fill="both", expand=True)
        main_frame.bind("<Button-1>", lambda e: self.safe_destroy())
        self.bind("<Button-1>", lambda e: self.safe_destroy())

        target_width = min(
            Dimensions.TOOLTIP_MAX_WIDTH,
            max(Dimensions.TOOLTIP_MIN_WIDTH, len(translated_text) * Dimensions.TOOLTIP_CHAR_WIDTH),
        )
        chars_per_line = target_width / Dimensions.TOOLTIP_CHARS_PER_LINE
        est_lines = math.ceil(len(translated_text) / chars_per_line)
        newline_count = translated_text.count('\n')
        total_lines = est_lines + newline_count
        target_height = int((total_lines * Dimensions.TOOLTIP_LINE_HEIGHT) + Dimensions.TOOLTIP_PADDING)
        if target_height > Dimensions.TOOLTIP_MAX_HEIGHT:
            target_height = Dimensions.TOOLTIP_MAX_HEIGHT

        screen_width = self.winfo_screenwidth()
        screen_height = self.winfo_screenheight()
        margin = Dimensions.TOOLTIP_SCREEN_MARGIN
        offset = Dimensions.TOOLTIP_OFFSET
        center_x = max(margin, min(screen_width - target_width - margin, x + offset))
        center_y = max(margin, min(screen_height - target_height - margin, y + offset))
        self.geometry(f"{target_width}x{target_height}+{center_x}+{center_y}")

        self.scroll_frame = ctk.CTkScrollableFrame(
            main_frame, fg_color=Colors.BG_CARD, corner_radius=Dimensions.CARD_CORNER_RADIUS
        )
        self.scroll_frame.pack(padx=1, pady=1, fill="both", expand=True)
        
        translation_label = ctk.CTkLabel(
            self.scroll_frame, 
            text=translated_text, 
            font=Fonts.HEADING,
            text_color=Colors.TEXT_BODY,
            justify="left",
            wraplength=target_width - Dimensions.TOOLTIP_PADDING, 
            anchor="w"
        )
        translation_label.pack(padx=20, pady=20, fill="x", expand=True)
        translation_label.bind("<Button-1>", lambda e: self.safe_destroy())
        self.deiconify()
        self.after(Timers.TOOLTIP_AUTO_CLOSE_MS, self.safe_destroy)
    
    def safe_destroy(self):
        try:
            self.destroy()
        except (tkinter.TclError, RuntimeError):
            pass


class SettingCard(ctk.CTkFrame):
    def __init__(self, master, title, **kwargs):
        super().__init__(
            master,
            fg_color=Colors.BG_CARD,
            corner_radius=Dimensions.CARD_CORNER_RADIUS,
            border_width=1,
            border_color=Colors.BORDER,
            **kwargs,
        )
        self.label = ctk.CTkLabel(
            self, text=title, font=Fonts.CAPTION_BOLD, text_color=Colors.TEXT_SECONDARY
        )
        self.label.pack(anchor="w", padx=20, pady=(15, 5))
        self.content = ctk.CTkFrame(self, fg_color=Colors.TRANSPARENT)
        self.content.pack(fill="x", padx=6, pady=(0, 6))


class LanguageSelector(ctk.CTkFrame):
    def __init__(self, master, languages, current_var, command, flag_images, **kwargs):
        super().__init__(master, fg_color=Colors.TRANSPARENT, **kwargs)
        self.languages = languages
        self.current_var = current_var
        self.command = command
        self.flag_images = flag_images
        self.is_open = False
        
        self.main_btn = ctk.CTkButton(
            self,
            text=f"  {self.current_var.get()}",
            image=self.get_current_image(),
            compound="left",
            command=self.toggle_dropdown,
            fg_color=Colors.BG_BUTTON,
            hover_color=Colors.BG_BUTTON_HOVER,
            height=Dimensions.BUTTON_HEIGHT,
            anchor="w",
            font=Fonts.BODY,
        )
        self.main_btn.pack(fill="x")
        
        self.dropdown_frame = ctk.CTkScrollableFrame(
            self,
            height=Dimensions.DROPDOWN_HEIGHT,
            fg_color=Colors.BG_CARD,
            corner_radius=Dimensions.DROPDOWN_CORNER_RADIUS,
        )
        self.buttons = [] 
        self.refresh_list(languages)

    def refresh_list(self, new_languages):
        self.languages = new_languages
        for btn in self.buttons:
            btn.destroy()
        self.buttons = []
        for name, code in self.languages.items():
            mapped_code = code if code != Defaults.SOURCE_LANG else Defaults.SOURCE_LANG
            img = self.flag_images.get(mapped_code)
            btn = ctk.CTkButton(
                self.dropdown_frame,
                text=f"  {name}",
                image=img,
                compound="left",
                command=lambda n=name, c=code: self.select_item(n, c),
                fg_color=Colors.TRANSPARENT,
                hover_color=Colors.BG_BUTTON,
                height=30,
                anchor="w",
                font=Fonts.BODY,
            )
            btn.pack(fill="x", pady=1)
            self.buttons.append(btn)
        self.main_btn.configure(text=f"  {self.current_var.get()}", image=self.get_current_image())

    def get_current_image(self):
        code = Defaults.SOURCE_LANG
        for name, c in self.languages.items():
            if name == self.current_var.get():
                code = c
                break
        return self.flag_images.get(code)

    def toggle_dropdown(self):
        if self.is_open:
            self.dropdown_frame.pack_forget()
        else:
            self.dropdown_frame.pack(fill="x", pady=(4, 0))
        self.is_open = not self.is_open

    def select_item(self, name, code):
        self.current_var.set(name)
        self.main_btn.configure(text=f"  {name}", image=self.flag_images.get(code))
        self.dropdown_frame.pack_forget()
        self.is_open = False
        if self.command:
            self.command(name)


class TranslationApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        self.ui_lang = Defaults.UI_LANG
        self.s = STRINGS[self.ui_lang]
        self.title(self.s["window_title"])
        self.geometry(Dimensions.WINDOW_GEOMETRY)
        ctk.set_appearance_mode("Dark")
        self.configure(fg_color=Colors.BG_PRIMARY)
        
        self.flag_images = {}
        for f in SUPPORTED_FLAG_CODES:
            try:
                pil_img = Image.open(f"{FLAG_ASSETS_DIR}/{f}.png")
                self.flag_images[f] = ctk.CTkImage(
                    light_image=pil_img, dark_image=pil_img, size=Dimensions.FLAG_SIZE
                )
            except (FileNotFoundError, OSError):
                pass

        self.translator = TranslationService(source=Defaults.SOURCE_LANG, target=Defaults.TARGET_LANG)
        self.languages = NAME_TO_CODE_TR if self.ui_lang == "tr" else NAME_TO_CODE_EN
        
        self.active_tooltip = None
        self.loading_indicator = None
        self.is_running = True
        self.bubble_mode = ctk.BooleanVar(value=Defaults.BUBBLE_MODE_ON)
        self.input_mode = ctk.BooleanVar(value=Defaults.INPUT_MODE_ON)
        
        auto_key = [k for k, v in self.languages.items() if v == Defaults.SOURCE_LANG][0]
        tr_key = [k for k, v in self.languages.items() if v == Defaults.TARGET_LANG][0]
        self.source_var = ctk.StringVar(value=auto_key) 
        self.target_var = ctk.StringVar(value=tr_key)

        self.typed_buffer = ""
        self._buffer_lock = threading.Lock()
        self.is_typing_replacement = False 
        self.last_text = ""
        self.last_trigger_time = 0
        self.kb_controller = Controller()
        self.translation_queue = queue.Queue()
        threading.Thread(target=self.process_queue, daemon=True).start()
        
        self.mouse_pressed_pos = None
        self.drag_threshold = Dimensions.DRAG_THRESHOLD
        
        self.setup_ui()
        self.start_mouse_listener()
        self.start_keyboard_listener()
        self.check_status()

    def setup_ui(self):
        self.main_frame = ctk.CTkFrame(self, fg_color=Colors.TRANSPARENT)
        self.main_frame.pack(fill="both", expand=True, padx=24, pady=24)

        header_row = ctk.CTkFrame(self.main_frame, fg_color=Colors.TRANSPARENT)
        header_row.pack(fill="x", pady=(0, 20))
        self.title_label = ctk.CTkLabel(
            header_row, text="Quick Trace", font=Fonts.TITLE, text_color=Colors.TEXT_PRIMARY
        )
        self.title_label.pack(side="left")
        self.badge = ctk.CTkLabel(
            header_row, text="PRO", font=Fonts.BADGE,
            fg_color=Colors.ACCENT_BLUE, text_color=Colors.TEXT_PRIMARY,
            corner_radius=Dimensions.BADGE_CORNER_RADIUS, width=Dimensions.BADGE_WIDTH,
        )
        self.badge.pack(side="left", padx=10)

        self.ui_lang_btn = ctk.CTkButton(
            header_row, text="TR 🇹🇷",
            width=Dimensions.UI_LANG_BTN_WIDTH, height=Dimensions.UI_LANG_BTN_HEIGHT,
            fg_color=Colors.BG_BUTTON, hover_color=Colors.BG_BUTTON_HOVER,
            font=Fonts.CAPTION_BOLD, command=self.toggle_ui_language,
        )
        self.ui_lang_btn.pack(side="right")

        self.status_frame = ctk.CTkFrame(
            self.main_frame, fg_color=Colors.BG_CARD,
            corner_radius=Dimensions.STATUS_CORNER_RADIUS, height=Dimensions.STATUS_HEIGHT,
        )
        self.status_frame.pack(fill="x", pady=(0, 16))
        self.status_dot = ctk.CTkLabel(
            self.status_frame, text="●", font=Fonts.STATUS_ICON, text_color=Colors.TEXT_MUTED
        )
        self.status_dot.pack(side="left", padx=(10, 5))
        self.status_label = ctk.CTkLabel(
            self.status_frame, text=self.s["checking_connection"], font=Fonts.CAPTION
        )
        self.status_label.pack(side="left")

        self.src_card = SettingCard(self.main_frame, title=self.s["source_lang"])
        self.src_card.pack(fill="x", pady=(0, 12))
        self.src_selector = LanguageSelector(
            self.src_card.content, self.languages,
            self.source_var, self.change_source, self.flag_images,
        )
        self.src_selector.pack(fill="x", padx=12, pady=10)

        self.tgt_card = SettingCard(self.main_frame, title=self.s["target_lang"])
        self.tgt_card.pack(fill="x", pady=(0, 12))
        self.tgt_selector = LanguageSelector(
            self.tgt_card.content, self.languages,
            self.target_var, self.change_target, self.flag_images,
        )
        self.tgt_selector.pack(fill="x", padx=12, pady=10)

        self.modes_card = SettingCard(self.main_frame, title=self.s["active_modes"])
        self.modes_card.pack(fill="x", pady=(0, 16))
        self.bubble_switch = ctk.CTkSwitch(
            self.modes_card.content, text=self.s["bubble_mode"],
            variable=self.bubble_mode, progress_color=Colors.ACCENT_BLUE,
        )
        self.bubble_switch.pack(pady=8, padx=16, anchor="w")
        self.input_switch = ctk.CTkSwitch(
            self.modes_card.content, text=self.s["input_mode"],
            variable=self.input_mode, progress_color=Colors.ACCENT_GREEN,
        )
        self.input_switch.pack(pady=(0, 8), padx=16, anchor="w")

        self.minimize_btn = ctk.CTkButton(
            self.main_frame, text=self.s["minimize_tray"], command=self.iconify,
            fg_color=Colors.TRANSPARENT, border_width=1,
            border_color=Colors.BORDER, hover_color=Colors.BG_CARD,
        )
        self.minimize_btn.pack(side="bottom", fill="x")

    def toggle_ui_language(self):
        if self.ui_lang == "tr":
            self.ui_lang = "en"
            self.ui_lang_btn.configure(text="EN 🇺🇸")
        else:
            self.ui_lang = "tr"
            self.ui_lang_btn.configure(text="TR 🇹🇷")
        self.s = STRINGS[self.ui_lang]
        self.update_ui_text()

    def update_ui_text(self):
        self.title(self.s["window_title"])
        is_online = utils.check_internet_connection()
        self.status_label.configure(
            text=self.s["system_online"] if is_online else self.s["system_offline"]
        )
        self.src_card.label.configure(text=self.s["source_lang"])
        self.tgt_card.label.configure(text=self.s["target_lang"])
        self.modes_card.label.configure(text=self.s["active_modes"])
        self.bubble_switch.configure(text=self.s["bubble_mode"])
        self.input_switch.configure(text=self.s["input_mode"])
        self.minimize_btn.configure(text=self.s["minimize_tray"])

        curr_src_code = self.languages.get(self.source_var.get(), Defaults.SOURCE_LANG)
        curr_tgt_code = self.languages.get(self.target_var.get(), Defaults.TARGET_LANG)
        self.languages = NAME_TO_CODE_TR if self.ui_lang == "tr" else NAME_TO_CODE_EN
        
        # Safe lookup for new names
        src_entry = [k for k, v in self.languages.items() if v == curr_src_code]
        tgt_entry = [k for k, v in self.languages.items() if v == curr_tgt_code]
        new_src_name = src_entry[0] if src_entry else list(self.languages.keys())[0]
        new_tgt_name = tgt_entry[0] if tgt_entry else list(self.languages.keys())[1]

        self.src_selector.refresh_list(self.languages)
        self.tgt_selector.refresh_list(self.languages)
        self.source_var.set(new_src_name)
        self.target_var.set(new_tgt_name)
        self.src_selector.main_btn.configure(
            text=f"  {new_src_name}", image=self.flag_images.get(curr_src_code)
        )
        self.tgt_selector.main_btn.configure(
            text=f"  {new_tgt_name}", image=self.flag_images.get(curr_tgt_code)
        )

    def check_status(self):
        if utils.check_internet_connection():
            self.status_dot.configure(text_color=Colors.ACCENT_GREEN)
            self.status_label.configure(text=self.s["system_online"])
        else:
            self.status_dot.configure(text_color=Colors.ACCENT_RED)
            self.status_label.configure(text=self.s["system_offline"])
        self.after(Timers.STATUS_CHECK_INTERVAL_MS, self.check_status)

    def change_source(self, choice):
        self.translator.set_source_language(self.languages[choice])

    def change_target(self, choice):
        self.translator.set_target_language(self.languages[choice])

    def process_queue(self):
        while True:
            try:
                text, is_enter = self.translation_queue.get()
                if text:
                    self.process_input_translation(text, is_enter)
                self.translation_queue.task_done()
            except (queue.Empty, ValueError):
                pass
    
    def start_mouse_listener(self):
        def on_click(x, y, button, pressed):
            if not self.is_running:
                return
            if pressed:
                with self._buffer_lock:
                    self.typed_buffer = ""
                self.after(0, self.hide_tooltip)
                if button == mouse.Button.left:
                    self.mouse_pressed_pos = (x, y)
            elif button == mouse.Button.left:
                if self.mouse_pressed_pos:
                    dist = math.hypot(x - self.mouse_pressed_pos[0], y - self.mouse_pressed_pos[1])
                    self.mouse_pressed_pos = None
                    if self.bubble_mode.get() and dist > self.drag_threshold:
                        threading.Timer(Timers.TRANSLATION_DELAY_S, self.perform_translation).start()
        self.mouse_listener = mouse.Listener(on_click=on_click)
        self.mouse_listener.start()

    def start_keyboard_listener(self):
        nav_keys = frozenset([
            keyboard.Key.left, keyboard.Key.right,
            keyboard.Key.up, keyboard.Key.down,
            keyboard.Key.home, keyboard.Key.end,
        ])

        def on_press(key):
            if not self.is_running or not self.input_mode.get():
                return
            if self.is_typing_replacement:
                return
            try:
                char = getattr(key, "char", None)
                if key in nav_keys:
                    with self._buffer_lock:
                        self.typed_buffer = ""
                    return

                if key == keyboard.Key.enter or (char and char in INPUT_TRIGGER_CHARS):
                    now = time.time()
                    if now - self.last_trigger_time < Timers.INPUT_DEBOUNCE_S:
                        return
                    self.last_trigger_time = now
                    with self._buffer_lock:
                        text_to_translate = self.typed_buffer
                        self.typed_buffer = ""
                    self.is_typing_replacement = True
                    self.translation_queue.put((text_to_translate, key == keyboard.Key.enter))
                elif key == keyboard.Key.backspace:
                    with self._buffer_lock:
                        if len(self.typed_buffer) > 0:
                            self.typed_buffer = self.typed_buffer[:-1]
                elif char:
                    with self._buffer_lock:
                        self.typed_buffer += char
                elif key == keyboard.Key.space:
                    with self._buffer_lock:
                        self.typed_buffer += " "
            except AttributeError:
                pass
        self.kb_listener = keyboard.Listener(on_press=on_press)
        self.kb_listener.start()

    def show_loading(self):
        try:
            x, y = utils.get_mouse_position()
            self.loading_indicator = LoadingIndicator(x, y)
        except (RuntimeError, OSError):
            pass

    def hide_loading(self):
        if self.loading_indicator:
            try:
                self.loading_indicator.destroy()
            except (tkinter.TclError, RuntimeError):
                pass
            self.loading_indicator = None

    def process_input_translation(self, text, is_enter):
        if not text or len(text) < Limits.MIN_INPUT_TEXT_LENGTH: 
            self.is_typing_replacement = False
            return
        self.after(0, self.show_loading)
        time.sleep(Timers.CLIPBOARD_WAIT_S)
        try:
            translation_result = {"text": None, "target": self.translator.target}

            def run_translation():
                try:
                    res, target = self.translator.translate(text) 
                    translation_result["text"] = res
                    translation_result["target"] = target
                except (ConnectionError, TimeoutError):
                    pass

            t_trans = threading.Thread(target=run_translation)
            t_trans.start()
            delete_count = len(text) + 1
            for _ in range(delete_count):
                self.kb_controller.tap(keyboard.Key.backspace)
                time.sleep(Timers.KEY_PRESS_DELAY_S)
            t_trans.join(timeout=Timers.TRANSLATION_TIMEOUT_S)
            translated = translation_result["text"]
            used_target = translation_result["target"]
            if not translated:
                final_text = text
            else:
                final_text = utils.fix_punctuation_input_mode(
                    utils.smart_capitalize(translated.strip()), used_target
                )

            old_clip = utils.get_clipboard_safe()
            pyperclip.copy(final_text)
            time.sleep(Timers.PASTE_DELAY_S)
            ctrl_key = keyboard.Key.cmd if sys.platform == PLATFORM_DARWIN else keyboard.Key.ctrl
            with self.kb_controller.pressed(ctrl_key):
                self.kb_controller.tap('v')
            
            time.sleep(Timers.POST_PASTE_DELAY_S)
            if is_enter:
                self.kb_controller.tap(keyboard.Key.enter)
            else:
                self.kb_controller.type(" ")
            time.sleep(Timers.FINAL_DELAY_S)
            if old_clip:
                pyperclip.copy(old_clip)
        except (OSError, RuntimeError, pyperclip.PyperclipException):
            pass
        finally:
            self.after(0, self.hide_loading)
            self.is_typing_replacement = False

    def perform_translation(self):
        raw_text = utils.get_selected_text()  
        if not raw_text or len(raw_text.strip()) < Limits.MIN_SELECTED_TEXT_LENGTH:
            return
        cleaned = utils.clean_text_for_translation(raw_text)
        if cleaned == self.last_text:
            return
        self.last_text = cleaned
        translated, _ = self.translator.translate(cleaned)
        if translated:
            self.after(0, lambda: self.show_tooltip(translated))

    def hide_tooltip(self):
        if self.active_tooltip:
            self.active_tooltip.safe_destroy()
            self.active_tooltip = None

    def show_tooltip(self, translated_text):
        self.hide_tooltip()
        try:
            x, y = utils.get_mouse_position()
            self.active_tooltip = Tooltip(translated_text, x, y)
        except (RuntimeError, OSError):
            pass

    def on_closing(self):
        self.is_running = False
        try:
            self.mouse_listener.stop()
            self.kb_listener.stop()
        except (AttributeError, RuntimeError):
            pass
        self.destroy()
        sys.exit()




if __name__ == "__main__":
    app = TranslationApp()
    app.protocol("WM_DELETE_WINDOW", app.on_closing)
    try:
        app.mainloop()
    except KeyboardInterrupt:
        app.on_closing()
