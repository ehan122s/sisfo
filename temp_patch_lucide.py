from pathlib import Path
import re
path = Path(r'C:\Users\smkn1garut\AppData\Local\Pub\Cache\hosted\pub.dev\lucide_icons-0.257.0\lib\lucide_icons.dart')
text = path.read_text(encoding='utf-8')
text = text.replace('import "src/icon_data.dart";\n', '')
text = re.sub(r'const LucideIconData\((0x[0-9a-fA-F]+)\)', r"const IconData(\1, fontFamily: 'Lucide', fontPackage: 'lucide_icons')", text)
path.write_text(text, encoding='utf-8')
print('patched')
