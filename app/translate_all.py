import os
import json
import time
from deep_translator import GoogleTranslator

LANGUAGES = ['as', 'bn', 'gu', 'hi', 'kn', 'ml', 'mr', 'or', 'pa', 'ta', 'te']
TRANS_DIR = r"d:\OsteoSense\app\assets\translations"

def run_translation():
    # Load en.json
    en_path = os.path.join(TRANS_DIR, 'en.json')
    with open(en_path, 'r', encoding='utf-8-sig') as f:
        en_data = json.load(f)
        
    for lang in LANGUAGES:
        lang_path = os.path.join(TRANS_DIR, f"{lang}.json")
        if os.path.exists(lang_path):
            with open(lang_path, 'r', encoding='utf-8-sig') as f:
                try:
                    lang_data = json.load(f)
                except Exception:
                    lang_data = {}
        else:
            lang_data = {}
            
        keys_to_translate = []
        texts_to_translate = []
        for key, value in en_data.items():
            if key not in lang_data or lang_data[key] == value:
                # If missing or identical to English (fallback happened)
                if value.strip() and len(value) > 1:
                    keys_to_translate.append(key)
                    texts_to_translate.append(value)
                else:
                    lang_data[key] = value
                
        if not keys_to_translate:
            print(f"{lang}.json is up to date.")
            continue
            
        print(f"Translating {len(keys_to_translate)} keys for {lang}...")
        
        translator = GoogleTranslator(source='en', target=lang)
        
        # Process in smaller chunks to avoid rate limiting
        chunk_size = 50
        for i in range(0, len(texts_to_translate), chunk_size):
            chunk_keys = keys_to_translate[i:i+chunk_size]
            chunk_texts = texts_to_translate[i:i+chunk_size]
            
            try:
                translated_texts = translator.translate_batch(chunk_texts)
                for k, t_text in zip(chunk_keys, translated_texts):
                    lang_data[k] = t_text if t_text else en_data[k]
            except Exception as e:
                print(f"Error in batch translation to {lang}: {e}")
                for k in chunk_keys:
                    lang_data[k] = en_data[k] # fallback
            time.sleep(2) # wait between chunks
            
        # Save updated json
        with open(lang_path, 'w', encoding='utf-8-sig') as f:
            json.dump(lang_data, f, indent=2, ensure_ascii=False)
            
        print(f"Updated {lang}.json")

if __name__ == '__main__':
    run_translation()
