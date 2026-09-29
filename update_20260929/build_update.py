from pathlib import Path
import re,json
root=Path(r'C:\Users\Admin\Desktop\Скрипты\File for github\update_20260929')
hud=root/'addons/arena_system/lua/arena/vgui/cl_hud.lua'
s=hud.read_text(encoding='utf-8-sig')
active={'perk_double_jump':'arena_jump_2_v2.png','perk_triple_jump':'arena_jump_3_v2.png','perk_blink':'arena_blink_v2.png','perk_dash':'arena_dash_v2.png','perk_quick_step':'arena_quick_step_v2.png','perk_phase_step':'arena_phase_v2.png','perk_overdrive':'arena_overdrive_v2.png','perk_camo_invis':'arena_camo_v2.png','relic_mark_500':'arena_mark_500_v2.png'}
pos=s.index('local MatCache = {}')
end=s.index('-- ===========================================================================\n-- ГЛАВНАЯ ОТРИСОВКА',pos)
materials='\n'.join('PERK_ICON_FILES["%s"] = "%s"'%x for x in active.items())+'''

local MatCache, RequestedIcons = {}, {}
local ICON_BASE = "https://raw.githubusercontent.com/Linan5454/GoodAstRP/main/"
local function PreloadPerkMaterial(fileName)
    if MatCache[fileName] or RequestedIcons[fileName] then return end
    local paths = string.StartWith(fileName, "arena_")
        and {"arena/perks/v2/" .. fileName}
        or {"onyx_phone/icons/" .. fileName, "arena/perks/" .. fileName}
    for _, path in ipairs(paths) do
        local mat = Material(path, "smooth mips")
        if not mat:IsError() then MatCache[fileName] = mat return end
    end
    RequestedIcons[fileName] = true
    file.CreateDir("arena_perk_icons_v2")
    local dataPath = "arena_perk_icons_v2/" .. fileName
    local function LoadDownloaded()
        local mat = Material("../data/" .. dataPath, "smooth mips")
        if not mat:IsError() then MatCache[fileName] = mat return true end
    end
    if file.Exists(dataPath, "DATA") and LoadDownloaded() then return end
    http.Fetch(ICON_BASE .. fileName, function(body, _, _, code)
        if code == 200 and isstring(body) and body:sub(1, 8) == "\\137PNG\\r\\n\\26\\n" then
            file.Write(dataPath, body)
            LoadDownloaded()
        end
    end, function() end)
end
-- Materials and HTTP requests are prepared once, outside HUDPaint.
for _, fileName in pairs(PERK_ICON_FILES) do PreloadPerkMaterial(fileName) end
PreloadPerkMaterial("perk_cooldown_clock.png")
local function DrawPerkIcon(templateId, x, y, size, tint)
    local fileName = PERK_ICON_FILES[templateId] or "perk_cooldown_clock.png"
    local mat = MatCache[fileName]
    if not mat then return end
    surface.SetDrawColor(tint or color_white)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(x, y, size, size)
end

local diamond = {{x=0,y=0},{x=0,y=0},{x=0,y=0},{x=0,y=0}}
local function DrawPerkDiamond(cx, cy, radius, color)
    diamond[1].x, diamond[1].y = cx, cy - radius
    diamond[2].x, diamond[2].y = cx + radius, cy
    diamond[3].x, diamond[3].y = cx, cy + radius
    diamond[4].x, diamond[4].y = cx - radius, cy
    draw.NoTexture()
    surface.SetDrawColor(color)
    surface.DrawPoly(diamond)
end

'''
s=s[:pos]+materials+s[end:]
pos=s.index('    local count = #equippedActivePerks')
end=s.index('\nend)',pos)
s=s[:pos]+'''    local count = #equippedActivePerks
    if count > 0 then
        local scale = math.Clamp(scrH / 1080, 0.65, 2)
        local tileSize = math.Round(80 * scale)
        local cellW = math.Round(126 * scale)
        local radius = tileSize * 0.5
        local keyH = math.Round(24 * scale)
        local totalW = count * cellW
        local startX = (scrW - totalW) * 0.5
        local centerY = scrH - math.Round(85 * scale)
        local border = math.max(1, math.Round(scale))
        local primary = (onyx and onyx.hud and onyx.hud.GetColor) and onyx.hud:GetColor("primary") or Color(38, 39, 46, 245)
        local secondary = (onyx and onyx.hud and onyx.hud.GetColor) and onyx.hud:GetColor("textSecondary") or Color(170, 173, 184)
        for idx, perkId in ipairs(equippedActivePerks) do
            local cfg = Arena.ActivePerkConfig[perkId]
            local cx = startX + (idx - 0.5) * cellW
            local cdData = Arena.ClientPerkCooldowns[perkId]
            local remaining = cdData and math.max(0, cdData.endTime - now) or 0
            local isOnCd = remaining > 0
            local accent = cfg.color
            DrawPerkDiamond(cx, centerY, radius, ColorAlpha(accent, isOnCd and 90 or 190))
            DrawPerkDiamond(cx, centerY, radius - border, primary)
            DrawPerkDiamond(cx, centerY, radius - 5 * scale, Color(23, 24, 30, 245))
            local iconSize = math.Round(45 * scale)
            DrawPerkIcon(perkId, cx - iconSize * 0.5, centerY - iconSize * 0.5 - 5 * scale, iconSize,
                isOnCd and Color(130, 133, 147) or Color(245, 246, 250))
            if isOnCd then
                local text = remaining <= 3 and string.format("%.1fс", remaining) or string.format("%dс", math.ceil(remaining))
                draw.SimpleTextOutlined(text, "Arena.Font.PerkCdTime", cx, centerY + 14 * scale,
                    Color(245, 193, 98), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, border, Color(18, 19, 25))
            end
            -- The keycap overlaps the lower tip of the diamond; keys remain visible during cooldown.
            surface.SetFont("Arena.Font.PromptKey")
            local textW = surface.GetTextSize(cfg.keys)
            local keyW = math.max(keyH, textW + math.Round(18 * scale))
            local keyX, keyY = cx - keyW * 0.5, centerY + radius - 12 * scale
            draw.RoundedBox(math.Round(4 * scale), keyX - border, keyY - border, keyW + border * 2, keyH + border * 2, ColorAlpha(accent, 190))
            draw.RoundedBox(math.Round(3 * scale), keyX, keyY, keyW, keyH, Color(24, 25, 32, 255))
            draw.SimpleText(cfg.keys, "Arena.Font.PromptKey", cx, keyY + keyH * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            if isOnCd then
                local frac = math.Clamp(remaining / math.max(1, cdData.total or 60), 0, 1)
                surface.SetDrawColor(accent)
                surface.DrawRect(keyX + border, keyY + keyH - 2 * scale, (keyW - border * 2) * (1 - frac), math.max(1, scale))
            end
            draw.SimpleText(cfg.name, "Arena.Font.PromptHint", cx, keyY + keyH + 9 * scale, secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end'''+s[end:]
hud.write_text(s,encoding='utf-8')
cfg=root/'addons/cases_systemlasted2/lua/cases_system/sh_config.lua'
c=cfg.read_text(encoding='utf-8-sig')
blocks=re.findall(r'(?m)^\t{4}id = "([^\"]+)"([\s\S]*?)(?=\n\t{3}\},)',c)
records=[]
for rid,b in blocks:
    def field(k):
        m=re.search(r'\b'+k+r' = "([^\"]+)"',b)
        return m.group(1) if m else ''
    records.append({'id':rid,'name':field('name'),'type':field('type'),'class':field('class'),'perk_id':field('perk_id'),'rank':field('rank')})
(root/'reward_manifest.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
print('HUD updated; rewards:',len(records))
