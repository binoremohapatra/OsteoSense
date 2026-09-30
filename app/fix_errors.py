import os
import re

DART_DIR = r"d:\OsteoSense\app\lib\screens\shared"

def fix_errors():
    for filename in os.listdir(DART_DIR):
        if not filename.endswith('.dart'):
            continue
            
        filepath = os.path.join(DART_DIR, filename)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        original_content = content
        
        # Remove const before Text('...'.tr())
        # The regex looks for `const Text` or `const  Text` etc where it has `.tr()`
        content = re.sub(r'const\s+Text\(([^)]+)\.tr\(\)', r'Text(\1.tr()', content)
        
        # Also fix `const SnackBar(content: Text('...'.tr()))` -> `SnackBar(content: Text('...'.tr()))`
        # Because the SnackBar can no longer be const if it contains a non-const Text
        content = re.sub(r'const\s+SnackBar\(content:\s*Text\(([^)]+)\.tr\(\)', r'SnackBar(content: Text(\1.tr()', content)

        # Check if '.tr()' is in content but import is missing
        if '.tr()' in content or '.tr(' in content:
            if "import 'package:easy_localization/easy_localization.dart';" not in content:
                # Add import after the first import
                content = re.sub(r'(import [^;]+;)', r"\1\nimport 'package:easy_localization/easy_localization.dart';", content, count=1)
                
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed {filename}")

if __name__ == '__main__':
    fix_errors()
