from pathlib import Path
root=Path(r'C:\Users\Admin\Desktop\Скрипты\File for github\update_20260929')
for p in (root/'addons').glob('**/*.lua'):
 text=p.read_text(encoding='utf-8-sig')
 p.write_text(text,encoding='utf-8')
print('All Lua files saved in UTF-8 without BOM.')
