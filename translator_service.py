import os
import json
import time
from deep_translator import GoogleTranslator
from langdetect import detect, LangDetectException

class TranslationService:
    def __init__(self, source='auto', target='tr', history_file="translation_history.json"):
        self.source = source
        self.target = target  # Default target language
        self.history_file = history_file
        self.history = self._load_history()

    def _load_history(self):
        if os.path.exists(self.history_file):
            try:
                with open(self.history_file, 'r', encoding='utf-8') as f:
                    return json.load(f)
            except Exception:
                return []
        return []

    def _save_history_entry(self, original, translated, src, tgt):
        try:
            entry = {
                "timestamp": int(time.time()),
                "date": time.strftime("%Y-%m-%d %H:%M:%S"),
                "source_text": original,
                "translated_text": translated,
                "src_lang": src,
                "target_lang": tgt
            }
            self.history.insert(0, entry)
            if len(self.history) > 200:
                self.history = self.history[:200]
            with open(self.history_file, 'w', encoding='utf-8') as f:
                json.dump(self.history, f, ensure_ascii=False, indent=2)
        except Exception as e:
            pass

    def translate(self, text):
        """
        Translates the given text with smart auto-detection and records history:
        - Uses selected source (default 'auto').
        - Handles bidirectional TR <-> EN switching if source is auto and target is tr.
        Returns: (translated_text, used_target_lang)
        """
        if not text or not text.strip():
            return "", self.target
        
        try:
            # 1. Primary Translation
            translator = GoogleTranslator(source=self.source, target=self.target)
            result = translator.translate(text)
            final_target = self.target
            
            # 2. Smart Bidirectional Switching (only if source is 'auto')
            if self.source == 'auto' and result and result.lower() == text.lower():
                if self.target == 'tr':
                    translator_reverse = GoogleTranslator(source='tr', target='en')
                    result_reverse = translator_reverse.translate(text)
                    if result_reverse and result_reverse.lower() != text.lower():
                        result = result_reverse
                        final_target = 'en'
            
            self._save_history_entry(text, result, self.source, final_target)
            return result, final_target
            
        except Exception:
            return text, self.target 

    def get_history(self, limit=50):
        return self.history[:limit]

    def clear_history(self):
        self.history = []
        if os.path.exists(self.history_file):
            try:
                os.remove(self.history_file)
            except Exception:
                pass

    def set_target_language(self, lang_code):
        self.target = lang_code

    def set_source_language(self, lang_code):
        self.source = lang_code
