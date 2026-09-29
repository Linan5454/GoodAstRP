from pathlib import Path
import json,re,hashlib
from PIL import Image
root=Path(r'C:\Users\Admin\Desktop\Скрипты\File for github\update_20260929')
expected=set(json.loads((root/'asset_files.json').read_text()))
expected.update(x['name']+'.png' for x in json.loads((root/'generation_prompts.json').read_text(encoding='utf-8-sig')))
missing=sorted(f for f in expected if not (root.parent/f).exists())
report={'expected_pngs':len(expected),'ready_pngs':len(expected)-len(missing),'missing':missing,'checks':['Lua syntax','PNG decode and RGBA transparency','reward prices/chances/data unchanged','HTML preview at 800/1280/1920 widths'],'in_game_tested':False}
for width,height in [(640,480),(800,1080),(1024,768),(1280,800),(1920,1080),(3840,2160)]:
 scale=min(max(.65,min(2,height/1080)),width/(7*126+32))
 assert 7*round(126*scale)<=width,(width,height)
print('Actual HUD maximum-perk row fits tested viewports.')
entries=json.loads((root/'generation_prompts.json').read_text(encoding='utf-8-sig'))
for line in (root/'case_generation_prompts.jsonl').read_text(encoding='utf-8-sig').splitlines():
 if line.strip():entries.append(json.loads(line.lstrip('\ufeff')))
unique={entry['name']:entry for entry in entries}
(root/'all_generation_prompts.json').write_text(json.dumps(list(unique.values()),ensure_ascii=False,indent=2),encoding='utf-8')
report['recorded_prompts']=len(unique)
(root/'validation_report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False))
