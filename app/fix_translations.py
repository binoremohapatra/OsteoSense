import json
import time
from deep_translator import GoogleTranslator

TRANS_DIR = r"d:\OsteoSense\app\assets\translations"
LANGUAGES = ['as', 'bn', 'gu', 'hi', 'kn', 'ml', 'mr', 'or', 'pa', 'ta', 'te']

# Load English
with open(f"{TRANS_DIR}/en.json", 'r', encoding='utf-8-sig') as f:
    en = json.load(f)

def fix_lang(lang):
    path = f"{TRANS_DIR}/{lang}.json"
    with open(path, 'r', encoding='utf-8-sig') as f:
        data = json.load(f)
    
    # Find keys where value == English value (not translated)
    missing = {}
    for k, v in en.items():
        current = data.get(k, '')
        if current == v or current == '':  # Same as English = not translated
            if v.strip() and len(v) > 1:
                missing[k] = v
    
    if not missing:
        print(f"{lang}: all up to date")
        return
    
    print(f"{lang}: fixing {len(missing)} untranslated keys...")
    translator = GoogleTranslator(source='en', target=lang)
    
    keys = list(missing.keys())
    texts = list(missing.values())
    
    # Smaller chunks with bigger delay
    chunk_size = 30
    for i in range(0, len(keys), chunk_size):
        chunk_k = keys[i:i+chunk_size]
        chunk_t = texts[i:i+chunk_size]
        try:
            translated = translator.translate_batch(chunk_t)
            for k, t in zip(chunk_k, translated):
                if t and t != missing[k]:
                    data[k] = t
        except Exception as e:
            print(f"  Error for {lang} chunk {i}: {e}")
        time.sleep(3)  # Longer delay
    
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"{lang}: done")

for lang in LANGUAGES:
    fix_lang(lang)
    time.sleep(2)

print("All done!")
