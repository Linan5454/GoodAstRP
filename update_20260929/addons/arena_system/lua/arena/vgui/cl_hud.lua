--[[
    ===========================================================================
    ARENA SYSTEM - MATCH HUD & PERK COOLDOWN INTERFACE (ONYX STYLE)
    Файл: lua/arena/vgui/cl_hud.lua
    ===========================================================================
]]

if not CLIENT then return end

Arena = Arena or {}
Arena.HUD = Arena.HUD or {}
Arena.ClientPerkCooldowns = Arena.ClientPerkCooldowns or {}

-- ===========================================================================
-- ШРИФТЫ COMFORTAA (ВЕС 700 / 500 СОГЛАСНО ПРАВИЛУ БОБР)
-- ===========================================================================

local function CreateHUDFonts()
    local scale = math.max(0.75, ScrH() / 900)
    surface.CreateFont("Arena.Font.PerkCdTime", {
        font = "Comfortaa",
        size = math.Round(14 * scale),
        weight = 700,
        antialias = true,
        extended = true,
    })

    surface.CreateFont("Arena.Font.PerkCdTitle", {
        font = "Comfortaa",
        size = math.Round(11 * scale),
        weight = 700,
        antialias = true,
        extended = true,
    })

    surface.CreateFont("Arena.Font.PromptName", {
        font = "Comfortaa",
        size = math.Round(12 * scale),
        weight = 700,
        antialias = true,
        extended = true,
    })

    surface.CreateFont("Arena.Font.PromptKey", {
        font = "Comfortaa",
        size = math.Round(11 * scale),
        weight = 700,
        antialias = true,
        extended = true,
    })

    surface.CreateFont("Arena.Font.PromptHint", {
        font = "Comfortaa",
        size = math.Round(10 * scale),
        weight = 500,
        antialias = true,
        extended = true,
    })
end
CreateHUDFonts()
hook.Add("OnScreenSizeChanged", "Arena.HUD.RecreateFonts", CreateHUDFonts)

Arena.ActivePerkConfig = {
    ["perk_triple_jump"] = {
        name = "Тройной прыжок",
        keys = "ПРОБЕЛ x3",
        hint = "В воздухе",
        color = Color(168, 85, 247),
    },
    ["perk_double_jump"] = {
        name = "Двойной прыжок",
        keys = "ПРОБЕЛ x2",
        hint = "В воздухе",
        color = Color(59, 130, 246),
    },
    ["perk_blink"] = {
        name = "Блинк",
        keys = "R",
        hint = "В прыжке",
        color = Color(245, 158, 11),
    },
    ["perk_dash"] = {
        name = "Воздушный рывок",
        keys = "SHIFT",
        hint = "В прыжке",
        color = Color(249, 115, 22),
    },
    ["perk_quick_step"] = {
        name = "Быстрый рывок",
        keys = "SHIFT",
        hint = "В прыжке",
        color = Color(16, 185, 129),
    },
    ["perk_phase_step"] = {
        name = "Фазовый сдвиг",
        keys = "ALT",
        hint = "Неуязвимость",
        color = Color(6, 182, 212),
    },
    ["perk_overdrive"] = {
        name = "Овердрайв",
        keys = "E + R",
        hint = "+40% силы",
        color = Color(239, 68, 68),
    },
    ["perk_camo_invis"] = {
        name = "Маскировка",
        keys = "E + ALT",
        hint = "Инвиз 15 сек",
        color = Color(139, 92, 246),
    },
    ["relic_mark_500"] = {
        name = "Клеймо 500-го",
        keys = "E + ПРОБЕЛ",
        hint = "+50 HP вспышка",
        color = Color(255, 215, 0),
    },
}

hook.Add("InitPostEntity", "Arena.HUD.RequestSync", function()
    timer.Simple(1, function()
        net.Start("Arena.RequestSyncInventory")
        net.SendToServer()
    end)
end)

-- ===========================================================================
-- УВЕДОМЛЕНИЯ АРЕНЫ
-- ===========================================================================

net.Receive('Arena.Notify', function()
    local text = net.ReadString()
    local nType = net.ReadUInt(4)

    local gType = NOTIFY_GENERIC
    if nType == 2 then
        gType = NOTIFY_HINT
    elseif nType == 3 then
        gType = NOTIFY_ERROR
    end

    notification.AddLegacy(text, gType, 4)
    surface.PlaySound("buttons/lightswitch2.wav")
end)

-- ===========================================================================
-- СИНХРОНИЗАЦИЯ КУЛДАУНОВ ПЕРКОВ С СЕРВЕРА
-- ===========================================================================

net.Receive("Arena.Perks.SyncCooldown", function()
    local templateId = net.ReadString()
    local endTime = net.ReadFloat()
    local duration = net.ReadUInt(16)
    Arena.ClientPerkCooldowns[templateId] = {
        endTime = endTime,
        total = (duration and duration > 0) and duration or 60
    }
end)

-- ===========================================================================
-- ИКОНКИ ПЕРКОВ (GITHUB URL + ЛОКАЛЬНЫЙ РЕПОЗИТОРИЙ)
-- ===========================================================================

local PERK_ICON_FILES = {
    perk_blink           = "perk_blink.png",
    perk_double_jump     = "perk_jump.png",
    perk_triple_jump     = "perk_jump.png",
    perk_dash            = "perk_dash.png",
    perk_quick_step      = "perk_dash.png",
    perk_vampirism       = "perk_vampirism.png",
    perk_berserk         = "perk_berserk.png",
    perk_fortify         = "perk_shield.png",
    perk_armor_plating   = "perk_shield.png",
    perk_phoenix         = "perk_phoenix.png",
    perk_overdrive       = "perk_overdrive.png",
    perk_second_wind     = "perk_wind.png",
    perk_crit_strike     = "perk_crit.png",
    perk_regen_hp        = "perk_regen.png",
    perk_minor_regen     = "perk_regen.png",
    perk_nano_armor      = "perk_shield.png",
    perk_phase_step      = "perk_phase.png",
    perk_hunter_mark     = "perk_hunter.png",
    perk_absolute_hunter = "perk_hunter.png",
    perk_executioner     = "perk_executioner.png",
    perk_adrenaline      = "perk_adrenaline.png",
    perk_bloodlust       = "perk_bloodlust.png",
    perk_hp_5            = "perk_regen.png",
    perk_speed_3         = "perk_dash.png",
    perk_scavenger       = "perk_hunter.png",
    token_boss_scrake    = "perk_berserk.png",
    token_boss_fleshpound= "perk_shield.png",
    token_boss_patriarch = "perk_phase.png",
    relic_mark_500       = "perk_hunter.png",
    relic_aegis_immortal = "perk_shield.png",
    relic_eye_of_abyss   = "perk_phase.png",
}

PERK_ICON_FILES["perk_double_jump"] = "arena_jump_2_v2.png"
PERK_ICON_FILES["perk_triple_jump"] = "arena_jump_3_v2.png"
PERK_ICON_FILES["perk_blink"] = "arena_blink_v2.png"
PERK_ICON_FILES["perk_dash"] = "arena_dash_v2.png"
PERK_ICON_FILES["perk_quick_step"] = "arena_quick_step_v2.png"
PERK_ICON_FILES["perk_phase_step"] = "arena_phase_v2.png"
PERK_ICON_FILES["perk_overdrive"] = "arena_overdrive_v2.png"
PERK_ICON_FILES["perk_camo_invis"] = "arena_camo_v2.png"
PERK_ICON_FILES["relic_mark_500"] = "arena_mark_500_v2.png"

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
        if code == 200 and isstring(body) and body:sub(1, 8) == "\137PNG\r\n\26\n" then
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

-- ===========================================================================
-- ГЛАВНАЯ ОТРИСОВКА HUD (PVP ДУЭЛИ + ИНТЕРФЕЙС КУЛДАУНОВ ПЕРКОВ)
-- ===========================================================================

hook.Add('HUDPaint', 'Arena.HUD.Draw', function()
    local client = LocalPlayer()
    if not IsValid(client) or not client:Alive() then return end

    local scrW, scrH = ScrW(), ScrH()

    -- 1. Отрисовка таймера и счета PvP Дуэли
    if Arena.PvP and Arena.PvP.ActiveMatch then
        local match = Arena.PvP.ActiveMatch
        if match.state == 'ACTIVE' then
            local hudW, hudH = 380, 60
            local hudX = scrW / 2 - hudW / 2
            local hudY = 16

            draw.RoundedBox(8, hudX, hudY, hudW, hudH, Arena.Theme.Colors.Primary)
            draw.RoundedBoxEx(8, hudX, hudY, hudW, 3, Arena.Theme.Colors.Accent, true, true, false, false)

            local timeRem = math.max(0, math.floor((match.matchEnd or CurTime()) - CurTime()))
            draw.SimpleText(Arena.Util.FormatTime(timeRem), 'Arena.Font.20B', scrW / 2, hudY + 22, Arena.Theme.Colors.AccentGold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText('1V1 DUEL', 'Arena.Font.10R', scrW / 2, hudY + 44, Arena.Theme.Colors.TextDarkGray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            draw.SimpleText(client:Nick(), 'Arena.Font.14B', hudX + 16, hudY + 18, Arena.Theme.Colors.TextWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            local myHpFrac = math.Clamp(client:Health() / math.max(1, client:GetMaxHealth()), 0, 1)
            Arena.Theme.DrawProgressBar(hudX + 16, hudY + 34, 120, 6, myHpFrac, Arena.Theme.Colors.Positive)
            draw.SimpleText(string.format('%d HP', math.max(0, client:Health())), 'Arena.Font.12B', hudX + 16, hudY + 50, Arena.Theme.Colors.TextLightGray, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            draw.SimpleText(match.oppNick or 'Соперник', 'Arena.Font.14B', hudX + hudW - 16, hudY + 18, Arena.Theme.Colors.Negative, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            draw.SimpleText(string.format('%d MMR', match.oppRating or 1000), 'Arena.Font.12B', hudX + hudW - 16, hudY + 50, Arena.Theme.Colors.TextDarkGray, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    -- 2. ИНТЕРФЕЙС КУЛДАУНОВ ПАССИВНЫХ ПЕРКОВ (СПРАВА, ТОЛЬКО ДЛЯ ПАССИВНЫХ!)
    -- Активные способности здесь НЕ отображаются — они имеют свой индикатор в нижней панели!
    local activeCooldowns = {}
    local now = CurTime()

    for templateId, data in pairs(Arena.ClientPerkCooldowns) do
        local rem = data.endTime - now
        if rem > 0 then
            local isActive = (Arena.ActivePerkConfig and Arena.ActivePerkConfig[templateId]) or (Arena.ACTIVE_PERKS and Arena.ACTIVE_PERKS[templateId])
            local isPassive = (Arena.PASSIVE_COOLDOWN_PERKS and Arena.PASSIVE_COOLDOWN_PERKS[templateId])
            if not isActive and isPassive then
                table.insert(activeCooldowns, {
                    id = templateId,
                    rem = rem,
                    total = data.total or 60,
                    frac = math.Clamp(rem / (data.total or 60), 0, 1)
                })
            end
        else
            Arena.ClientPerkCooldowns[templateId] = nil
        end
    end

    -- Отрисовка пассивных карточек справа (только когда есть активные перезарядки пассивок)
    if #activeCooldowns > 0 then
        table.sort(activeCooldowns, function(a, b) return a.rem > b.rem end)

        local cardW = (onyx and onyx.ScaleWide) and onyx.ScaleWide(195) or 195
        local cardH = (onyx and onyx.ScaleTall) and onyx.ScaleTall(38) or 38
        local space = (onyx and onyx.ScaleTall) and onyx.ScaleTall(6) or 6
        local startX = scrW - cardW - 20
        local startY = scrH - 180 - (#activeCooldowns * (cardH + space))

        for idx, cd in ipairs(activeCooldowns) do
            local y = startY + (idx - 1) * (cardH + space)
            local tmpl = Arena.Items and Arena.Items.GetTemplate and Arena.Items.GetTemplate(cd.id)
            local perkName = tmpl and tmpl.name or cd.id

            -- Основное тело карточки Onyx (#26272E, скругление строго 8px, без боковых полосок)
            draw.RoundedBox(8, startX, y, cardW, cardH, Color(38, 39, 46, 240))
            -- Рамка карточки 1px (#30323B)
            surface.SetDrawColor(48, 50, 59, 255)
            surface.DrawOutlinedRect(startX, y, cardW, cardH, 1)

            -- Иконка перка слева с подложкой
            local iconSize = cardH - 12
            local iconX = startX + 6
            local iconY = y + 6
            draw.RoundedBox(6, iconX, iconY, iconSize, iconSize, Color(24, 25, 30, 220))
            DrawPerkIcon(cd.id, iconX + 2, iconY + 2, iconSize - 4)

            -- Название перка
            local textX = iconX + iconSize + 8
            draw.SimpleText(perkName, "Arena.Font.PerkCdTitle", textX, y + 10, Color(220, 220, 225), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- Таймер отсчета кулдауна (крупно справа)
            local timeText
            local timeCol
            if cd.rem <= 3.0 then
                timeText = string.format("%.1fs", cd.rem)
                timeCol = Color(241, 196, 15) -- Золотисто-желтый при скором завершении
            else
                timeText = string.format("%ds", math.ceil(cd.rem))
                timeCol = Color(235, 77, 75) -- Красный цвет перезарядки
            end

            draw.SimpleText(timeText, "Arena.Font.PerkCdTime", startX + cardW - 10, y + 15, timeCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

            -- Нижний индикатор прогресса КД
            local barX = textX
            local barY = y + cardH - 8
            local barW = (startX + cardW - 10) - barX
            local barH = 3
            draw.RoundedBox(2, barX, barY, barW, barH, Color(18, 19, 24, 200))
            draw.RoundedBox(2, barX, barY, barW * cd.frac, barH, timeCol)
        end
    end

    -- ===========================================================================
    -- 3. НИЖНЯЯ ПАНЕЛЬ АКТИВНЫХ СПОСОБНОСТЕЙ И КЛАВИШ (BOTTOM CENTER PROMPT)
    -- Отображается ТОЛЬКО тогда, когда соответствующий перк экипирован!
    -- ===========================================================================
    local equippedActivePerks = {}

    local function HasEquipped(perkId)
        return Arena.Perks and Arena.Perks.HasPerk and Arena.Perks.HasPerk(client, perkId)
    end

    -- Прыжки: если экипирован Тройной прыжок, показываем только его (приоритет над Двойным)
    if HasEquipped("perk_triple_jump") then
        table.insert(equippedActivePerks, "perk_triple_jump")
    elseif HasEquipped("perk_double_jump") then
        table.insert(equippedActivePerks, "perk_double_jump")
    end

    -- Рывки: Dash имеет приоритет над Quick Step
    if HasEquipped("perk_dash") then
        table.insert(equippedActivePerks, "perk_dash")
    elseif HasEquipped("perk_quick_step") then
        table.insert(equippedActivePerks, "perk_quick_step")
    end

    if HasEquipped("perk_blink") then
        table.insert(equippedActivePerks, "perk_blink")
    end

    if HasEquipped("perk_phase_step") then
        table.insert(equippedActivePerks, "perk_phase_step")
    end

    if HasEquipped("perk_overdrive") then
        table.insert(equippedActivePerks, "perk_overdrive")
    end

    if HasEquipped("perk_camo_invis") then
        table.insert(equippedActivePerks, "perk_camo_invis")
    end

    if HasEquipped("relic_mark_500") then
        table.insert(equippedActivePerks, "relic_mark_500")
    end

    local count = #equippedActivePerks
    if count > 0 then
        local scale = math.min(math.Clamp(scrH / 1080, 0.65, 2), scrW / (count * 126 + 32))
        local tileSize = math.Round(80 * scale)
        local cellW = math.Round(126 * scale)
        local radius = tileSize * 0.5
        local keyH = math.Round(24 * scale)
        local totalW = count * cellW
        local startX = (scrW - totalW) * 0.5
        local centerY = scrH - math.Round(90 * scale)
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
            if cfg.hint and cfg.hint ~= "" then
                draw.SimpleText(cfg.hint, "Arena.Font.PromptHint", cx, keyY + keyH + 22 * scale, ColorAlpha(secondary, 170), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end
end)


-- ===========================================================================
-- ЭФФЕКТ СВЯЩЕННОЙ РЕЛИКВИИ: ИСТИННОЕ ЗРЕНИЕ ОКА БЕЗДНЫ (HALO СИЛУЭТЫ)
-- ===========================================================================

hook.Add("PreDrawHalos", "Arena.Perks.AbyssVisionHalos", function()
    local client = LocalPlayer()
    if not IsValid(client) or not client:Alive() then return end
    local untilTime = client:GetNW2Float("ArenaAbyssVisionUntil", 0)
    if untilTime <= CurTime() then return end

    local targets = {}
    local myPos = client:GetPos()
    for _, ent in ipairs(ents.FindInSphere(myPos, 1400)) do
        if IsValid(ent) and ent ~= client and (ent:IsNPC() or (ent:IsPlayer() and ent:Alive())) then
            table.insert(targets, ent)
        end
    end
    if #targets > 0 then
        halo.Add(targets, Color(155, 89, 182, 220), 2, 2, 1, true, true)
    end
end)


