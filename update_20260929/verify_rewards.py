from pathlib import Path
import re,json
root=Path(r'C:\Users\Admin\Desktop\Скрипты\File for github\update_20260929')
relative='cases_systemlasted2/lua/cases_system/sh_config.lua'
before=(root/'originals'/relative).read_text(encoding='utf-8-sig')
after=(root/'addons'/relative).read_text(encoding='utf-8-sig').split('-- Generated reward artwork.')[0].rstrip()
def without_icons(text):return re.sub(r'icon = "[^\"]+"','icon = "ARTWORK"',text).rstrip()
assert without_icons(before)==without_icons(after),'Non-artwork configuration changed'
print('Verified: all rewards, prices, chances and reward data preserved.')
manifest={str(p.relative_to(root/'originals')):__import__('hashlib').sha256(p.read_bytes()).hexdigest() for p in (root/'originals').glob('**/*.lua')}
(root/'original_hashes.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('Original hashes and backup copies saved:',len(manifest))
