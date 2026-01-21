import pyperclip
import pyautogui
import time
import platform
import re
import socket

def check_internet_connection():
    """
    Checks if there is an internet connection by connecting to Google DNS.
    Fast timeout (1s).
    """
    try:
        socket.create_connection(("8.8.8.8", 53), timeout=1)
        return True
    except OSError:
        return False

def get_clipboard_safe():
    """
    Safely reads the clipboard content.
    Returns empty string if content is too large or not text.
    """
    try:
        text = pyperclip.paste()
        if text and len(text) > 100000:
            return "" 
        return text
    except Exception:
        return ""

def clean_text_for_translation(text):
    if not text: return ""
    text = text.replace('\n', ' ').replace('\r', '')
    text = re.sub(r'\s+', ' ', text)
    return text.strip()

def smart_capitalize(text):
    """Capitalize first letter while preserving the rest"""
    if not text: return ""
    return text[:1].upper() + text[1:]

def normalize_spacing(text):
    if not text: return ""
    normalized = re.sub(r'([.?!])(?=[A-Za-zığüşöçİĞÜŞÖÇ])', r'\1 ', text)
    return normalized

def split_run_on_sentences(text):
    if not text: return ""
    greeting_pattern = r'(?i)\b(hello|hi|hey|good morning|greetings)\s+(how|what|where|who|are)\b'
    text = re.sub(greeting_pattern, r'\1. \2', text)
    how_pattern = r'(?i)\b(how are you|how is it going)\s+(i|i\'m|im|we|good|fine)\b'
    text = re.sub(how_pattern, r'\1? \2', text)
    thx_pattern = r'(?i)\b(thanks|thank you)\s+(i|i\'m|im|we|it|but|and)\b'
    text = re.sub(thx_pattern, r'\1. \2', text)
    return text

def is_question(sentence, lang="en"):
    clean = sentence.strip().lower()
    if not clean: return False
    # If already ends with ?, trust it
    if clean.endswith("?"): return True
    
    words = clean.split(" ")
    if lang == "en":
        starters = ("what", "where", "when", "who", "why", "how", "which", "whose", "whom", "is", "are", "am", "was", "were", "do", "does", "did", "can", "could", "should", "would", "will", "shall", "may", "might", "must", "have", "has", "had")
        if words[0] in starters: return True
        # Check for mid-sentence questions
        for s in starters:
            if f", {s}" in clean: return True
    elif lang == "tr":
        q_words = ["neden", "niçin", "nasıl", "nasılsın", "ne", "nerede", "kim", "hangi", "kaç", "ne zaman", "kime", "kimden", "neyi", "neye", "mi acaba", "naber", "ne haber"]
        for word in words:
            if word.rstrip(".,!:") in q_words: return True
        suffix_pattern = r'(mi|mı|mu|mü|misin|mısın|musun|müsün|midir|mıdır|mudur|müdür|miyim|mıyım|muyum|müyüm|miyiz|mıyız|muyuz|müyüz)[\s\.\!]*$'
        if re.search(suffix_pattern, clean, re.IGNORECASE): return True
    return False

def fix_punctuation_input_mode(text, target_lang="en"):
    """Advanced punctuation fixer for Input Mode"""
    if not text: return ""
    
    # 1. Clean and normalize
    text = split_run_on_sentences(text)
    text = normalize_spacing(text)
    
    # 2. Split by sentence
    sentences = re.split(r'(?<=[.?!])\s+', text)
    fixed_sentences = []
    
    for sent in sentences:
        sent = sent.strip()
        if not sent: continue
        
        # Capitalize
        processed = sent[:1].upper() + sent[1:]
        
        # Add punctuation if missing
        if not processed.endswith((".", "!", "?", ":")):
            if is_question(processed, target_lang):
                processed += "?"
            else:
                processed += "."
        fixed_sentences.append(processed)
        
    return " ".join(fixed_sentences)

def get_selected_text():
    """Robust text selection capture using multiple attempts"""
    pyperclip.copy("") 
    time.sleep(0.1)
    
    if platform.system() == 'Darwin':
        pyautogui.hotkey('command', 'c')
    else:
        # More reliable Ctrl+C sequence
        pyautogui.keyDown('ctrl')
        time.sleep(0.05)
        pyautogui.press('c')
        time.sleep(0.05)
        pyautogui.keyUp('ctrl')
    
    # Retry loop for slow applications
    for _ in range(10):
        time.sleep(0.05)
        try:
            text = pyperclip.paste()
            if text and len(text.strip()) > 0:
                return text
        except: pass
    return ""

def get_mouse_position():
    return pyautogui.position()
