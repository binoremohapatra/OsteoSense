import json
import time
from googletrans import Translator

TRANS_DIR = r"d:\OsteoSense\app\assets\translations"
LANGUAGES = ['as', 'bn', 'gu', 'hi', 'kn', 'ml', 'mr', 'or', 'pa', 'ta', 'te']

# Load English
with open(f"{TRANS_DIR}/en.json", 'r', encoding='utf-8-sig') as f:
    en = json.load(f)

translator = Translator()

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
    
    keys = list(missing.keys())
    texts = list(missing.values())
    
    # Translate one by one with googletrans
    for i in range(len(keys)):
        k = keys[i]
        t = texts[i]
        try:
            res = translator.translate(t, dest=lang)
            if res and res.text and res.text != t:
                data[k] = res.text
            time.sleep(0.5)
        except Exception as e:
            print(f"  Error for {lang} key {k}: {e}")
            time.sleep(2)
            
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"{lang}: done")

for lang in LANGUAGES:
    fix_lang(lang)

print("All done!")
