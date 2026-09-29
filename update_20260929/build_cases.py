from pathlib import Path
import re,json
root=Path(r'C:\Users\Admin\Desktop\Скрипты\File for github\update_20260929')
records=json.loads((root/'reward_manifest.json').read_text(encoding='utf-8'))
classes={'lockpick':'lockpick','grub_knuckle':'parkour','sandbox_knuckle':'parkour','keypad_cracker':'keypad','weapon_sh_keypadcracker_deploy':'keypad_pro','weapon_armorkit':'armor','weapon_medkit':'medkit','tfa_deagle':'deagle','tfa_dbarrel':'double_barrel','tfa_val':'as_val','tfa_m416':'m416','weapon_defibrillator':'defibrillator','swep_disguise_briefcase':'disguise','weapon_gov_badge':'gov_badge','tfa_cso_desperado':'desperado','tfa_cso_elvenranger':'elven_ranger','tfa_l4d2_kfkat':'katana','sim_fphys_vaz_2107':'vaz_2107','sim_fphys_hyu_solaris':'solaris','sim_fphys_vw_golf_gti14':'golf_gti','sim_fphys_toy_mark2':'mark_ii','sim_fphys_nis_sky_r34':'skyline_r34','sim_fphys_bmw_750li':'bmw_750li','sim_fphys_bmw_m5_comp_21':'bmw_m5','sim_fphys_delorean_dmc12_bttf':'delorean','sim_fphys_lam_sian':'sian'}
types={'darkrp_money':'cash','donate_currency':'donate','salary_bonus':'salary','topup_bonus':'topup','f4_discount_50':'shop_discount','style_prefix':'chat_prefix','style_physgun':'physgun','style_colored_nick':'colored_nick','style_neon_tab':'neon_tab','style_trail':'trail','style_killsound':'kill_sound','prop_limit_bonus':'props','door_autoclose':'door_autoclose','cardealer_discount_25':'car_discount'}
mapping={}
for r in records:
    t=r['type']
    if t in ('perm_weapon','rcd_vehicle'): slug=classes[r['class']]
    elif t=='unique_door_perk': slug=r['perk_id']
    elif t=='sam_rank': slug='rank_qmenu' if r['rank']=='Qmenu' else 'rank_project_team'
    elif t=='arena_perk': mapping[r['id']]='arena_camo_v2.png'; continue
    else: slug=types[t]
    mapping[r['id']]='case_'+slug+'_v2.png'
for r in records:r['icon_file']=mapping[r['id']]
(root/'reward_manifest.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
config=root/'addons/cases_systemlasted2/lua/cases_system/sh_config.lua'
s=config.read_text(encoding='utf-8-sig')
pat=r'(?m)(^\t{4}id = "([^\"]+)"[\s\S]*?\bicon = ")[^\"]+("[\s\S]*?)(?=\n\t{3}\},)'
s,n=re.subn(pat,lambda m:m[1]+'https://raw.githubusercontent.com/Linan5454/GoodAstRP/main/'+mapping[m[2]]+m[3],s)
assert n==len(records),(n,len(records))
s+='\n-- Generated reward artwork. Also resolves old inventory snapshots by reward_id.\nCS.GeneratedRewardIcons = {\n'+''.join('    ["%s"] = "%s",\n'%(k,v) for k,v in mapping.items())+'}\n\nfunction CS.GetRewardArtwork(reward)\n    if not istable(reward) then return nil end\n    local id = reward.reward_id or reward.id\n    local fileName = CS.GeneratedRewardIcons[id]\n    if fileName then return "https://raw.githubusercontent.com/Linan5454/GoodAstRP/main/" .. fileName end\n    return reward.icon\nend\n'
config.write_text(s,encoding='utf-8')
ui=root/'addons/cases_systemlasted2/lua/cases_system/client/cl_default_ui.lua'
s=ui.read_text(encoding='utf-8-sig')
needle="    if webCache[path] then return webCache[path].mat end\n"
insert='''    if webCache[path] then return webCache[path].mat end
    local fileName = path:match("/([^/]+_v2%.png)$")
    if fileName then
        local localPath = "cases_system/rewards/v2/" .. fileName
        if file.Exists("materials/" .. localPath, "GAME") then
            local mat = Material(localPath, "smooth mips")
            if not mat:IsError() then
                webCache[path] = { mat = mat }
                return mat
            end
        end
    end
'''
assert needle in s
s=s.replace(needle,insert,1)
s=s.replace('local iconUrl = item.icon','local iconUrl = CasesSystem.GetRewardArtwork(item)').replace('local iconUrl = it.icon or GetCaseIcon(caseDef)','local iconUrl = CasesSystem.GetRewardArtwork(it) or GetCaseIcon(caseDef)')
# Load final assets outside panel Paint callbacks.
needle='local function GetOwnedCount(caseID)'
prime='''-- Prime generated materials once, rather than creating them each frame.
timer.Simple(0, function()
    if not CasesSystem.GeneratedRewardIcons then return end
    for _, fileName in pairs(CasesSystem.GeneratedRewardIcons) do
        GetWebOrLocalMat("https://raw.githubusercontent.com/Linan5454/GoodAstRP/main/" .. fileName)
    end
end)

'''
assert needle in s
s=s.replace(needle,prime+needle,1)
ui.write_text(s,encoding='utf-8')
(root/'asset_files.json').write_text(json.dumps(sorted(set(mapping.values())),indent=2),encoding='utf-8')
print('Updated all',n,'rewards; unique case artwork:',len(set(mapping.values())))
