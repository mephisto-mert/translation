"""
Uygulama genelinde kullanılan sabit değerler.
Magic string/number kullanımını engellemek için tüm sabitler burada tanımlanır.
"""

# =============================================================================
# RENK PALETİ (Slate Dark Tema)
# =============================================================================
class Colors:
    """Uygulama renk paleti - Tailwind Slate tonları."""
    BG_PRIMARY = "#0f172a"       # Ana arka plan (slate-900)
    BG_CARD = "#1e293b"          # Kart arka planı (slate-800)
    BG_BUTTON = "#334155"        # Buton arka planı (slate-700)
    BG_BUTTON_HOVER = "#475569"  # Buton hover (slate-600)
    
    TEXT_PRIMARY = "white"       # Ana metin rengi
    TEXT_SECONDARY = "#cbd5e1"   # İkincil metin (slate-300)
    TEXT_BODY = "#f1f5f9"        # Gövde metni (slate-100)
    TEXT_MUTED = "#94a3b8"       # Soluk metin (slate-400)
    
    ACCENT_BLUE = "#3b82f6"      # Vurgu mavisi (blue-500)
    ACCENT_GREEN = "#10b981"     # Vurgu yeşili (emerald-500)
    ACCENT_RED = "#ef4444"       # Hata kırmızısı (red-500)
    ACCENT_YELLOW = "#FACC15"    # Loading göstergesi (yellow-400)
    
    BORDER = "#334155"           # Kenarlık rengi (slate-700)
    TRANSPARENT = "transparent"  # Şeffaf arka plan


# =============================================================================
# FONT AYARLARI
# =============================================================================
class Fonts:
    """Uygulama font tanımları."""
    FAMILY_PRIMARY = "Segoe UI"
    FAMILY_ICON = "Arial"
    
    # (family, size, weight) şeklinde tuple'lar
    TITLE = (FAMILY_PRIMARY, 26, "bold")
    HEADING = (FAMILY_PRIMARY, 14)
    BODY = (FAMILY_PRIMARY, 13)
    CAPTION = (FAMILY_PRIMARY, 11)
    CAPTION_BOLD = (FAMILY_PRIMARY, 11, "bold")
    BADGE = (FAMILY_PRIMARY, 10, "bold")
    STATUS_ICON = (FAMILY_ICON, 14)


# =============================================================================
# PENCERE & BOYUTLAR
# =============================================================================
class Dimensions:
    """Pencere ve bileşen boyutları."""
    WINDOW_WIDTH = 450
    WINDOW_HEIGHT = 700
    WINDOW_GEOMETRY = f"{WINDOW_WIDTH}x{WINDOW_HEIGHT}"
    
    # Loading Indicator
    LOADING_SIZE = 24
    LOADING_DOT_SIZE = 16
    LOADING_DOT_RADIUS = 8
    LOADING_OFFSET = 20
    
    # Tooltip
    TOOLTIP_MIN_WIDTH = 400
    TOOLTIP_MAX_WIDTH = 700
    TOOLTIP_MAX_HEIGHT = 500
    TOOLTIP_CHAR_WIDTH = 10    # Karakter başına piksel
    TOOLTIP_CHARS_PER_LINE = 9  # Satır genişliği hesaplama katsayısı
    TOOLTIP_LINE_HEIGHT = 26
    TOOLTIP_PADDING = 60
    TOOLTIP_SCREEN_MARGIN = 20
    TOOLTIP_OFFSET = 15
    
    # Flag Image
    FLAG_WIDTH = 24
    FLAG_HEIGHT = 18
    FLAG_SIZE = (FLAG_WIDTH, FLAG_HEIGHT)
    
    # Button & Card
    BUTTON_HEIGHT = 32
    DROPDOWN_HEIGHT = 200
    CARD_CORNER_RADIUS = 12
    DROPDOWN_CORNER_RADIUS = 8
    TOOLTIP_CORNER_RADIUS = 14
    
    # Badge
    BADGE_WIDTH = 35
    BADGE_CORNER_RADIUS = 6
    
    # Status bar
    STATUS_HEIGHT = 30
    STATUS_CORNER_RADIUS = 8
    
    # UI Language Button
    UI_LANG_BTN_WIDTH = 60
    UI_LANG_BTN_HEIGHT = 24
    
    # Drag threshold (piksel)
    DRAG_THRESHOLD = 10


# =============================================================================
# ZAMANLAYICILAR (milisaniye veya saniye)
# =============================================================================
class Timers:
    """Uygulama zamanlayıcı sabitleri."""
    # Milisaniye (ms) — tkinter after() çağrıları için
    TOOLTIP_AUTO_CLOSE_MS = 15000
    STATUS_CHECK_INTERVAL_MS = 10000
    
    # Saniye (s) — time.sleep() ve timeout çağrıları için
    TRANSLATION_DELAY_S = 0.15
    INPUT_DEBOUNCE_S = 0.3
    CLIPBOARD_WAIT_S = 0.1
    KEY_PRESS_DELAY_S = 0.015
    PASTE_DELAY_S = 0.05
    POST_PASTE_DELAY_S = 0.05
    FINAL_DELAY_S = 0.1
    TRANSLATION_TIMEOUT_S = 3
    
    # Clipboard retry
    CLIPBOARD_RETRY_COUNT = 10
    CLIPBOARD_RETRY_DELAY_S = 0.05
    
    # Key sequence
    KEY_DOWN_DELAY_S = 0.05


# =============================================================================
# AĞ AYARLARI
# =============================================================================
class Network:
    """Ağ bağlantı sabitleri."""
    DNS_HOST = "8.8.8.8"
    DNS_PORT = 53
    CONNECTION_TIMEOUT_S = 1


# =============================================================================
# LİMİTLER
# =============================================================================
class Limits:
    """Uygulama limitleri."""
    CLIPBOARD_MAX_LENGTH = 100_000
    MIN_SELECTED_TEXT_LENGTH = 2
    MIN_INPUT_TEXT_LENGTH = 1
    TOOLTIP_ALPHA = 0.95
    LOADING_ALPHA = 0.9


# =============================================================================
# BAYRAK DOSYALARI
# =============================================================================
SUPPORTED_FLAG_CODES = [
    "auto", "tr", "en", "de", "fr", "es", "it", "ru", "ja", "zh-CN", "ar",
    "pt", "ko", "nl", "pl", "hi", "id", "uk", "el", "cs", "sv", "vi", "th",
]

FLAG_ASSETS_DIR = "assets/flags"


# =============================================================================
# VARSAYILAN DİL AYARLARI
# =============================================================================
class Defaults:
    """Varsayılan dil ve mod ayarları."""
    SOURCE_LANG = "auto"
    TARGET_LANG = "tr"
    UI_LANG = "tr"
    BUBBLE_MODE_ON = True
    INPUT_MODE_ON = False


# =============================================================================
# PLATFORM
# =============================================================================
PLATFORM_WINDOWS_PREFIX = "win"
PLATFORM_DARWIN = "darwin"


# =============================================================================
# TRİGGER KARAKTERLERİ
# =============================================================================
INPUT_TRIGGER_CHARS = (".", "!", "?")
