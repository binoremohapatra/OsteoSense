import json
import time
from deep_translator import GoogleTranslator
from deep_translator.exceptions import TranslationNotFound, RequestError

def translate_json(file_path, target_lang):
    with open('en.json', 'r', encoding='utf-8') as f:
        data = json.load(f)

    translator = GoogleTranslator(source='en', target=target_lang)
    translated_data = {}
    
    keys = list(data.keys())
    values = list(data.values())
    
    # Batch translation to avoid rate limits (in chunks of 50)
    chunk_size = 20
    print(f"Starting translation for {target_lang} ({len(keys)} keys)...")
    
    translated_values = []
    
    for i in range(0, len(values), chunk_size):
        chunk = values[i:i + chunk_size]
        try:
            # Google Translate preserves placeholders like {name} sometimes, but to be safe:
            translated_chunk = translator.translate_batch(chunk)
            translated_values.extend(translated_chunk)
            print(f"Translated {min(i + chunk_size, len(values))}/{len(values)}")
            time.sleep(1) # Be nice to the API
        except Exception as e:
            print(f"Error at chunk {i}: {e}")
            # Fallback to individual translation for the chunk
            for v in chunk:
                try:
                    res = translator.translate(v)
                    translated_values.append(res if res else v)
                    time.sleep(0.5)
                except Exception as inner_e:
                    print(f"Failed to translate '{v}': {inner_e}")
                    translated_values.append(v)
    
    for k, v in zip(keys, translated_values):
        translated_data[k] = v

    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(translated_data, f, ensure_ascii=False, indent=2)
    
    print(f"Finished {file_path}!")

if __name__ == "__main__":
    translate_json('manipuri.json', 'mni-Mtei')
    translate_json('mizo.json', 'lus')
