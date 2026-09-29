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

local MatCache = {}
local function GetPerkMaterial(fileName)
    if not MatCache[fileName] then
        -- 1. Сначала локальные материалы сервера
        local localPath = "onyx_phone/icons/" .. fileName
        local localMat = Material(localPath, "smooth mips")
        if not localMat:IsError() then
            MatCache[fileName] = localMat
        else
            -- Запасной локальный путь
            local arenaMat = Material("arena/perks/" .. fileName, "smooth mips")
            if not arenaMat:IsError() then
                MatCache[fileName] = arenaMat
            else
                MatCache[fileName] = false
            end
        end
    end
    return MatCache[fileName]
end

local function DrawPerkIcon(templateId, x, y, size)
    local fileName = PERK_ICON_FILES[templateId] or "perk_cooldown_clock.png"
    local mat = GetPerkMaterial(fileName)

    if mat then
        surface.SetDrawColor(255, 255, 255, 240)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(x, y, size, size)
    elseif Onyx and Onyx.Phone and Onyx.Phone.DrawWebImage then
        local ghUrl = "https://github.com/Linan5454/GoodAstRP/blob/main/" .. fileName
        Onyx.Phone.DrawWebImage(ghUrl, x, y, size, size, color_white)
    else
        -- Запасной рендер часиков если иконка еще подгружается
        local defMat = GetPerkMaterial("perk_cooldown_clock.png")
        if defMat then
            surface.SetDrawColor(255, 200, 50, 240)
            surface.SetMaterial(defMat)
            surface.DrawTexturedRect(x, y, size, size)
        else
            draw.RoundedBox(4, x, y, size, size, Color(241, 196, 15, 180))
        end
    end
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
        local cardW = (onyx and onyx.ScaleWide) and onyx.ScaleWide(185) or 185
        local cardH = (onyx and onyx.ScaleTall) and onyx.ScaleTall(44) or 44
        local spacing = (onyx and onyx.ScaleWide) and onyx.ScaleWide(8) or 8
        local totalW = count * cardW + (count - 1) * spacing
        local startX = (scrW - totalW) / 2
        local startY = scrH - cardH - ((onyx and onyx.ScaleTall) and onyx.ScaleTall(18) or 18)

        for idx, perkId in ipairs(equippedActivePerks) do
            local cfg = Arena.ActivePerkConfig and Arena.ActivePerkConfig[perkId]
            if not cfg then continue end

            local x = startX + (idx - 1) * (cardW + spacing)
            local y = startY

            local cdRem = (Arena.Perks and Arena.Perks.GetCooldownRemaining) and Arena.Perks.GetCooldownRemaining(client, perkId) or 0
            local cdData = Arena.ClientPerkCooldowns and Arena.ClientPerkCooldowns[perkId]
            if cdData and cdData.endTime and cdData.endTime > CurTime() then
                cdRem = math.max(cdRem, cdData.endTime - CurTime())
            end
            local isOnCd = cdRem > 0
            local accentCol = cfg.color or Color(155, 89, 182)

            -- Фон карточки: Onyx #26272E, скругление строго 8px (без боковых полосок по правилу БОБР)
            draw.RoundedBox(8, x, y, cardW, cardH, Color(38, 39, 46, 240))
            -- Рамка карточки 1px #30323B
            surface.SetDrawColor(48, 50, 59, 255)
            surface.DrawOutlinedRect(x, y, cardW, cardH, 1)

            -- Иконка способности слева
            local iconSize = cardH - 12
            local iconX = x + 7
            local iconY = y + 6
            draw.RoundedBox(6, iconX, iconY, iconSize, iconSize, Color(24, 25, 30, 230))
            surface.SetDrawColor(accentCol.r, accentCol.g, accentCol.b, isOnCd and 50 or 120)
            surface.DrawOutlinedRect(iconX, iconY, iconSize, iconSize, 1)
            DrawPerkIcon(perkId, iconX + 2, iconY + 2, iconSize - 4)

            if isOnCd then
                -- Затемнение иконки при перезарядке
                draw.RoundedBox(6, iconX, iconY, iconSize, iconSize, Color(15, 15, 20, 160))
            end

            -- Текстовая область
            local textX = iconX + iconSize + 7

            -- Название способности (сверху)
            local nameCol = isOnCd and Color(160, 160, 165) or Color(240, 240, 245)
            draw.SimpleText(cfg.name, "Arena.Font.PromptName", textX, y + 12, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- Нижняя строка: если готова — капсула клавиши + подсказка, если на КД — таймер и прогрессбар
            if not isOnCd then
                -- Капсула (Pill Badge) для клавиш
                surface.SetFont("Arena.Font.PromptKey")
                local kw, kh = surface.GetTextSize(cfg.keys)
                local pillPadH = 6
                local pillPadV = 2
                local pillW = kw + pillPadH * 2
                local pillH = kh + pillPadV * 2
                local pillX = textX
                local pillY = y + 22

                draw.RoundedBox(4, pillX, pillY, pillW, pillH, Color(20, 21, 26, 240))
                surface.SetDrawColor(accentCol.r, accentCol.g, accentCol.b, 160)
                surface.DrawOutlinedRect(pillX, pillY, pillW, pillH, 1)

                draw.SimpleText(cfg.keys, "Arena.Font.PromptKey", pillX + pillW / 2, pillY + pillH / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                -- Подсказка действия рядом с клавишей
                if cfg.hint and cfg.hint ~= "" then
                    draw.SimpleText(cfg.hint, "Arena.Font.PromptHint", pillX + pillW + 6, pillY + pillH / 2, Color(160, 160, 165), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
            else
                -- В перезарядке: таймер
                local timeText = cdRem <= 3.0 and string.format("%.1fс", cdRem) or string.format("%dс", math.ceil(cdRem))
                draw.SimpleText("Перезарядка: " .. timeText, "Arena.Font.PromptKey", textX, y + 28, Color(235, 77, 75), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                -- Нижняя полоска отсчета
                local totalCd = (cdData and cdData.total) or 60
                local frac = math.Clamp(cdRem / totalCd, 0, 1)
                local barX = textX
                local barY = y + cardH - 6
                local barW = (x + cardW - 8) - barX
                draw.RoundedBox(2, barX, barY, barW, 2, Color(20, 20, 25, 220))
                draw.RoundedBox(2, barX, barY, barW * frac, 2, Color(235, 77, 75))
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
