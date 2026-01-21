from deep_translator import GoogleTranslator
from langdetect import detect, LangDetectException

class TranslationService:
    def __init__(self, source='auto', target='tr'):
        self.source = source
        self.target = target  # Default target language

    def translate(self, text):
        """
        Translates the given text with smart auto-detection:
        - Uses selected source (default 'auto').
        - Handles bidirectional TR <-> EN switching if source is auto and target is tr.
        Returns: (translated_text, used_target_lang)
        """
        if not text or not text.strip():
            return "", self.target
        
        try:
            # 1. Primary Translation
            # Use specific source if selected, otherwise 'auto'
            translator = GoogleTranslator(source=self.source, target=self.target)
            result = translator.translate(text)
            
            # 2. Smart Bidirectional Switching (only if source is 'auto')
            if self.source == 'auto' and result and result.lower() == text.lower():
                # If target is TR and input was already TR, try TR -> EN
                if self.target == 'tr':
                    translator_reverse = GoogleTranslator(source='tr', target='en')
                    result_reverse = translator_reverse.translate(text)
                    
                    if result_reverse and result_reverse.lower() != text.lower():
                        return result_reverse, 'en'
            
            return result, self.target
            
        except Exception:
            return text, self.target 

    def set_target_language(self, lang_code):
        self.target = lang_code

    def set_source_language(self, lang_code):
        self.source = lang_code
