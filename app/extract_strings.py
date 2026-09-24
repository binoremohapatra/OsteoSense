import os
import re
import json

DART_DIR = r"d:\OsteoSense\app\lib\screens\shared"
EN_JSON_PATH = r"d:\OsteoSense\app\assets\translations\en.json"

text_regex = re.compile(r"Text\(\s*'([^'\$]+)'\s*\)")
title_regex = re.compile(r"title:\s*'([^'\$]+)'")

def generate_key(text):
    clean = re.sub(r'[^a-zA-Z0-9 ]', '', text.strip().lower())
    words = clean.split()
    if not words:
        return "unknown_key"
    key = "_".join(words[:5])
    return key

def process_files():
    with open(EN_JSON_PATH, 'r', encoding='utf-8') as f:
        en_data = json.load(f)
    
    modified_json = False
    
    for filename in os.listdir(DART_DIR):
        if not filename.endswith('.dart'):
            continue
            
        filepath = os.path.join(DART_DIR, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        original_content = content
        
        # Find all Text('...')
        for match in text_regex.finditer(original_content):
            original_text = match.group(1)
            # Skip if already looks like a translation key
            if re.match(r'^[a-z_]+$', original_text) or not original_text.strip():
                continue
            
            key = generate_key(original_text)
            if key not in en_data:
                en_data[key] = original_text
                modified_json = True
                
            content = content.replace(f"Text('{original_text}')", f"Text('{key}'.tr())")
            
        # Find all title: '...'
        for match in title_regex.finditer(original_content):
            original_text = match.group(1)
            if re.match(r'^[a-z_]+$', original_text) or not original_text.strip():
                continue
                
            key = generate_key(original_text)
            if key not in en_data:
                en_data[key] = original_text
                modified_json = True
                
            content = content.replace(f"title: '{original_text}'", f"title: '{key}'.tr()")
            
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Updated {filename}")
            
    if modified_json:
        with open(EN_JSON_PATH, 'w', encoding='utf-8') as f:
            json.dump(en_data, f, indent=2, ensure_ascii=False)
        print("Updated en.json")

if __name__ == '__main__':
    process_files()
