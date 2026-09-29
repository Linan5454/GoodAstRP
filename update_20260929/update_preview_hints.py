from pathlib import Path
root=Path(r'C:\Users\Admin\Desktop\Скрипты\File for github\update_20260929')
p=root/'build_preview.py'
s=p.read_text(encoding='utf-8-sig')
s=s.replace("css='''", "hints={'arena_jump_3_v2':'В воздухе','arena_dash_v2':'В прыжке','arena_blink_v2':'В прыжке','arena_phase_v2':'Неуязвимость','arena_overdrive_v2':'+40% силы','arena_camo_v2':'Инвиз 15 сек','arena_mark_500_v2':'+50 HP вспышка'}\ncss='''",1)
s=s.replace('bottom:21px;width:100%','bottom:9px;width:100%').replace('height:103px;text-align:center','height:115px;text-align:center')
s=s.replace('.timer{display:none', '.hint{position:absolute;top:114px;left:0;width:126px;font-size:9px;color:#818796;white-space:nowrap}.timer{display:none')
s=s.replace('<div class="name">{name}</div></div>', '<div class="name">{name}</div><div class="hint">{hints[file]}</div></div>')
s=s.replace('loading="lazy" ','')
p.write_text(s,encoding='utf-8')
