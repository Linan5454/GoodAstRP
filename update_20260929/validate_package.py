from pathlib import Path
import re,json
from luaparser import ast
root=Path(r'C:\Users\Admin\Desktop\Скрипты\File for github\update_20260929')
for path in root.glob('addons/**/*.lua'):
    text=path.read_text(encoding='utf-8-sig')
    # GLua continue is a statement extension; replace for standard Lua syntax validation only.
    text=re.sub(r'\bcontinue\b','break',text)
    ast.parse(text)
    print('Lua syntax OK:',path.relative_to(root))
for addon,subdir,files in [
('arena_system','arena/perks/v2',['arena_jump_2_v2.png','arena_jump_3_v2.png','arena_blink_v2.png','arena_dash_v2.png','arena_quick_step_v2.png','arena_phase_v2.png','arena_overdrive_v2.png','arena_camo_v2.png','arena_mark_500_v2.png']),
('cases_systemlasted2','cases_system/rewards/v2',json.loads((root/'asset_files.json').read_text()))]:
    p=root/'addons'/addon/'lua/autorun/server'/('sv_'+addon+'_artwork_v2.lua')
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text('-- Generated UI artwork for client downloads.\n'+''.join('resource.AddFile("materials/'+subdir+'/'+f+'")\n' for f in files),encoding='utf-8')
print('Resource download lists written.')
