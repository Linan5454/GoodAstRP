from pathlib import Path
import json,hashlib
from PIL import Image
root=Path(r'C:\Users\Admin\Desktop\Скрипты\File for github\update_20260929')
records=json.loads((root/'reward_manifest.json').read_text(encoding='utf-8'))
missing=sorted({r['icon_file'] for r in records if not (root.parent/r['icon_file']).exists()})
ready=list(root.parent.glob('*_v2.png'))
for p in ready:
    with Image.open(p) as im:
        assert im.format=='PNG' and im.mode=='RGBA',p.name
        assert im.getchannel('A').getextrema()==(0,255),p.name
        im.load()
print('Valid transparent PNGs:',len(ready))
print('Missing artwork:',len(missing),', '.join(missing))

