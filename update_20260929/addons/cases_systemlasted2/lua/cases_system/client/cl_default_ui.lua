--[[=========================================================================

    CASES SYSTEM x ONYX F4 UI - 100% Authentic Onyx F4 Design Clone for Cases
    Built to replicate the exact Onyx F4 layout, 2-column grid, sliding preview,
    and visual effects.

    Tabs:
    1. КЕЙСЫ (2-Column Grid, Live Search, Slide-in Case Preview Panel with Buy/Open & Drop Chances)
    2. ИНВЕНТАРЬ (Won items inventory with Activate / Sell / Sell All actions, fixed layouts & IDs)
    3. ПОПОЛНЕНИЕ (IGS Balance top-up with presets & gateway redirect)
    4. НАСТРОЙКИ (Sound volume, Fast open, Notification toggles)
    5. УПРАВЛЕНИЕ (Admin live JSON Case Editor)
    - Animated Roulette with Easing & Sound Ticks
    - Win Celebration Modal with Claim / Sell actions

=========================================================================]]

if SERVER then return end

local function doCasesOnyxInit()
    if not onyx or not onyx.gui or not onyx.gui.Register or not onyx.Font then return end

    CasesSystem = CasesSystem or {}
local CS     = CasesSystem
local Client = CS.Client or {}
CS.Client    = Client

Client.Renderer = Client.Renderer or {}
local Renderer  = Client.Renderer

Client.Admin    = Client.Admin or {}
local Admin     = Client.Admin

-- 1. ONYX COLORS & SCALING HELPERS
local colorPrimary   = (onyx and onyx.Config and onyx:Config('colors.primary'))   or Color(37, 40, 47)
local colorSecondary = (onyx and onyx.Config and onyx:Config('colors.secondary')) or Color(42, 44, 51)
local colorTertiary  = (onyx and onyx.Config and onyx:Config('colors.tertiary'))  or Color(48, 50, 59)
local colorAccent    = (onyx and onyx.Config and onyx:Config('colors.accent'))    or Color(142, 73, 252)
local colorGradient  = (onyx and onyx.OffsetColor) and onyx.OffsetColor(colorAccent, -50) or Color(100, 45, 180)
local colorOutline   = Color(255, 255, 255, 5)
local colorGray      = Color(159, 159, 159)
local colorLine      = Color(75, 75, 75)
local colorCanAfford = Color(121, 255, 141)
local colorCannotAfford = Color(253, 120, 120)
local colorGold      = Color(255, 200, 50)
local colorWhite     = Color(235, 235, 235)
local colorBG        = (onyx and onyx.OffsetColor) and onyx.OffsetColor(colorPrimary, -3) or Color(32, 34, 40)

local function SW(n)
    if onyx and onyx.ScaleWide then return onyx.ScaleWide(n) end
    return math.Round(n / 1600 * ScrW())
end

local function ST(n)
    if onyx and onyx.ScaleTall then return onyx.ScaleTall(n) end
    return math.Round(n / 900 * ScrH())
end

local function BuildFonts()
    local function sz(b) return math.max(9, ST(b)) end
    surface.CreateFont('CSF4.H1',     { font = 'Comfortaa', size = sz(17), weight = 700, extended = true })
    surface.CreateFont('CSF4.H2',     { font = 'Comfortaa', size = sz(15), weight = 700, extended = true })
    surface.CreateFont('CSF4.Title',  { font = 'Comfortaa', size = sz(22), weight = 700, extended = true })
    surface.CreateFont('CSF4.Bold14', { font = 'Comfortaa', size = sz(14), weight = 700, extended = true })
    surface.CreateFont('CSF4.Bold13', { font = 'Comfortaa', size = sz(13), weight = 700, extended = true })
    surface.CreateFont('CSF4.Small',  { font = 'Comfortaa', size = sz(12), weight = 500, extended = true })
    surface.CreateFont('CSF4.SmallB', { font = 'Comfortaa', size = sz(12), weight = 700, extended = true })
    surface.CreateFont('CSF4.ExcludedBadge', { font = 'Comfortaa', size = sz(11), weight = 700, extended = true })
    surface.CreateFont('CSF4.Bal',    { font = 'Comfortaa', size = sz(24), weight = 700, extended = true })
end
BuildFonts()
hook.Add('OnScreenSizeChanged', 'CasesOnyxF4.Fonts', BuildFonts)

-- 2. CONVARS & SETTINGS
local UI_VOLUME   = CreateClientConVar('cases_system_ui_volume', '1', true, false)
local FAST_OPEN   = CreateClientConVar('cases_system_fast_open', '0', true, false)
local RARE_NOTIFY = CreateClientConVar('cases_system_rare_notify', '1', true, false)

local function getUIVolume() return math.Clamp(UI_VOLUME:GetFloat(), 0, 1) end
local function isFastOpen() return FAST_OPEN:GetBool() end

local function playUISound(sndPath)
    local vol = getUIVolume()
    if vol <= 0 then return end
    local clean = sndPath
    if string.StartWith(clean, 'sound/') then clean = string.sub(clean, 7) end
    sound.PlayFile('sound/' .. clean, 'noplay', function(station)
        if IsValid(station) then
            station:SetVolume(vol)
            station:Play()
        else
            surface.PlaySound(clean)
        end
    end)
end

-- 3. HELPERS FOR CURRENCY, RARITY & ICONS
local function FormatNumber(n)
    n = math.floor(tonumber(n) or 0)
    local sign = (n < 0) and '-' or ''
    local s = tostring(math.abs(n))
    local out = ''
    while #s > 3 do
        out = ' ' .. string.sub(s, -3) .. out
        s = string.sub(s, 1, #s - 3)
    end
    return sign .. s .. out
end

local function FormatMoney(n)
    return FormatNumber(n) .. ' ₽'
end

local function GetIGSBalance()
    local ply = LocalPlayer()
    if not IsValid(ply) then return 0 end
    for _, fnName in ipairs({ 'IGSFunds', 'GetIGSBalance', 'GetIGSFunds', 'IGSBalance' }) do
        local fn = ply[fnName]
        if isfunction(fn) then
            local ok, val = pcall(fn, ply)
            if ok and isnumber(val) then return val end
        end
    end
    if istable(IGS) then
        for _, fnName in ipairs({ 'GetBalance', 'GetFunds' }) do
            if isfunction(IGS[fnName]) then
                local ok, val = pcall(IGS[fnName])
                if ok and isnumber(val) then return val end
            end
        end
    end
    local nw = ply:GetNWInt('IGS.Funds', -1)
    if nw >= 0 then return nw end
    return 0
end

local RARITY_COLORS = {
    [1] = { name = 'Ширпотреб',     color = Color(176, 195, 217) },
    [2] = { name = 'Армейское',     color = Color(94, 152, 217)  },
    [3] = { name = 'Запрещенное',   color = Color(136, 71, 255)  },
    [4] = { name = 'Засекреченное', color = Color(211, 44, 230)  },
    [5] = { name = 'Тайное',        color = Color(235, 75, 75)   },
    [6] = { name = 'Необычайное',   color = Color(255, 215, 0)   },
}

local function GetRewardRarity(reward, totalChance)
    if not reward then return RARITY_COLORS[1] end
    local chance = tonumber(reward.chance) or 1
    local pct = (totalChance and totalChance > 0) and (chance / totalChance * 100) or chance
    if pct <= 2.0  then return RARITY_COLORS[6]
    elseif pct <= 6.0  then return RARITY_COLORS[5]
    elseif pct <= 14.0 then return RARITY_COLORS[4]
    elseif pct <= 25.0 then return RARITY_COLORS[3]
    elseif pct <= 40.0 then return RARITY_COLORS[2]
    else return RARITY_COLORS[1] end
end

local function GetRewardColor(reward, totalChance)
    if reward and reward.color and istable(reward.color) and reward.color.r then
        return Color(reward.color.r, reward.color.g, reward.color.b, reward.color.a or 255)
    end
    return GetRewardRarity(reward, totalChance).color
end

local webCache = {}
file.CreateDir('cases_system_icons')

local caseIconsMap = {
    ['city_starter'] = 'https://raw.githubusercontent.com/Linan5454/GoodAstRP/main/%D0%93%D0%BE%D1%80%D0%BE%D0%B4%D1%81%D0%BA%D0%BE%D0%B9%20%D1%81%D1%82%D0%B0%D1%80%D1%82.png',
    ['street_cache'] = 'https://raw.githubusercontent.com/Linan5454/GoodAstRP/main/%D0%A3%D0%BB%D0%B8%D1%87%D0%BD%D1%8B%D0%B9%20%D0%BA%D0%B5%D0%B9%D1%81.png',
    ['contraband']   = 'https://raw.githubusercontent.com/Linan5454/GoodAstRP/main/%D0%9A%D0%BE%D0%BD%D1%82.png',
    ['merchant']     = 'https://raw.githubusercontent.com/Linan5454/GoodAstRP/main/%D0%9A%D0%BE%D0%BC%D0%B5%D1%80%D1%81%D0%B0%D0%BD%D1%82.png',
    ['arsenal']      = 'https://raw.githubusercontent.com/Linan5454/GoodAstRP/main/%D0%B0%D1%80%D1%81%D0%B5%D0%BD%D0%B0%D0%BB.png',
    ['vip_club']     = 'https://raw.githubusercontent.com/Linan5454/GoodAstRP/main/%D0%B2%D0%B8%D0%BF-%D0%BA%D0%BB%D1%83%D0%B1.png',
    ['oligarch']     = 'https://raw.githubusercontent.com/Linan5454/GoodAstRP/main/%D0%BE%D0%BB%D0%B8%D0%B3%D0%B0%D1%80%D1%85.png',
    ['jackpot']      = 'https://raw.githubusercontent.com/Linan5454/GoodAstRP/main/%D0%B4%D0%B6%D0%B5%D0%BA%D0%BF%D0%BE%D1%82.png',
}
local caseNameMap = {
    ['city_starter'] = 'Городской старт',
    ['street_cache'] = 'Уличный кейс',
    ['contraband']   = 'Контрабанда',
    ['merchant']     = 'Купец',
    ['underground']  = 'Подпольный оружейник',
    ['syndicate']    = 'Синдикат',
    ['jackpot']      = 'Джекпот',
    ['oligarch']     = 'Олигарх',
    ['vip_club']     = 'VIP Клуб',
    ['vip_case']     = 'VIP Кейс',
    ['legend']       = 'Легенда',
}

local function GetCaseName(caseID)
    if not caseID or caseID == '' then return 'Обычный' end
    local idLower = string.lower(tostring(caseID))
    if caseNameMap[idLower] then return caseNameMap[idLower] end
    if CasesSystem and CasesSystem.Cases and CasesSystem.Cases[idLower] and CasesSystem.Cases[idLower].name then
        return CasesSystem.Cases[idLower].name
    end
    if Client and Client.Data and Client.Data.cases then
        for _, c in ipairs(Client.Data.cases) do
            if string.lower(tostring(c.id or '')) == idLower and c.name then
                return c.name
            end
        end
    end
    if CasesSystem and CasesSystem.DefaultCases then
        for _, c in ipairs(CasesSystem.DefaultCases) do
            if string.lower(tostring(c.id or '')) == idLower and c.name then
                return c.name
            end
        end
    end
    return string.upper(string.sub(caseID, 1, 1)) .. string.sub(caseID, 2)
end

local function GetCaseIcon(cdef)
    if not cdef then return nil end
    local id = string.lower(tostring(cdef.id or ''))
    local name = string.lower(tostring(cdef.name or ''))
    if caseIconsMap[id] then return caseIconsMap[id] end
    if caseIconsMap[name] then return caseIconsMap[name] end
    if isstring(cdef.icon) and cdef.icon ~= '' then return cdef.icon end
    return nil
end

local function GetWebOrLocalMat(path)
    if not isstring(path) or path == '' then return nil end
    if webCache[path] then return webCache[path].mat end
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

    if string.StartWith(path, 'http://') or string.StartWith(path, 'https://') then
        local ext = string.find(string.lower(path), '%.jpe?g') and 'jpg' or 'png'
        local dataPath = 'cases_system_icons/' .. util.CRC(path) .. '.' .. ext
        local entry = { mat = nil }
        webCache[path] = entry

        local function load()
            local mat = Material('../data/' .. dataPath, 'smooth mips')
            if mat and not mat:IsError() then entry.mat = mat end
        end

        if file.Exists(dataPath, 'DATA') then
            load()
            return entry.mat
        end

        http.Fetch(path, function(body, _, _, code)
            if code == 200 and isstring(body) and body ~= '' then
                file.Write(dataPath, body)
                if file.Exists(dataPath, 'DATA') then load() end
            end
        end, function() end)

        return nil
    else
        local mat = Material(path, 'smooth mips')
        if mat and not mat:IsError() then
            webCache[path] = { mat = mat }
            return mat
        end
    end
    return nil
end

-- Prime generated materials once, rather than creating them each frame.
timer.Simple(0, function()
    if not CasesSystem.GeneratedRewardIcons then return end
    for _, fileName in pairs(CasesSystem.GeneratedRewardIcons) do
        GetWebOrLocalMat("https://raw.githubusercontent.com/Linan5454/GoodAstRP/main/" .. fileName)
    end
end)

local function GetOwnedCount(caseID)
    if not Client.Data or not Client.Data.inventory or not Client.Data.inventory.cases then return 0 end
    return tonumber(Client.Data.inventory.cases[caseID]) or 0
end

-- 4. CASE ITEM CARD (Exact Replica of onyx.f4.Item)
do
    local fontDesc = (onyx and onyx.Font and onyx.Font('Comfortaa@16')) or 'CSF4.Small'
    local PANEL = {}

    function PANEL:Init()
        self.padding = ST(7.5)
        self.itemColor = colorAccent
        self.itemColorBG = colorPrimary
        self.colorBG = colorSecondary
        self.colorBGGrad = Color(57, 57, 57, 25)
        self.caseDef = nil
        self.iconMat = nil

        self.iconContainer = self:Add('Panel')
        self.iconContainer:SetMouseInputEnabled(false)
        self.iconContainer.PerformLayout = function(pnl, w, h)
            pnl.mask = onyx.CalculateCircle(w * .5, h * .5, h * .5 - 2, 24)
        end
        local me = self
        self.iconContainer.Paint = function(pnl, w, h)
            local child = pnl:GetChild(0)
            if IsValid(child) and child:IsVisible() then
                onyx.DrawCircle(w * .5, h * .5, h * .5, me.itemColorBG)
                if pnl.mask then
                    onyx.DrawWithPolyMask(pnl.mask, function() child:PaintManual() end)
                else
                    child:PaintManual()
                end
                onyx.DrawOutlinedCircle(w * .5, h * .5, h * .5, 3, me.itemColor)
            else
                onyx.DrawCircle(w * .5, h * .5, h * .5, me.itemColorBG)
                local mat = me:GetIconMat()
                if mat then
                    local sz = h * .7
                    if pnl.mask then
                        onyx.DrawWithPolyMask(pnl.mask, function()
                            surface.SetMaterial(mat)
                            surface.SetDrawColor(color_white)
                            surface.DrawTexturedRect(w * .5 - sz * .5, h * .5 - sz * .5, sz, sz)
                        end)
                    else
                        surface.SetMaterial(mat)
                        surface.SetDrawColor(color_white)
                        surface.DrawTexturedRect(w * .5 - sz * .5, h * .5 - sz * .5, sz, sz)
                    end
                else
                    local fallback = Material('icon16/box.png')
                    surface.SetMaterial(fallback)
                    surface.SetDrawColor(color_white)
                    surface.DrawTexturedRect(w * .5 - ST(12), h * .5 - ST(12), ST(24), ST(24))
                end
                onyx.DrawOutlinedCircle(w * .5, h * .5, h * .5, 3, me.itemColor)
            end
        end

        self.lblName = self:Add('onyx.Label')
        self.lblName:SetText('Кейс')
        self.lblName:Font('Comfortaa Bold@18')
        self.lblName:SetContentAlignment(1)

        self.pnlDesc = self:Add('Panel')
        self.pnlDesc:SetMouseInputEnabled(false)
        self.pnlDesc.label = ''
        self.pnlDesc.text = ''
        self.pnlDesc.color = colorCanAfford
        self.pnlDesc.Paint = function(pnl, w, h)
            local label = (pnl.label or ''):Trim()
            if label ~= '' then
                local tw = draw.SimpleText(label .. ': ', fontDesc, 0, 0, colorGray, 0, 0)
                draw.SimpleText(pnl.text, fontDesc, tw, 0, pnl.color, 0, 0)
            else
                draw.SimpleText(pnl.text, fontDesc, 0, 0, pnl.color, 0, 0)
            end
        end
    end

    function PANEL:GetIconMat()
        if self.iconMat then return self.iconMat end
        if not self.caseDef then return nil end
        local url = GetCaseIcon(self.caseDef)
        if url then
            local mat = GetWebOrLocalMat(url)
            if mat then self.iconMat = mat; return mat end
        end
        return nil
    end

    function PANEL:SetCase(cdef)
        self.caseDef = cdef
        self.iconMat = nil
        if not cdef then return end

        self.lblName:SetText(cdef.name or cdef.id or 'Кейс')
        local price = tonumber(cdef.price) or 0
        local owned = GetOwnedCount(cdef.id)

        self.pnlDesc.label = 'Цена'
        self.pnlDesc.text = FormatMoney(price) .. (owned > 0 and ('  (В наличии: ' .. owned .. ' шт.)') or '')
        self.pnlDesc.color = (GetIGSBalance() >= price or owned > 0) and colorCanAfford or colorCannotAfford

        local col = (cdef.color and istable(cdef.color) and Color(cdef.color.r, cdef.color.g, cdef.color.b)) or colorAccent
        self.itemColor = col
        self.colorBGGrad = onyx.LerpColor(.05, colorSecondary, col)
        self.itemColorBG = onyx.LerpColor(.1, colorSecondary, onyx.CopyColor(col))

        self:InvalidateLayout()
    end

    function PANEL:GetName()
        return self.lblName:GetText()
    end

    function PANEL:PerformLayout(w, h)
        local p = self.padding
        local height = h - p * 2

        self:DockPadding(p, p, p, p)
        self.mask = onyx.CalculateRoundedBox(8, 1, 1, w - 2, h - 2)

        self.iconContainer:Dock(LEFT)
        self.iconContainer:SetWide(height)
        self.iconContainer:DockMargin(0, 0, SW(10), 0)

        self.lblName:Dock(TOP)
        self.lblName:SetTall(height * .5)

        self.pnlDesc:Dock(FILL)
    end

    function PANEL:Paint(w, h)
        draw.RoundedBox(8, 0, 0, w, h, colorOutline)
        draw.RoundedBox(8, 1, 1, w - 2, h - 2, self.colorBG)

        if self.mask then
            onyx.DrawWithPolyMask(self.mask, function()
                onyx.DrawMatGradient(0, 0, w, h, TOP, self.colorBGGrad)
            end)
        end
    end

    onyx.gui.Register('cases.F4Item', PANEL)
end

-- 4.5. УНИВЕРСАЛЬНЫЙ СЛАЙДЕР В СТИЛЕ ONYX
local function CreateOnyxSlider(parent, minVal, maxVal, defaultVal, onChange, themeColor, knobBorder)
    local pnl = parent:Add('Panel')
    pnl.val = defaultVal or minVal
    pnl.minVal = minVal or 1
    pnl.maxVal = maxVal or 10
    pnl.dragging = false
    pnl.themeColor = themeColor or colorAccent
    pnl.knobBorder = knobBorder

    pnl.Paint = function(s, w, h)
        local barH = ST(4)
        local barY = math.floor((h - barH) * .5)
        local radius = math.floor(barH * .5)
        local col = s.themeColor or colorAccent

        -- Трек фона
        draw.RoundedBox(radius, 0, barY, w, barH, Color(48, 50, 60))

        -- Заполненная часть полосы
        local frac = math.Clamp((s.val - s.minVal) / math.max(1, s.maxVal - s.minVal), 0, 1)
        local fillW = math.Clamp(math.floor(w * frac), 0, w)
        if fillW > 0 then
            draw.RoundedBox(radius, 0, barY, fillW, barH, col)
        end

        -- Идеально круглый сглаженный ползунок
        local knobR = ST(7)
        local knobX = math.Clamp(math.floor(w * frac), knobR, w - knobR)
        local knobY = h * .5

        onyx.DrawCircle(knobX, knobY, knobR, col)
        onyx.DrawCircle(knobX, knobY, math.max(1, knobR - 2), ColorAlpha(color_white, 40))
    end

    local function updateFromMouse(s, mouseX)
        local w = s:GetWide()
        if w <= 0 then return end
        local frac = math.Clamp(mouseX / w, 0, 1)
        local newVal = math.Round(s.minVal + frac * (s.maxVal - s.minVal))
        newVal = math.Clamp(newVal, s.minVal, s.maxVal)
        if newVal ~= s.val then
            s.val = newVal
            if onChange then onChange(s.val) end
            playUISound('buttons/lightswitch2.wav')
        end
    end

    pnl.OnMousePressed = function(s, mc)
        if mc == MOUSE_LEFT then
            s.dragging = true
            s:MouseCapture(true)
            local mx, _ = s:CursorPos()
            updateFromMouse(s, mx)
        end
    end

    pnl.OnMouseReleased = function(s, mc)
        if mc == MOUSE_LEFT and s.dragging then
            s.dragging = false
            s:MouseCapture(false)
        end
    end

    pnl.OnCursorMoved = function(s, mx, my)
        if s.dragging then
            updateFromMouse(s, mx)
        end
    end

    return pnl
end

-- 5. ПОЛНОЭКРАННАЯ СТРАНИЦА ОТКРЫТИЯ И ПОКУПКИ КЕЙСА (ОТДЕЛЬНЫЕ СЛАЙДЕРЫ + ИКОНКИ НАГРАД)
do
    local PANEL = {}

    function PANEL:Init()
        local padding = ST(10)
        self.padding = padding
        self.cdef = nil
        self.buyAmount = 1
        self.openAmount = 1

        self:DockPadding(ST(10), ST(8), ST(10), ST(10))

        local this = self

        -- 1. ВЕРХНИЙ БЛОК УПРАВЛЕНИЯ (3 КОЛОНКИ: ОТКРЫТИЕ СЛЕВА, КЕЙС ПО ЦЕНТРУ, ПОКУПКА СПРАВА)
        self.cardControls = self:Add('Panel')
        self.cardControls:Dock(TOP)
        self.cardControls:SetTall(ST(165))
        self.cardControls:DockMargin(0, 0, 0, ST(10))
        self.cardControls.Paint = function() end

        -- ЛЕВАЯ КОЛОНКА: ОТКРЫТИЕ КЕЙСОВ
        self.openSide = self.cardControls:Add('Panel')
        self.openSide:Dock(LEFT)
        self.openSide:DockPadding(ST(14), ST(8), ST(14), ST(8))
        self.openSide.Paint = function(pnl, w, h)
            draw.RoundedBox(8, 0, 0, w, h, colorSecondary)
        end

        local openHeader = self.openSide:Add('Panel')
        openHeader:Dock(TOP)
        openHeader:SetTall(ST(24))
        openHeader.Paint = function(pnl, w, h)
            draw.SimpleText('ОТКРЫТИЕ КЕЙСОВ', 'CSF4.Bold14', 0, h * .5, colorAccent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        self.btnOpen = self.openSide:Add('onyx.Button')
        self.btnOpen:Dock(BOTTOM)
        self.btnOpen:SetTall(ST(36))
        self.btnOpen:Font('Comfortaa Bold@13')
        self.btnOpen:SetColorIdle(colorAccent)
        self.btnOpen:SetColorHover(onyx.OffsetColor(colorAccent, 25))
        self.btnOpen:SetMasking(true)
        self.btnOpen:SetGradientColor(colorGradient)
        self.btnOpen:SetGradientDirection(RIGHT)
        self.btnOpen.DoClick = function()
            if not this.cdef then return end
            playUISound('ui/buttonclickrelease.wav')
            Client.SendOpen(this.cdef.id, this.openAmount or 1)
        end

        local fastOpenRow = self.openSide:Add('Panel')
        fastOpenRow:Dock(BOTTOM)
        fastOpenRow:SetTall(ST(26))
        fastOpenRow:DockMargin(0, 0, 0, ST(4))
        fastOpenRow.Paint = function() end

        local tgl = fastOpenRow:Add('onyx.TogglerLabel')
        tgl:Dock(FILL)
        tgl:SetText('Быстрое открытие')
        tgl:Font('Comfortaa@13')
        tgl:SetChecked(isFastOpen(), true)
        tgl:On('OnChange', function(_, val)
            FAST_OPEN:SetBool(val == true)
            playUISound('ui/buttonclickrelease.wav')
        end)

        local openSliderWrap = self.openSide:Add('Panel')
        openSliderWrap:Dock(FILL)
        openSliderWrap:DockMargin(0, ST(2), 0, ST(2))

        self.sliderOpen = CreateOnyxSlider(openSliderWrap, 1, 10, 1, function(val)
            this.openAmount = val
            this:UpdateOpenButton()
        end, colorAccent)
        self.sliderOpen:Dock(FILL)

        -- ЦЕНТРАЛЬНАЯ КОЛОНКА: ВИТРИНА КЕЙСА + НАЛИЧИЕ
        self.iconSide = self.cardControls:Add('Panel')
        self.iconSide:Dock(LEFT)
        self.iconSide:DockMargin(ST(10), 0, ST(10), 0)
        self.iconSide:DockPadding(ST(6), ST(6), ST(6), ST(6))
        self.iconSide.Paint = function(pnl, w, h)
            draw.RoundedBox(8, 0, 0, w, h, colorPrimary)
        end

        self.iconWrap = self.iconSide:Add('Panel')
        self.iconWrap:Dock(FILL)

        self.iconModel = self.iconWrap:Add('DModelPanel')
        self.iconModel:Dock(FILL)
        self.iconModel:SetCursor('arrow')
        self.iconModel.LayoutEntity = function(pnl, ent)
            ent:SetAngles(Angle(0, RealTime() * 30 % 360, 0))
        end

        self.lblUnitInfo = self.iconSide:Add('Panel')
        self.lblUnitInfo:Dock(BOTTOM)
        self.lblUnitInfo:SetTall(ST(26))
        self.lblUnitInfo.Paint = function(pnl, w, h)
            local owned = GetOwnedCount(this.cdef and this.cdef.id or '')
            draw.SimpleText('В наличии: ' .. owned .. ' шт.', 'CSF4.H1', w * .5, h * .5, colorWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- ПРАВАЯ КОЛОНКА: ПОКУПКА КЕЙСОВ
        self.buySide = self.cardControls:Add('Panel')
        self.buySide:Dock(FILL)
        self.buySide:DockPadding(ST(14), ST(8), ST(14), ST(8))
        self.buySide.Paint = function(pnl, w, h)
            draw.RoundedBox(8, 0, 0, w, h, colorSecondary)
        end

        local buyHeader = self.buySide:Add('Panel')
        buyHeader:Dock(TOP)
        buyHeader:SetTall(ST(24))
        buyHeader.Paint = function(pnl, w, h)
            draw.SimpleText('КУПИТЬ КЕЙСЫ', 'CSF4.Bold14', 0, h * .5, Color(121, 255, 141), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        self.btnBuy = self.buySide:Add('onyx.Button')
        self.btnBuy:Dock(BOTTOM)
        self.btnBuy:SetTall(ST(36))
        self.btnBuy:Font('Comfortaa Bold@13')
        self.btnBuy:SetColorIdle(Color(45, 140, 60))
        self.btnBuy:SetColorHover(Color(55, 170, 75))
        self.btnBuy:SetMasking(true)
        self.btnBuy:SetGradientColor(Color(25, 80, 35))
        self.btnBuy:SetGradientDirection(RIGHT)
        self.btnBuy.DoClick = function()
            if not this.cdef then return end
            playUISound('ui/buttonclickrelease.wav')
            Client.SendBuy(this.cdef.id, this.buyAmount or 1)
        end

        local buySliderWrap = self.buySide:Add('Panel')
        buySliderWrap:Dock(FILL)
        buySliderWrap:DockMargin(0, ST(2), 0, ST(2))

        self.sliderBuy = CreateOnyxSlider(buySliderWrap, 1, 10, 1, function(val)
            this.buyAmount = val
            this:UpdateBuyButton()
        end, Color(55, 170, 75))
        self.sliderBuy:Dock(FILL)

        self.cardControls.PerformLayout = function(pnl, w, h)
            local centerW = math.floor(w * 0.32)
            local sideW = math.floor((w - centerW - ST(20)) / 2)
            self.openSide:SetWide(sideW)
            self.iconSide:SetWide(centerW)
        end

        -- 2. НИЖНИЙ БЛОК: СПИСОК ВСЕХ НАГРАД С ИКОНКАМИ И ШАНСАМИ
        self.rewardsContainer = self:Add('Panel')
        self.rewardsContainer:Dock(FILL)
        self.rewardsContainer.Paint = function(pnl, w, h)
            draw.RoundedBox(8, 0, 0, w, h, colorSecondary)
        end

        self.lblRewHeader = self.rewardsContainer:Add('Panel')
        self.lblRewHeader:Dock(TOP)
        self.lblRewHeader:SetTall(ST(34))
        self.lblRewHeader.Paint = function(pnl, w, h)
            local rewCount = (this.cdef and this.cdef.rewards and #this.cdef.rewards) or 0
            draw.SimpleText('СОДЕРЖИМОЕ И ВЕРОЯТНОСТИ ВЫПАДЕНИЯ:', 'CSF4.Bold14', ST(14), h * .5, colorWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText('Всего предметов: ' .. rewCount .. ' шт.', 'CSF4.Small', w - ST(14), h * .5, colorGray, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(colorLine)
            surface.DrawRect(ST(12), h - 1, w - ST(24), 1)
        end

        self.contentScroll = self.rewardsContainer:Add('onyx.ScrollPanel')
        self.contentScroll:Dock(FILL)
        self.contentScroll:DockMargin(ST(12), ST(6), ST(12), ST(10))
    end

    function PANEL:UpdateBuyButton()
        if not self.cdef then return end
        local price = tonumber(self.cdef.price) or 0
        local count = self.buyAmount or 1
        local totalCost = price * count
        self.btnBuy:SetText('КУПИТЬ ' .. count .. ' ШТ. (' .. FormatMoney(totalCost) .. ')')
    end

    function PANEL:UpdateOpenButton()
        if not self.cdef then return end
        local count = self.openAmount or 1
        self.btnOpen:SetText('ОТКРЫТЬ ' .. count .. ' ШТ.')
    end

    function PANEL:SetupCase(cdef)
        self.cdef = cdef
        self.buyAmount = 1
        self.openAmount = 1

        if IsValid(self.sliderBuy) then self.sliderBuy.val = 1 end
        if IsValid(self.sliderOpen) then self.sliderOpen.val = 1 end

        self:UpdateBuyButton()
        self:UpdateOpenButton()

        self.contentScroll:Clear()

        local rewards = cdef.rewards or {}
        local totalChance = 0
        for _, r in ipairs(rewards) do totalChance = totalChance + (tonumber(r.chance) or 1) end

        for _, rew in ipairs(rewards) do
            local rewPnl = self.contentScroll:Add('Panel')
            rewPnl:Dock(TOP)
            rewPnl:SetTall(ST(46))
            rewPnl:DockMargin(0, 0, 0, ST(6))

            local isExcluded = (rew.owned == true)
            local col = GetRewardColor(rew, totalChance)
            local pct = string.format('%.1f%%', (tonumber(rew.chance) or 1) / math.max(1, totalChance) * 100)
            local rewName = rew.name or 'Награда'
            local iconPath = CasesSystem.GetRewardArtwork(rew) or 'icon16/box.png'
            local iconMat = nil
            if iconPath and iconPath ~= '' then
                iconMat = GetWebOrLocalMat(iconPath)
            end

            rewPnl.Paint = function(p, w, h)
                -- HTTP artwork may finish loading after SetupCase; read the prepared cache.
                if not iconMat and webCache[iconPath] then iconMat = webCache[iconPath].mat end
                if isExcluded then
                    -- Затемненный фон лота, который больше не может выпасть
                    draw.RoundedBox(6, 0, 0, w, h, Color(20, 21, 26, 240))
                    draw.RoundedBoxEx(6, 0, 0, ST(4), h, Color(65, 68, 78, 220), true, false, true, false)

                    -- Затемненный контейнер иконки
                    local iconBoxSz = ST(32)
                    local iconBoxX = ST(12)
                    local iconBoxY = math.floor((h - iconBoxSz) * .5)
                    draw.RoundedBox(4, iconBoxX, iconBoxY, iconBoxSz, iconBoxSz, Color(26, 27, 33, 200))

                    if iconMat then
                        surface.SetMaterial(iconMat)
                        surface.SetDrawColor(Color(120, 120, 120, 130))
                        local iconSz = ST(22)
                        local ix = iconBoxX + math.floor((iconBoxSz - iconSz) * .5)
                        local iy = iconBoxY + math.floor((iconBoxSz - iconSz) * .5)
                        surface.DrawTexturedRect(ix, iy, iconSz, iconSz)
                    end

                    -- Название награды приглушенным серым цветом
                    local textX = iconBoxX + iconBoxSz + ST(12)
                    draw.SimpleText(rewName, 'CSF4.Bold14', textX, h * .5, Color(135, 138, 150), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                    -- Надпись шрифтом Comfortaa: "больше не может выпасть"
                    local badgeText = 'больше не может выпасть'
                    surface.SetFont('CSF4.ExcludedBadge')
                    local tw = surface.GetTextSize(badgeText)
                    local pillW = tw + ST(18)
                    local pillH = ST(24)
                    local pillX = w - pillW - ST(12)
                    local pillY = math.floor((h - pillH) * .5)

                    draw.RoundedBox(12, pillX, pillY, pillW, pillH, Color(220, 55, 55, 25))
                    draw.RoundedBox(12, pillX + 1, pillY + 1, pillW - 2, pillH - 2, Color(220, 55, 55, 55))
                    draw.SimpleText(badgeText, 'CSF4.ExcludedBadge', pillX + pillW * .5, pillY + pillH * .5, Color(255, 110, 110), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                else
                    draw.RoundedBox(6, 0, 0, w, h, colorPrimary)
                    draw.RoundedBoxEx(6, 0, 0, ST(4), h, col, true, false, true, false)

                    -- Аккуратный контейнер иконки
                    local iconBoxSz = ST(32)
                    local iconBoxX = ST(12)
                    local iconBoxY = math.floor((h - iconBoxSz) * .5)
                    draw.RoundedBox(4, iconBoxX, iconBoxY, iconBoxSz, iconBoxSz, colorTertiary)

                    if iconMat then
                        surface.SetMaterial(iconMat)
                        surface.SetDrawColor(color_white)
                        local iconSz = ST(22)
                        local ix = iconBoxX + math.floor((iconBoxSz - iconSz) * .5)
                        local iy = iconBoxY + math.floor((iconBoxSz - iconSz) * .5)
                        surface.DrawTexturedRect(ix, iy, iconSz, iconSz)
                    end

                    -- Название награды
                    local textX = iconBoxX + iconBoxSz + ST(12)
                    draw.SimpleText(rewName, 'CSF4.Bold14', textX, h * .5, colorWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                    -- Бейджик шанса в аккуратной капсуле справа
                    local pillW = ST(72)
                    local pillH = ST(24)
                    local pillX = w - pillW - ST(12)
                    local pillY = math.floor((h - pillH) * .5)

                    draw.RoundedBox(12, pillX, pillY, pillW, pillH, ColorAlpha(col, 20))
                    draw.RoundedBox(12, pillX + 1, pillY + 1, pillW - 2, pillH - 2, ColorAlpha(col, 40))
                    draw.SimpleText(pct, 'CSF4.SmallB', pillX + pillW * .5, pillY + pillH * .5, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            end
        end

        local iconUrl = GetCaseIcon(cdef)
        if iconUrl then
            local mat = GetWebOrLocalMat(iconUrl)
            self.iconWrap.Paint = function(p, w, h)
                if mat then
                    local sz = math.min(w, h) * 0.95
                    surface.SetMaterial(mat)
                    surface.SetDrawColor(color_white)
                    surface.DrawTexturedRect((w - sz) * .5, (h - sz) * .5, sz, sz)
                end
            end
            self.iconModel:SetVisible(false)
        else
            self.iconWrap.Paint = function() end
            self.iconModel:SetVisible(true)
            self.iconModel:SetModel('models/items/item_item_crate.mdl')
        end
    end

    function PANEL:Paint(w, h)
        draw.RoundedBoxEx(8, 0, 0, w, h, colorBG, false, false, true, true)
    end

    onyx.gui.Register('cases.CasePreview', PANEL)
end

-- 6. ТАБ 1: КАТАЛОГ КЕЙСОВ
do
    local PANEL = {}

    function PANEL:Init()
        local this = self
        local toolbarPadding = ST(5)

        self.container = self:Add('Panel')
        self.container:Dock(FILL)

        self.toolbar = self:Add('DPanel')
        self.toolbar:Dock(TOP)
        self.toolbar:SetTall(ST(80))
        self.toolbar:DockMargin(0, 0, 0, ST(10))
        self.toolbar.Paint = function(pnl, w, h)
            draw.RoundedBox(8, 0, 0, w, h, colorSecondary)
        end
        self.toolbar.PerformLayout = function(pnl, w, h)
            self.topRow:SetTall(h / 2)
        end

        self.topRow = self.toolbar:Add('Panel')
        self.topRow:Dock(BOTTOM)
        self.topRow:DockPadding(toolbarPadding, toolbarPadding, toolbarPadding * 2, toolbarPadding)

        self.navbar = self.toolbar:Add('onyx.Navbar')
        self.navbar:Dock(FILL)
        self.navbar:SetContainer(self.container)
        self.navbar:SetKeepTabContent(true)
        self.navbar.Paint = function(pnl, w, h)
            draw.RoundedBoxEx(8, 0, 0, w, h, colorTertiary, true, true)
            surface.SetDrawColor(colorLine)
            surface.DrawRect(0, h - 1, w, 1)
        end
        self.navbar.OnTabSelected = function()
            if IsValid(self.search) then self.search:SetValue('') end
        end

        self.search = self.topRow:Add('onyx.TextEntry')
        self.search:SetPlaceholderText('Поиск кейса...')
        self.search:SetPlaceholderIcon('https://i.imgur.com/Nk3IUJT.png', 'smooth mips')
        self.search:Dock(LEFT)
        self.search:SetWide(SW(160))
        self.search:SetUpdateOnType(true)
        self.search.OnValueChange = function(pnl, value)
            value = string.lower(value)
            local activeTab = this.navbar:GetActiveTab()
            if not IsValid(activeTab) then return end
            local plist = activeTab.content
            if not IsValid(plist) then return end

            for _, cat in ipairs(plist:GetItems()) do
                local layout = cat.canvas:GetChild(0)
                if not IsValid(layout) then continue end
                local vis = 0
                for _, item in ipairs(layout:GetChildren()) do
                    local show = (value == '') or (string.find(string.lower(item:GetName() or ''), value, nil, true) ~= nil)
                    item:SetVisible(show)
                    if show then vis = vis + 1 end
                end
                layout:InvalidateLayout()
                cat:SetVisible(value == '' or vis > 0)
                cat:UpdateInTick()
            end
            plist:InvalidateLayout()
        end

        self.caseCountLbl = self.topRow:Add('onyx.Label')
        self.caseCountLbl:Dock(RIGHT)
        self.caseCountLbl:Font('Comfortaa@14')
        self.caseCountLbl:SetText('')
        self.caseCountLbl:SetContentAlignment(6)

        -- DEDICATED FULL-SCREEN CASE VIEW
        self.preview = self:Add('onyx.Panel')
        self.preview:Hide()
        self.preview.PerformLayout = function(pnl, w, h)
            pnl.content:SetSize(w, h)
        end

        self.preview.content = self.preview:Add('cases.CasePreview')

        self.enabledFirst = false
        self:BuildCategories()
    end

    function PANEL:EnablePreview(cdef)
        local f = Renderer.Frame
        if IsValid(f) and f.EnableCasePreview then
            f:EnableCasePreview(cdef)
        end
    end

    function PANEL:DisablePreview()
        local f = Renderer.Frame
        if IsValid(f) and f.DisableCasePreview then
            f:DisableCasePreview()
        end
    end

    function PANEL:PerformLayout(w, h)
        if IsValid(self.preview) and self.preview:IsVisible() then
            self.preview:SetSize(w, h)
            if IsValid(self.preview.content) then
                self.preview.content:SetSize(w, h)
            end
        end
    end

    function PANEL:Refresh()
        self:BuildCategories()
    end

    function PANEL:BuildCategories()
        local cases = {}
        for _, cdef in ipairs((Client.Data and Client.Data.cases) or {}) do
            if cdef.enabled ~= false then
                cases[#cases + 1] = cdef
            end
        end

        table.sort(cases, function(a, b)
            local pa, pb = tonumber(a.price) or 0, tonumber(b.price) or 0
            if pa ~= pb then return pa < pb end
            return tostring(a.name or '') < tostring(b.name or '')
        end)

        self.navbar:Clear()
        self.container:Clear()

        local this = self
        local allTab = self.navbar:AddTab({
            name  = 'ВСЕ КЕЙСЫ',
            icon  = 'https://i.imgur.com/JnNGizM.png',
            class = 'onyx.ScrollPanel',
            onBuild = function(content)
                this:SetupCaseList(content, cases)
            end
        })

        self.navbar:SelectTab(allTab, true)
        self.caseCountLbl:SetText(#cases .. ' кейсов')
        self.caseCountLbl:SizeToContents()
    end

    function PANEL:SetupCaseList(content, cases)
        if #cases == 0 then
            local emptyPnl = content:Add('Panel')
            emptyPnl:Dock(FILL)
            emptyPnl.Paint = function(p, w, h)
                draw.SimpleText('Загрузка списка кейсов...', 'CSF4.H1', w * .5, h * .35, colorGray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            return
        end

        local pnlCat = content:Add('onyx.Category')
        pnlCat:Dock(TOP)
        pnlCat:SetTitle('ДОСТУПНЫЕ КЕЙСЫ')
        pnlCat:SetSpace(0)
        pnlCat:SetInset(ST(10))
        pnlCat:DockMargin(0, 0, 0, ST(10))
        pnlCat:SetExpanded(true)
        pnlCat.m_iTextMargin = ST(10)
        pnlCat.m_bSquareCorners = true
        pnlCat.canvas.Paint = function(p, w, h)
            draw.RoundedBoxEx(8, 0, 0, w, h, colorPrimary, false, false, true, true)
        end

        local grid = pnlCat:Add('onyx.Grid')
        grid:Dock(TOP)
        grid:SetTall(0)
        grid:SetSpaceX(ST(5))
        grid:SetSpaceY(grid:GetSpaceX())
        grid:SetColumnCount(2)
        grid.category = pnlCat
        grid.parentContainer = content

        for _, cdef in ipairs(cases) do
            local card = grid:Add('cases.F4Item')
            card:SetTall(ST(55))
            card:SetCase(cdef)

            if card.Import then
                card:Import('click')
                card:Import('hovercolor')
                card:SetColorKey('colorBG')
                card:SetColorIdle(colorSecondary)
                card:SetColorHover(colorTertiary)
                if card.AddHoverSound then card:AddHoverSound() end
                if card.AddClickEffect then card:AddClickEffect() end
            end

            card.DoClick = function()
                self:EnablePreview(cdef)
            end
        end

        pnlCat:UpdateInTick()
        pnlCat:UpdateInTick(10)
        pnlCat:UpdateInTick(100)
    end

    onyx.gui.Register('cases.TabCases', PANEL)
end

-- 7. ТАБ 2: ИНВЕНТАРЬ ВЫИГРЫШЕЙ (БЕЗУПРЕЧНЫЙ ДИЗАЙН И ФИКС КНОПОК)
do
    local PANEL = {}

    function PANEL:Init()
        local header = self:Add('DPanel')
        header:Dock(TOP)
        header:SetTall(ST(46))
        header:DockMargin(0, 0, 0, ST(10))
        header.Paint = function(pnl, w, h)
            draw.RoundedBox(8, 0, 0, w, h, colorSecondary)
            draw.SimpleText('ВЫИГРАННЫЕ ПРЕДМЕТЫ', 'CSF4.H2', ST(14), h * .5, colorWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        local btnSellAll = header:Add('onyx.Button')
        btnSellAll:SetText('ПРОДАТЬ ВСЁ')
        btnSellAll:Dock(RIGHT)
        btnSellAll:DockMargin(0, ST(8), ST(8), ST(8))
        btnSellAll:SetWide(SW(120))
        btnSellAll:SetColorIdle(Color(160, 50, 50))
        btnSellAll:SetColorHover(Color(190, 60, 60))
        btnSellAll:SetMasking(true)
        btnSellAll:SetGradientColor(Color(120, 30, 30, 80))
        btnSellAll.DoClick = function()
            local rewards = (Client.Data and Client.Data.inventory and Client.Data.inventory.rewards) or {}
            local ids = {}
            for _, r in ipairs(rewards) do
                local iid = tonumber(r.inventory_id or r.id)
                if iid and iid > 0 then ids[#ids + 1] = iid end
            end
            if #ids > 0 then Client.SendSellMultiple(ids) end
        end

        local btnActAll = header:Add('onyx.Button')
        btnActAll:SetText('АКТИВИРОВАТЬ ВСЁ')
        btnActAll:Dock(RIGHT)
        btnActAll:DockMargin(0, ST(8), ST(8), ST(8))
        btnActAll:SetWide(SW(160))
        btnActAll:SetColorIdle(Color(45, 140, 60))
        btnActAll:SetColorHover(Color(55, 170, 75))
        btnActAll:SetMasking(true)
        btnActAll:SetGradientColor(Color(30, 100, 40, 80))
        btnActAll.DoClick = function()
            local rewards = (Client.Data and Client.Data.inventory and Client.Data.inventory.rewards) or {}
            local ids = {}
            for _, r in ipairs(rewards) do
                if not r.cant_activate then
                    local iid = tonumber(r.inventory_id or r.id)
                    if iid and iid > 0 then ids[#ids + 1] = iid end
                end
            end
            if #ids > 0 then
                Client.SendActivateMultiple(ids)
            else
                surface.PlaySound('buttons/button10.wav')
                chat.AddText(Color(255, 90, 90), '[Кейсы] ', Color(240, 240, 240), 'Нет доступных для активации предметов. Дубликаты уникальных перков можно только продать!')
            end
        end

        local btnRefresh = header:Add('onyx.Button')
        btnRefresh:SetText('ОБНОВИТЬ')
        btnRefresh:Dock(RIGHT)
        btnRefresh:DockMargin(0, ST(8), ST(8), ST(8))
        btnRefresh:SetWide(SW(100))
        btnRefresh:SetMasking(true)
        btnRefresh:SetGradientColor(colorGradient)
        btnRefresh.DoClick = function() Client.RequestSnapshot() end

        self.scroll = self:Add('onyx.ScrollPanel')
        self.scroll:Dock(FILL)
        self:Refresh()
        Client.RequestSnapshot()
    end

    function PANEL:Refresh()
        self.scroll:Clear()
        local rewards = (Client.Data and Client.Data.inventory and Client.Data.inventory.rewards) or {}

        if #rewards == 0 then
            local empty = self.scroll:Add('Panel')
            empty:Dock(TOP)
            empty:SetTall(ST(320))
            empty.Paint = function(p, w, h)
                draw.SimpleText('Инвентарь пуст', 'CSF4.H1', w * .5, ST(120), colorWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText('Откройте кейс на витрине, чтобы получить награду!', 'CSF4.Small', w * .5, ST(155), colorGray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            return
        end

        for _, item in ipairs(rewards) do
            local invID = tonumber(item.inventory_id or item.id) or 0
            local row = self.scroll:Add('Panel')
            row:Dock(TOP)
            row:SetTall(ST(64))
            row:DockMargin(0, 0, 0, ST(8))

            local sellPrice = tonumber(item.sell_price) or 0
            local cdef = (CasesSystem and CasesSystem.GetCase and CasesSystem.GetCase(item.case_id or ''))
            local caseDisplayName = (cdef and cdef.name) or item.case_name or item.case_id or 'Обычный'
            local col = (item.color and istable(item.color) and Color(item.color.r, item.color.g, item.color.b)) or (cdef and cdef.color and istable(cdef.color) and Color(cdef.color.r, cdef.color.g, cdef.color.b)) or colorAccent
            local cantAct = item.cant_activate == true

            row.Paint = function(p, w, h)
                draw.RoundedBox(8, 0, 0, w, h, colorSecondary)
                draw.RoundedBoxEx(8, 0, 0, ST(5), h, col, true, false, true, false)

                local name = item.name or 'Награда'
                draw.SimpleText(name, 'CSF4.Bold14', ST(68), ST(14), colorWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

                if cantAct then
                    local sub = 'Кейс: ' .. caseDisplayName .. '  •  Стоимость: ' .. FormatMoney(sellPrice) .. '  •  [ТОЛЬКО ПРОДАЖА]'
                    draw.SimpleText(sub, 'CSF4.Small', ST(68), ST(36), Color(255, 110, 110), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                else
                    local sub = 'Кейс: ' .. caseDisplayName .. '  •  Стоимость: ' .. FormatMoney(sellPrice)
                    draw.SimpleText(sub, 'CSF4.Small', ST(68), ST(36), Color(121, 255, 141), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
            end

            local iconBox = row:Add('Panel')
            iconBox:SetSize(ST(46), ST(46))
            iconBox:SetPos(ST(12), ST(9))
            iconBox.Paint = function(p, w, h)
                onyx.DrawCircle(w * .5, h * .5, h * .5, colorTertiary)
                local iconUrl = CasesSystem.GetRewardArtwork(item)
                if iconUrl then
                    local mat = GetWebOrLocalMat(iconUrl)
                    if mat then
                        surface.SetMaterial(mat)
                        surface.SetDrawColor(color_white)
                        surface.DrawTexturedRect(w * .15, h * .15, w * .7, h * .7)
                    end
                else
                    local fallback = Material('icon16/star.png')
                    surface.SetMaterial(fallback)
                    surface.SetDrawColor(color_white)
                    surface.DrawTexturedRect(w * .5 - ST(10), h * .5 - ST(10), ST(20), ST(20))
                end
                onyx.DrawOutlinedCircle(w * .5, h * .5, h * .5, 2, col)
            end

            local btnSell = row:Add('onyx.Button')
            btnSell:SetText('ПРОДАТЬ')
            btnSell:Font('Comfortaa Bold@13')
            btnSell:SetColorIdle(Color(160, 50, 50))
            btnSell:SetColorHover(Color(190, 60, 60))
            btnSell:SetMasking(true)
            btnSell:SetGradientColor(Color(120, 30, 30, 80))
            btnSell.DoClick = function()
                if invID > 0 then Client.SendSell(invID) end
            end

            local btnAct = row:Add('onyx.Button')
            if cantAct then
                btnAct:SetText('УЖЕ АКТИВНО')
                btnAct:Font('Comfortaa Bold@13')
                btnAct:SetColorIdle(Color(55, 57, 65))
                btnAct:SetColorHover(Color(65, 68, 77))
                btnAct.DoClick = function()
                    surface.PlaySound('buttons/button10.wav')
                    chat.AddText(Color(255, 90, 90), '[Кейсы] ', Color(240, 240, 240), item.cant_activate_reason or 'Этот уникальный перк уже активен! Этот предмет можно только продать.')
                end
            else
                btnAct:SetText('АКТИВИРОВАТЬ')
                btnAct:Font('Comfortaa Bold@13')
                btnAct:SetColorIdle(colorAccent)
                btnAct:SetColorHover(onyx.OffsetColor(colorAccent, 25))
                btnAct:SetMasking(true)
                btnAct:SetGradientColor(colorGradient)
                btnAct.DoClick = function()
                    if invID > 0 then Client.SendActivate(invID) end
                end
            end

            row.PerformLayout = function(p, w, h)
                local bw1 = SW(100)
                local bw2 = SW(130)
                local bh  = ST(34)
                local by  = (h - bh) * .5

                btnAct:SetSize(bw2, bh)
                btnAct:SetPos(w - bw2 - ST(14), by)

                btnSell:SetSize(bw1, bh)
                btnSell:SetPos(w - bw2 - ST(14) - bw1 - ST(8), by)
            end
        end
    end

    onyx.gui.Register('cases.TabInventory', PANEL)
end

-- 8. ТАБ 3: ПОПОЛНЕНИЕ БАЛАНСА
do
    local PANEL = {}

    function PANEL:Init()
        local this = self
        self.amount = 100

        local bal = self:Add('DPanel')
        bal:Dock(TOP)
        bal:SetTall(ST(90))
        bal:DockMargin(0, 0, 0, ST(16))
        bal.Paint = function(pnl, w, h)
            draw.RoundedBox(8, 0, 0, w, h, colorSecondary)
            draw.SimpleText('ВАШ БАЛАНС ДОНАТ-ВАЛЮТЫ', 'CSF4.SmallB', ST(16), ST(14), colorGray, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(FormatMoney(GetIGSBalance()), 'CSF4.Bal', ST(16), ST(36), colorCanAfford, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        bal.Think = function(pnl)
            if (pnl.nextThink or 0) > CurTime() then return end
            pnl.nextThink = CurTime() + .4
            pnl:InvalidateLayout()
        end

        local lblP = self:Add('onyx.Label')
        lblP:Dock(TOP)
        lblP:SetText('БЫСТРОЕ ПОПОЛНЕНИЕ')
        lblP:Font('Comfortaa Bold@16')
        lblP:SetTall(ST(24))
        lblP:DockMargin(0, 0, 0, ST(10))
        lblP:SetContentAlignment(4)

        local presets = self:Add('Panel')
        presets:Dock(TOP)
        presets:DockMargin(0, 0, 0, ST(16))
        presets.btns = {}
        presets.Paint = function() end
        presets.PerformLayout = function(pnl, w, h)
            local cols = 3
            local sp = ST(8)
            local bw = (w - sp * (cols - 1)) / cols
            local bh = ST(44)
            local col, y = 0, 0
            for _, btn in ipairs(pnl.btns) do
                btn:SetPos(col * (bw + sp), y)
                btn:SetSize(bw, bh)
                col = col + 1
                if col >= cols then col = 0; y = y + bh + sp end
            end
            if col > 0 then y = y + bh + sp end
            pnl:SetTall(y)
        end

        for _, val in ipairs({ 100, 300, 500, 1000, 2500, 5000 }) do
            local btn = presets:Add('onyx.Button')
            btn:SetText(FormatMoney(val))
            btn:Font('Comfortaa Bold@16')
            btn:SetColorIdle(colorAccent)
            btn:SetColorHover(onyx.OffsetColor(colorAccent, 25))
            btn:SetMasking(true)
            btn:SetGradientColor(colorGradient)
            btn:SetGradientDirection(RIGHT)
            btn.DoClick = function()
                this.amount = val
                if IsValid(this.entryCustom) then this.entryCustom:SetValue(tostring(val)) end
            end
            presets.btns[#presets.btns + 1] = btn
        end

        local lblC = self:Add('onyx.Label')
        lblC:Dock(TOP)
        lblC:SetText('СВОЯ СУММА')
        lblC:Font('Comfortaa Bold@16')
        lblC:SetTall(ST(24))
        lblC:DockMargin(0, 0, 0, ST(10))
        lblC:SetContentAlignment(4)

        local inp = self:Add('Panel')
        inp:Dock(TOP)
        inp:SetTall(ST(44))
        inp.Paint = function() end

        self.entryCustom = inp:Add('onyx.TextEntry')
        self.entryCustom:Dock(LEFT)
        self.entryCustom:SetWide(SW(200))
        self.entryCustom:SetPlaceholderText('Сумма в рублях...')
        self.entryCustom.OnValueChange = function(pnl, val)
            this.amount = math.max(0, math.floor(tonumber(val) or 0))
        end
        self.entryCustom.OnEnter = function() this:Proceed() end
        self.entryCustom:SetValue(tostring(self.amount))

        local btnP = inp:Add('onyx.Button')
        btnP:SetText('ПЕРЕЙТИ К ОПЛАТЕ')
        btnP:Font('Comfortaa Bold@16')
        btnP:Dock(FILL)
        btnP:DockMargin(ST(10), 0, 0, 0)
        btnP:SetColorIdle(colorAccent)
        btnP:SetColorHover(onyx.OffsetColor(colorAccent, 25))
        btnP:SetMasking(true)
        btnP:SetGradientColor(colorGradient)
        btnP:SetGradientDirection(RIGHT)
        btnP.DoClick = function() this:Proceed() end
    end

    function PANEL:Proceed()
        local amount = math.floor(tonumber(self.amount) or 0)
        local frame = self
        while IsValid(frame) and not frame.Toast do frame = frame:GetParent() end

        if amount < 10 then
            if IsValid(frame) and frame.Toast then frame:Toast('Минимум: 10 ₽', colorCannotAfford) end
            return
        end

        if IsValid(frame) and frame.Toast then frame:Toast('Генерация ссылки...', colorWhite) end
        if istable(IGS) and isfunction(IGS.GetPaymentURL) then
            IGS.GetPaymentURL(amount, function(url)
                if isstring(url) and url ~= '' then
                    gui.OpenURL(url)
                    if IsValid(frame) and frame.Toast then frame:Toast('Оплата открыта в браузере', colorCanAfford) end
                else
                    if IsValid(frame) and frame.Toast then frame:Toast('Не удалось получить ссылку', colorCannotAfford) end
                end
            end)
        else
            if IsValid(frame) and frame.Toast then frame:Toast('Модуль IGS недоступен', colorCannotAfford) end
        end
    end

    onyx.gui.Register('cases.TabTopUp', PANEL)
end

-- 9. ТАБ 4: НАСТРОЙКИ UI
do
    local PANEL = {}

    function PANEL:Init()
        self.scroll = self:Add('onyx.ScrollPanel')
        self.scroll:Dock(FILL)

        local card = self.scroll:Add('Panel')
        card:Dock(TOP)
        card:SetTall(ST(320))
        card:DockMargin(0, 0, 0, ST(10))
        card.Paint = function(pnl, w, h)
            draw.RoundedBox(10, 0, 0, w, h, colorOutline)
            draw.RoundedBox(10, 1, 1, w - 2, h - 2, colorSecondary)
            draw.SimpleText('НАСТРОЙКИ СИСТЕМЫ КЕЙСОВ', 'CSF4.H1', ST(20), ST(20), colorWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText('Управление звуками, рулеткой и оповещениями', 'CSF4.Small', ST(20), ST(46), colorGray, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            surface.SetDrawColor(colorLine)
            surface.DrawRect(ST(20), ST(72), w - ST(40), 1)
        end

        local row1 = card:Add('Panel')
        row1:Dock(TOP)
        row1:SetTall(ST(50))
        row1:DockMargin(ST(20), ST(85), ST(20), ST(10))
        row1.Paint = function(pnl, w, h)
            draw.RoundedBox(6, 0, 0, w, h, colorPrimary)
        end
        local tgl1 = row1:Add('onyx.TogglerLabel')
        tgl1:Dock(FILL)
        tgl1:DockMargin(ST(12), ST(6), ST(12), ST(6))
        tgl1:SetText('Быстрый режим (без рулетки)')
        tgl1:Font('Comfortaa@14')
        local cv1 = GetConVar('cases_system_fast_open') or CreateClientConVar('cases_system_fast_open', '0', true, false)
        tgl1:SetChecked(cv1:GetBool(), true)
        tgl1:On('OnChange', function(_, val)
            RunConsoleCommand('cases_system_fast_open', val and '1' or '0')
        end)

        local row2 = card:Add('Panel')
        row2:Dock(TOP)
        row2:SetTall(ST(50))
        row2:DockMargin(ST(20), 0, ST(20), ST(10))
        row2.Paint = function(pnl, w, h)
            draw.RoundedBox(6, 0, 0, w, h, colorPrimary)
        end
        local tgl2 = row2:Add('onyx.TogglerLabel')
        tgl2:Dock(FILL)
        tgl2:DockMargin(ST(12), ST(6), ST(12), ST(6))
        tgl2:SetText('Оповещения о выигрышах других игроков')
        tgl2:Font('Comfortaa@14')
        local cv2 = GetConVar('cases_system_rare_notify') or CreateClientConVar('cases_system_rare_notify', '1', true, false)
        tgl2:SetChecked(cv2:GetBool(), true)
        tgl2:On('OnChange', function(_, val)
            RunConsoleCommand('cases_system_rare_notify', val and '1' or '0')
        end)

        local row3 = card:Add('Panel')
        row3:Dock(TOP)
        row3:SetTall(ST(70))
        row3:DockMargin(ST(20), 0, ST(20), ST(10))
        row3.Paint = function(pnl, w, h)
            draw.RoundedBox(6, 0, 0, w, h, colorPrimary)
            draw.SimpleText('Громкость звуковых эффектов', 'CSF4.Bold14', ST(14), ST(12), colorWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            local vol = math.Round((GetConVar('cases_system_ui_volume') and GetConVar('cases_system_ui_volume'):GetFloat() or 0.8) * 100)
            draw.SimpleText(vol .. '%', 'CSF4.Bold14', w - ST(14), ST(12), colorAccent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end

        local cvVol = GetConVar('cases_system_ui_volume') or CreateClientConVar('cases_system_ui_volume', '0.8', true, false)
        local curVol = math.Clamp(math.Round(cvVol:GetFloat() * 100), 0, 100)

        local slider3 = CreateOnyxSlider(row3, 0, 100, curVol, function(val)
            RunConsoleCommand('cases_system_ui_volume', tostring(val / 100))
        end, colorAccent)
        slider3:Dock(BOTTOM)
        slider3:SetTall(ST(24))
        slider3:DockMargin(ST(14), 0, ST(14), ST(10))

        -- Настройки перка автозакрытия дверей (Кейс «Недвижимость»)
        local cardDoor = self.scroll:Add('Panel')
        cardDoor:Dock(TOP)
        cardDoor:SetTall(ST(210))
        cardDoor:DockMargin(0, 0, 0, ST(10))
        cardDoor.Paint = function(pnl, w, h)
            draw.RoundedBox(10, 0, 0, w, h, colorOutline)
            draw.RoundedBox(10, 1, 1, w - 2, h - 2, colorSecondary)
            draw.SimpleText('ПЕРК «АВТОЗАКРЫТИЕ ДВЕРЕЙ»', 'CSF4.H1', ST(20), ST(20), colorWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText('Настройка работы перка автозакрытия дверей из кейса «Недвижимость»', 'CSF4.Small', ST(20), ST(46), colorGray, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            surface.SetDrawColor(colorLine)
            surface.DrawRect(ST(20), ST(72), w - ST(40), 1)
        end

        local cvDoorEnabled = GetConVar('cases_autoclose_enabled') or CreateClientConVar('cases_autoclose_enabled', '1', true, true)
        local cvDoorDelay = GetConVar('cases_autoclose_delay') or CreateClientConVar('cases_autoclose_delay', '4', true, true)

        local rowD1 = cardDoor:Add('Panel')
        rowD1:Dock(TOP)
        rowD1:SetTall(ST(50))
        rowD1:DockMargin(ST(20), ST(85), ST(20), ST(10))
        rowD1.Paint = function(pnl, w, h)
            draw.RoundedBox(6, 0, 0, w, h, colorPrimary)
        end
        local tglDoor = rowD1:Add('onyx.TogglerLabel')
        tglDoor:Dock(FILL)
        tglDoor:DockMargin(ST(12), ST(6), ST(12), ST(6))
        tglDoor:SetText('Автозакрытие дверей (при наличии перка)')
        tglDoor:Font('Comfortaa@14')
        tglDoor:SetChecked(cvDoorEnabled:GetBool(), true)
        tglDoor:On('OnChange', function(_, val)
            RunConsoleCommand('cases_autoclose_enabled', val and '1' or '0')
        end)

        local rowD2 = cardDoor:Add('Panel')
        rowD2:Dock(TOP)
        rowD2:SetTall(ST(70))
        rowD2:DockMargin(ST(20), 0, ST(20), ST(10))
        local curDelay = math.Clamp(math.Round(cvDoorDelay:GetFloat()), 1, 15)
        rowD2.Paint = function(pnl, w, h)
            draw.RoundedBox(6, 0, 0, w, h, colorPrimary)
            draw.SimpleText('Задержка автозакрытия', 'CSF4.Bold14', ST(14), ST(12), colorWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            local dVal = math.Clamp(math.Round(cvDoorDelay:GetFloat()), 1, 15)
            draw.SimpleText(dVal .. ' сек.', 'CSF4.Bold14', w - ST(14), ST(12), colorAccent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end

        local sliderDoor = CreateOnyxSlider(rowD2, 1, 15, curDelay, function(val)
            RunConsoleCommand('cases_autoclose_delay', tostring(math.Round(val)))
        end, colorAccent)
        sliderDoor:Dock(BOTTOM)
        sliderDoor:SetTall(ST(24))
        sliderDoor:DockMargin(ST(14), 0, ST(14), ST(10))
    end

    onyx.gui.Register('cases.TabSettings', PANEL)
end

-- 10. ТАБ 5: УПРАВЛЕНИЕ (АДМИН)
do
    local PANEL = {}

    function PANEL:Init()
        local isUserAdmin = LocalPlayer():IsSuperAdmin() or (LocalPlayer().GetUserGroup and string.lower(LocalPlayer():GetUserGroup()) == 'superadmin')

        if not isUserAdmin then
            local lbl = self:Add('onyx.Label')
            lbl:Dock(FILL)
            lbl:SetText('Доступно только администраторам')
            lbl:Font('Comfortaa Bold@18')
            lbl:SetContentAlignment(5)
            return
        end

        local card = self:Add('Panel')
        card.Paint = function(pnl, w, h)
            draw.RoundedBox(10, 0, 0, w, h, colorOutline)
            draw.RoundedBox(10, 1, 1, w - 2, h - 2, colorSecondary)
            draw.SimpleText('ПАНЕЛЬ УПРАВЛЕНИЯ КЕЙСАМИ', 'CSF4.H1', ST(16), ST(18), colorWhite, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText('Редактирование кейсов, наград и шансов выпадения', 'CSF4.Small', ST(16), ST(42), colorGray, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end

        self.PerformLayout = function(pnl, w, h)
            local cardW = math.min(ST(500), w - ST(40))
            local cardH = ST(180)
            card:SetPos((w - cardW) * .5, ST(60))
            card:SetSize(cardW, cardH)
        end

        local btnOpenAdmin = card:Add('onyx.Button')
        btnOpenAdmin:SetText('ОТКРЫТЬ РЕДАКТОР КЕЙСОВ')
        btnOpenAdmin:SetPos(ST(16), ST(90))
        btnOpenAdmin:SetSize(ST(468), ST(44))
        btnOpenAdmin:SetColorIdle(colorAccent)
        btnOpenAdmin:SetColorHover(onyx.OffsetColor(colorAccent, 25))
        btnOpenAdmin:SetMasking(true)
        btnOpenAdmin:SetGradientColor(colorGradient)
        btnOpenAdmin.DoClick = function()
            if Admin and Admin.Open then Admin.Open() end
        end
    end

    onyx.gui.Register('cases.TabAdmin', PANEL)
end

-- 11. РУЛЕТКА ОТКРЫТИЯ И ОКНО ВЫИГРЫША
local function PlayOnyxRouletteAnimation(caseDef, wonRewards)
    if IsValid(Renderer.OpeningOverlay) then Renderer.OpeningOverlay:Remove() end
    if IsValid(Renderer.WinModal) then Renderer.WinModal:Remove() end

    local wonFirst = (wonRewards and wonRewards[1]) or nil
    if not wonFirst then return end

    if isFastOpen() then
        Renderer.ShowWinModal(wonRewards, caseDef and caseDef.id)
        return
    end

    local count = #wonRewards

    local overlay = vgui.Create('EditablePanel', vgui.GetWorldPanel())
    overlay:SetPos(0, 0)
    overlay:SetSize(ScrW(), ScrH())
    overlay:MakePopup()
    overlay:SetZPos(3000)
    Renderer.OpeningOverlay = overlay

    local rw = math.min(ST(980), math.floor(ScrW() * 0.90))
    local rewards = (caseDef and caseDef.rewards and #caseDef.rewards > 0) and caseDef.rewards or wonRewards
    local totalChance = 0
    for _, r in ipairs(rewards) do totalChance = totalChance + (tonumber(r.chance) or 1) end

    -- Если кейсов до 5, то они идут в одну линию (1 колонка). Если больше 5 (6..10), то в 2 колонки
    local useTwoCols = (count > 5)
    local numRows = useTwoCols and math.ceil(count / 2) or count
    local colGap = ST(18)
    local colW = useTwoCols and math.floor((rw - colGap) / 2) or rw

    local laneH = (count == 1) and ST(160) or ((count == 2) and ST(125) or ((count == 3) and ST(100) or ((count == 4) and ST(85) or ((count == 5) and ST(72) or ((numRows <= 3) and ST(90) or ((numRows <= 4) and ST(78) or ST(68)))))))
    local itemW = (count == 1) and ST(120) or ((count <= 3) and ST(88) or ((count <= 5) and ST(70) or ((numRows <= 3) and ST(76) or ST(66))))
    local itemH = laneH - ST(6)
    local itemGap = ST(6)
    local stepW = itemW + itemGap
    local laneGap = ST(5)

    local totalLanesH = numRows * laneH + (numRows - 1) * laneGap
    local rh = totalLanesH + ST(60)

    -- Generate strips for each opened case
    local lanes = {}
    local winnerIndex = 38

    for k = 1, count do
        local stripItems = {}
        local winR = wonRewards[k] or wonFirst
        for i = 1, 46 do
            if i == winnerIndex then
                stripItems[i] = winR
            else
                stripItems[i] = rewards[math.random(#rewards)]
            end
        end
        local targetX = (winnerIndex - 1) * stepW + (itemW * .5) + math.random(-ST(10), ST(10)) - (colW * .5)
        lanes[k] = {
            stripItems = stripItems,
            targetX = targetX,
            winR = winR
        }
    end

    local startTime = CurTime()
    local animDuration = 4.2
    local lastTickSoundIndex = -1

    playUISound('weapons/ar2/ar2_empty.wav')

    local caseTitle = string.upper(caseDef and (caseDef.name or caseDef.id) or 'КЕЙС')
    if count > 1 then
        caseTitle = caseTitle .. ' (' .. count .. ' ШТ.)'
    end

    overlay.Paint = function(pnl, w, h)
        local rx = math.floor((w - rw) * .5)
        local ry = math.floor((h - rh) * .5)

        surface.SetDrawColor(15, 17, 23, 240)
        surface.DrawRect(0, 0, w, h)

        -- Header
        draw.SimpleText('ОТКРЫТИЕ: ' .. caseTitle, 'CSF4.Title', w * .5, ry + ST(12), colorGold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local elapsed = CurTime() - startTime
        local frac = math.Clamp(elapsed / animDuration, 0, 1)
        local ease = 1 - math.pow(1 - frac, 4.0)

        local startY = ry + ST(40)

        local function drawLane(lane, lx, ly)
            local currentX = lane.targetX * ease

            -- Lane Background
            draw.RoundedBox(8, lx, ly, colW, laneH, colorOutline)
            draw.RoundedBox(8, lx + 1, ly + 1, colW - 2, laneH - 2, colorPrimary)

            local startIdx = math.max(1, math.floor((currentX - ST(80)) / stepW))
            local endIdx = math.min(#lane.stripItems, math.ceil((currentX + colW + ST(80)) / stepW) + 1)

            render.SetScissorRect(lx + 2, ly + 2, lx + colW - 2, ly + laneH - 2, true)

            for i = startIdx, endIdx do
                local it = lane.stripItems[i]
                if not it then continue end

                local ix = lx - currentX + (i - 1) * stepW
                local iy = ly + (laneH - itemH) * .5

                local isExcl = (it.owned == true)
                local col = isExcl and Color(65, 68, 78) or GetRewardColor(it, totalChance)
                draw.RoundedBox(6, ix, iy, itemW, itemH, colorOutline)
                draw.RoundedBox(6, ix + 1, iy + 1, itemW - 2, itemH - 2, isExcl and Color(20, 21, 26, 240) or colorSecondary)
                draw.RoundedBoxEx(6, ix + 1, iy + itemH - ST(4), itemW - 2, ST(4), col, false, false, true, true)

                local iconUrl = CasesSystem.GetRewardArtwork(it) or GetCaseIcon(caseDef)
                local iconSz = (count == 1) and ST(54) or math.floor(itemH * 0.62)
                local iconY = (count == 1) and (iy + ST(10)) or (iy + (itemH - iconSz) * .5 - ST(2))

                if iconUrl then
                    local mat = GetWebOrLocalMat(iconUrl)
                    if mat then
                        surface.SetMaterial(mat)
                        surface.SetDrawColor(isExcl and Color(120, 120, 120, 130) or color_white)
                        surface.DrawTexturedRect(ix + (itemW - iconSz) * .5, iconY, iconSz, iconSz)
                    end
                end

                if count == 1 then
                    if isExcl then
                        draw.SimpleText(it.name or 'Награда', 'CSF4.SmallB', ix + itemW * .5, iy + itemH - ST(22), Color(135, 138, 150), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                        draw.SimpleText('ИСКЛЮЧЕНО', 'CSF4.ExcludedBadge', ix + itemW * .5, iy + itemH - ST(10), Color(255, 110, 110), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    else
                        draw.SimpleText(it.name or 'Награда', 'CSF4.SmallB', ix + itemW * .5, iy + itemH - ST(20), colorWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
            end

            render.SetScissorRect(0, 0, 0, 0, false)

            -- Left & Right gradient edge fades
            onyx.DrawMatGradient(lx + 2, ly + 2, ST(50), laneH - 4, LEFT, colorPrimary)
            onyx.DrawMatGradient(lx + colW - ST(52), ly + 2, ST(50), laneH - 4, RIGHT, colorPrimary)
        end

        -- Sound tick from lane 1
        if lanes[1] then
            local currentX1 = lanes[1].targetX * ease
            local currentItemIdx = math.floor((currentX1 + colW * .5) / stepW)
            if currentItemIdx ~= lastTickSoundIndex and currentItemIdx > 0 and frac < 0.98 then
                lastTickSoundIndex = currentItemIdx
                playUISound('buttons/button14.wav')
            end
        end

        if not useTwoCols then
            -- Single Column
            local ly = startY
            for k = 1, count do
                drawLane(lanes[k], rx, ly)
                ly = ly + laneH + laneGap
            end

            -- Unified Center Laser
            local cx = rx + colW * .5
            local laserStartY = startY - ST(2)
            local laserEndY = ly - laneGap + ST(2)

            surface.SetDrawColor(colorGold)
            draw.NoTexture()
            surface.DrawPoly({
                { x = cx - ST(8), y = laserStartY },
                { x = cx + ST(8), y = laserStartY },
                { x = cx, y = laserStartY + ST(12) }
            })
            surface.DrawPoly({
                { x = cx - ST(8), y = laserEndY },
                { x = cx + ST(8), y = laserEndY },
                { x = cx, y = laserEndY - ST(12) }
            })
            surface.DrawRect(cx - 1, laserStartY + ST(10), 2, (laserEndY - laserStartY) - ST(20))
        else
            -- 2 Columns (Side-by-Side)
            local col1X = rx
            local col2X = rx + colW + colGap

            local col1Count = numRows
            local col2Count = count - numRows

            -- Left Column Lanes
            for row = 1, col1Count do
                local laneIdx = row
                local ly = startY + (row - 1) * (laneH + laneGap)
                if lanes[laneIdx] then
                    drawLane(lanes[laneIdx], col1X, ly)
                end
            end

            -- Right Column Lanes
            for row = 1, col2Count do
                local laneIdx = col1Count + row
                local ly = startY + (row - 1) * (laneH + laneGap)
                if lanes[laneIdx] then
                    drawLane(lanes[laneIdx], col2X, ly)
                end
            end

            local maxRows = math.max(col1Count, col2Count)
            local laserStartY = startY - ST(2)
            local laserEndY = startY + maxRows * laneH + (maxRows - 1) * laneGap + ST(2)

            -- Left Column Center Laser
            local cx1 = col1X + colW * .5
            surface.SetDrawColor(colorGold)
            draw.NoTexture()
            surface.DrawPoly({
                { x = cx1 - ST(7), y = laserStartY },
                { x = cx1 + ST(7), y = laserStartY },
                { x = cx1, y = laserStartY + ST(11) }
            })
            surface.DrawPoly({
                { x = cx1 - ST(7), y = laserEndY },
                { x = cx1 + ST(7), y = laserEndY },
                { x = cx1, y = laserEndY - ST(11) }
            })
            surface.DrawRect(cx1 - 1, laserStartY + ST(9), 2, (laserEndY - laserStartY) - ST(18))

            -- Right Column Center Laser
            local cx2 = col2X + colW * .5
            surface.SetDrawColor(colorGold)
            draw.NoTexture()
            surface.DrawPoly({
                { x = cx2 - ST(7), y = laserStartY },
                { x = cx2 + ST(7), y = laserStartY },
                { x = cx2, y = laserStartY + ST(11) }
            })
            surface.DrawPoly({
                { x = cx2 - ST(7), y = laserEndY },
                { x = cx2 + ST(7), y = laserEndY },
                { x = cx2, y = laserEndY - ST(11) }
            })
            surface.DrawRect(cx2 - 1, laserStartY + ST(9), 2, (laserEndY - laserStartY) - ST(18))
        end
    end

    timer.Simple(animDuration + 0.35, function()
        if IsValid(overlay) then overlay:Remove() end
        Renderer.ShowWinModal(wonRewards, caseDef and caseDef.id)
    end)
end

function Renderer.ShowWinModal(wonRewards, caseID)
    if IsValid(Renderer.WinModal) then Renderer.WinModal:Remove() end

    wonRewards = wonRewards or {}
    local count = #wonRewards
    if count == 0 then return end

    playUISound('garrysmod/save_load1.wav')

    local modal = vgui.Create('EditablePanel', vgui.GetWorldPanel())
    modal:SetPos(0, 0)
    modal:SetSize(ScrW(), ScrH())
    modal:MakePopup()
    modal:SetZPos(3100)
    modal:SetAlpha(0)
    modal:AlphaTo(255, 0.18, 0)
    Renderer.WinModal = modal

    local remainingCases = caseID and GetOwnedCount(caseID) or 0

    local totalSell = 0
    local allInvIDs = {}
    for _, r in ipairs(wonRewards) do
        local sp = tonumber(r.sell_price) or 0
        totalSell = totalSell + sp
        local invID = tonumber(r.inventory_id or r.id) or 0
        if invID > 0 then allInvIDs[#allInvIDs + 1] = invID end
    end

    if count == 1 then
        local wonFirst = wonRewards[1]
        local mw = ST(480)
        local mh = ST(420)
        local col = GetRewardColor(wonFirst, 100)
        local rarity = GetRewardRarity(wonFirst, 100)
        local invID = tonumber(wonFirst.inventory_id or wonFirst.id) or 0
        local sellPrice = tonumber(wonFirst.sell_price) or 0

        modal.Paint = function(pnl, w, h)
            local mx = math.floor((w - mw) * .5)
            local my = math.floor((h - mh) * .5)

            surface.SetDrawColor(0, 0, 0, 220)
            surface.DrawRect(0, 0, w, h)

            -- Dialog background
            draw.RoundedBox(12, mx, my, mw, mh, colorOutline)
            draw.RoundedBox(12, mx + 1, my + 1, mw - 2, mh - 2, colorPrimary)

            -- Top Title
            draw.SimpleText('ПОЗДРАВЛЯЕМ С ВЫИГРЫШЕМ!', 'CSF4.Title', mx + mw * .5, my + ST(24), colorGold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Central Showcase Card
            local cardW = ST(220)
            local cardH = ST(180)
            local cx = mx + (mw - cardW) * .5
            local cy = my + ST(52)

            draw.RoundedBox(10, cx, cy, cardW, cardH, colorOutline)
            draw.RoundedBox(10, cx + 1, cy + 1, cardW - 2, cardH - 2, colorSecondary)
            draw.RoundedBoxEx(10, cx + 1, cy + cardH - ST(5), cardW - 2, ST(5), col, false, false, true, true)

            -- Rarity Badge Box
            local badgeW = ST(120)
            local badgeH = ST(20)
            local bx = cx + (cardW - badgeW) * .5
            local by = cy + ST(10)
            draw.RoundedBox(4, bx, by, badgeW, badgeH, ColorAlpha(col, 35))
            draw.SimpleText(rarity.name or 'Обычное', 'CSF4.SmallB', bx + badgeW * .5, by + badgeH * .5, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Item Icon
            local iconUrl = CasesSystem.GetRewardArtwork(wonFirst)
            if iconUrl then
                local mat = GetWebOrLocalMat(iconUrl)
                if mat then
                    surface.SetMaterial(mat)
                    surface.SetDrawColor(color_white)
                    surface.DrawTexturedRect(cx + (cardW - ST(72)) * .5, cy + ST(36), ST(72), ST(72))
                end
            end

            -- Item Name
            draw.SimpleText(wonFirst.name or 'Награда', 'CSF4.Bold14', cx + cardW * .5, cy + cardH - ST(26), colorWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Quick sell info
            if wonFirst.cant_activate then
                draw.SimpleText('Перк уже активен: предмет можно только продать!', 'CSF4.Small', mx + mw * .5, cy + cardH + ST(10), Color(255, 110, 110), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                if sellPrice > 0 then
                    draw.SimpleText('Цена быстрой продажи: ' .. FormatMoney(sellPrice), 'CSF4.Small', mx + mw * .5, cy + cardH + ST(28), colorCanAfford, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            elseif sellPrice > 0 then
                draw.SimpleText('Цена быстрой продажи: ' .. FormatMoney(sellPrice), 'CSF4.Small', mx + mw * .5, cy + cardH + ST(18), colorCanAfford, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        local btnClose = modal:Add('DButton')
        btnClose:SetText('✕')
        btnClose:SetFont('CSF4.Bold14')
        btnClose:SetTextColor(colorGray)
        btnClose:SetSize(ST(26), ST(26))
        btnClose.Paint = function() end
        btnClose.DoClick = function()
            modal:Remove()
            if IsValid(Renderer.Frame) and Renderer.Frame.activeTabContent and Renderer.Frame.activeTabContent.Refresh then
                Renderer.Frame.activeTabContent:Refresh()
            end
        end

        local btnH = ST(38)

        local btnClaim = modal:Add('onyx.Button')
        btnClaim:SetText('В ИНВЕНТАРЬ')
        btnClaim:Font('Comfortaa Bold@13')
        btnClaim:SetColorIdle(Color(45, 140, 60))
        btnClaim:SetColorHover(Color(55, 170, 75))
        btnClaim:SetMasking(true)
        btnClaim:SetGradientColor(Color(30, 100, 40, 80))
        btnClaim.DoClick = function()
            modal:Remove()
            if IsValid(Renderer.Frame) and Renderer.Frame.activeTabContent and Renderer.Frame.activeTabContent.Refresh then
                Renderer.Frame.activeTabContent:Refresh()
            end
        end

        local btnSell = modal:Add('onyx.Button')
        btnSell:SetText('ПРОДАТЬ (' .. FormatMoney(sellPrice) .. ')')
        btnSell:Font('Comfortaa Bold@13')
        btnSell:SetColorIdle(Color(160, 50, 50))
        btnSell:SetColorHover(Color(190, 60, 60))
        btnSell:SetMasking(true)
        btnSell:SetGradientColor(Color(120, 30, 30, 80))
        btnSell.DoClick = function()
            if invID > 0 then Client.SendSell(invID) end
            modal:Remove()
            if IsValid(Renderer.Frame) and Renderer.Frame.activeTabContent and Renderer.Frame.activeTabContent.Refresh then
                Renderer.Frame.activeTabContent:Refresh()
            end
        end

        local btnAgain = nil
        if remainingCases > 0 and caseID then
            btnAgain = modal:Add('onyx.Button')
            btnAgain:SetText('ЕЩЁ (' .. remainingCases .. ')')
            btnAgain:Font('Comfortaa Bold@13')
            btnAgain:SetColorIdle(colorAccent)
            btnAgain:SetColorHover(onyx.OffsetColor(colorAccent, 25))
            btnAgain:SetMasking(true)
            btnAgain:SetGradientColor(colorGradient)
            btnAgain.DoClick = function()
                modal:Remove()
                Client.SendOpen(caseID, 1)
            end
        end

        modal.PerformLayout = function(pnl, w, h)
            local mx = math.floor((w - mw) * .5)
            local my = math.floor((h - mh) * .5)
            local btnY = my + mh - ST(62)

            btnClose:SetPos(mx + mw - ST(36), my + ST(10))

            if IsValid(btnAgain) then
                local btnW = ST(135)
                local gap = ST(10)
                local totalW = btnW * 3 + gap * 2
                local startX = mx + (mw - totalW) * .5

                btnClaim:SetPos(startX, btnY)
                btnClaim:SetSize(btnW, btnH)

                btnSell:SetPos(startX + btnW + gap, btnY)
                btnSell:SetSize(btnW, btnH)

                btnAgain:SetPos(startX + (btnW + gap) * 2, btnY)
                btnAgain:SetSize(btnW, btnH)
            else
                local btnW = ST(200)
                local gap = ST(16)
                local totalW = btnW * 2 + gap
                local startX = mx + (mw - totalW) * .5

                btnClaim:SetPos(startX, btnY)
                btnClaim:SetSize(btnW, btnH)
                btnClaim:SetFont('Comfortaa Bold@14')

                btnSell:SetPos(startX + btnW + gap, btnY)
                btnSell:SetSize(btnW, btnH)
                btnSell:SetFont('Comfortaa Bold@14')
            end
        end
    else
        -- MULTI-ITEM WIN MODAL (МАКСИМУМ 2 РЯДА В ВЫСОТУ: 5 КОЛОНОК ДЛЯ 10 ПРЕДМЕТОВ)
        local mw = math.min(ST(960), math.floor(ScrW() * 0.94))
        local mh = math.min(ST(480), math.floor(ScrH() * 0.88))

        modal.Paint = function(pnl, w, h)
            local mx = math.floor((w - mw) * .5)
            local my = math.floor((h - mh) * .5)

            surface.SetDrawColor(0, 0, 0, 225)
            surface.DrawRect(0, 0, w, h)

            -- Dialog background
            draw.RoundedBox(12, mx, my, mw, mh, colorPrimary)

            -- Top Title
            draw.SimpleText('ПОЗДРАВЛЯЕМ С ВЫИГРЫШЕМ! (' .. count .. ' ШТ.)', 'CSF4.Title', mx + mw * .5, my + ST(22), colorGold, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText('Сумма быстрой продажи всех предметов: ' .. FormatMoney(totalSell), 'CSF4.Small', mx + mw * .5, my + ST(44), colorCanAfford, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local btnClose = modal:Add('DButton')
        btnClose:SetText('✕')
        btnClose:SetFont('CSF4.Bold14')
        btnClose:SetTextColor(colorGray)
        btnClose:SetSize(ST(26), ST(26))
        btnClose.Paint = function() end
        btnClose.DoClick = function()
            modal:Remove()
            if IsValid(Renderer.Frame) and Renderer.Frame.activeTabContent and Renderer.Frame.activeTabContent.Refresh then
                Renderer.Frame.activeTabContent:Refresh()
            end
        end

        local scroll = modal:Add('onyx.ScrollPanel')
        local grid = scroll:Add('onyx.Grid')
        grid:Dock(TOP)
        grid:SetSpaceX(ST(8))
        grid:SetSpaceY(ST(8))

        local cols = 5
        if count <= 4 then
            cols = count
        elseif count <= 5 then
            cols = 5
        elseif count <= 8 then
            cols = 4
        else
            cols = 5
        end
        grid:SetColumnCount(cols)

        for _, item in ipairs(wonRewards) do
            local col = GetRewardColor(item, 100)
            local invID = tonumber(item.inventory_id or item.id) or 0
            local sp = tonumber(item.sell_price) or 0
            local cantAct = item.cant_activate == true

            local card = grid:Add('Panel')
            card:SetTall(ST(130))
            card.Paint = function(pnl, cw, ch)
                draw.RoundedBox(8, 0, 0, cw, ch, colorSecondary)
                draw.RoundedBoxEx(8, 0, ch - ST(4), cw, ST(4), col, false, false, true, true)

                local iconUrl = CasesSystem.GetRewardArtwork(item)
                if iconUrl then
                    local mat = GetWebOrLocalMat(iconUrl)
                    if mat then
                        surface.SetMaterial(mat)
                        surface.SetDrawColor(color_white)
                        surface.DrawTexturedRect(math.floor((cw - ST(40)) * .5), ST(6), ST(40), ST(40))
                    end
                end

                draw.SimpleText(item.name or 'Награда', 'CSF4.SmallB', cw * .5, ST(50), colorWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                if cantAct then
                    draw.SimpleText('[ТОЛЬКО ПРОДАЖА]', 'CSF4.Small', cw * .5, ST(66), Color(255, 110, 110), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                elseif sp > 0 then
                    draw.SimpleText('+' .. FormatMoney(sp), 'CSF4.Small', cw * .5, ST(66), colorCanAfford, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
                end
            end

            if sp > 0 and invID > 0 then
                local btnCardSell = card:Add('onyx.Button')
                btnCardSell:Dock(BOTTOM)
                btnCardSell:DockMargin(ST(6), 0, ST(6), ST(8))
                btnCardSell:SetTall(ST(24))
                btnCardSell:SetText('ПРОДАТЬ (' .. FormatMoney(sp) .. ')')
                btnCardSell:Font('Comfortaa Bold@11')
                btnCardSell:SetColorIdle(Color(160, 50, 50))
                btnCardSell:SetColorHover(Color(190, 60, 60))
                btnCardSell.DoClick = function()
                    Client.SendSell(invID)
                    card:SetVisible(false)
                    grid:InvalidateLayout()
                end
            end
        end

        local btnH = ST(38)

        local btnClaimAll = modal:Add('onyx.Button')
        btnClaimAll:SetText('ЗАБРАТЬ ВСЕ В ИНВЕНТАРЬ')
        btnClaimAll:Font('Comfortaa Bold@13')
        btnClaimAll:SetColorIdle(Color(45, 140, 60))
        btnClaimAll:SetColorHover(Color(55, 170, 75))
        btnClaimAll:SetMasking(true)
        btnClaimAll:SetGradientColor(Color(30, 100, 40, 80))
        btnClaimAll.DoClick = function()
            modal:Remove()
            if IsValid(Renderer.Frame) and Renderer.Frame.activeTabContent and Renderer.Frame.activeTabContent.Refresh then
                Renderer.Frame.activeTabContent:Refresh()
            end
        end

        local btnSellAll = modal:Add('onyx.Button')
        btnSellAll:SetText('ПРОДАТЬ ВСЕ ЗА ' .. FormatMoney(totalSell))
        btnSellAll:Font('Comfortaa Bold@13')
        btnSellAll:SetColorIdle(Color(160, 50, 50))
        btnSellAll:SetColorHover(Color(190, 60, 60))
        btnSellAll:SetMasking(true)
        btnSellAll:SetGradientColor(Color(120, 30, 30, 80))
        btnSellAll.DoClick = function()
            if #allInvIDs > 0 then
                Client.SendSellMultiple(allInvIDs)
            end
            modal:Remove()
            if IsValid(Renderer.Frame) and Renderer.Frame.activeTabContent and Renderer.Frame.activeTabContent.Refresh then
                Renderer.Frame.activeTabContent:Refresh()
            end
        end

        local btnAgain = nil
        if remainingCases >= count and caseID then
            btnAgain = modal:Add('onyx.Button')
            btnAgain:SetText('ЕЩЁ ' .. count .. ' ШТ.')
            btnAgain:Font('Comfortaa Bold@13')
            btnAgain:SetColorIdle(colorAccent)
            btnAgain:SetColorHover(onyx.OffsetColor(colorAccent, 25))
            btnAgain:SetMasking(true)
            btnAgain:SetGradientColor(colorGradient)
            btnAgain.DoClick = function()
                modal:Remove()
                Client.SendOpen(caseID, count)
            end
        end

        modal.PerformLayout = function(pnl, w, h)
            local mx = math.floor((w - mw) * .5)
            local my = math.floor((h - mh) * .5)

            btnClose:SetPos(mx + mw - ST(36), my + ST(10))

            scroll:SetPos(mx + ST(16), my + ST(60))
            scroll:SetSize(mw - ST(32), mh - ST(130))

            local btnY = my + mh - ST(54)

            if IsValid(btnAgain) then
                local btnW = math.floor((mw - ST(48)) / 3)
                local gap = ST(8)
                local startX = mx + ST(16)

                btnClaimAll:SetPos(startX, btnY)
                btnClaimAll:SetSize(btnW, btnH)

                btnSellAll:SetPos(startX + btnW + gap, btnY)
                btnSellAll:SetSize(btnW, btnH)

                btnAgain:SetPos(startX + (btnW + gap) * 2, btnY)
                btnAgain:SetSize(btnW, btnH)
            else
                local btnW = math.floor((mw - ST(40)) / 2)
                local gap = ST(8)
                local startX = mx + ST(16)

                btnClaimAll:SetPos(startX, btnY)
                btnClaimAll:SetSize(btnW, btnH)

                btnSellAll:SetPos(startX + btnW + gap, btnY)
                btnSellAll:SetSize(btnW, btnH)
            end
        end
    end
end

-- 12. ГЛАВНЫЙ ФРЕЙМ CASES
local lastChosenTab = 1

local FRAME_TABS = {
    { id = 'cases',     title = 'КЕЙСЫ',      desc = 'Витрина и открытие',    icon = 'https://i.imgur.com/JnNGizM.png', class = 'cases.TabCases'     },
    { id = 'inventory', title = 'ИНВЕНТАРЬ',  desc = 'Выигранные предметы',   icon = 'https://i.imgur.com/oRqB4Cl.png', class = 'cases.TabInventory' },
    { id = 'topup',     title = 'ПОПОЛНЕНИЕ', desc = 'Пополнение донат счета',icon = 'https://i.imgur.com/MrgKOkL.png', class = 'cases.TabTopUp'    },
    { id = 'settings',  title = 'НАСТРОЙКИ',  desc = 'Звуки и анимации',      icon = 'https://i.imgur.com/9uyTLgB.png', class = 'cases.TabSettings'  },
    { id = 'admin',     title = 'УПРАВЛЕНИЕ', desc = 'Редактор кейсов',       icon = 'https://i.imgur.com/l4M12dO.png', class = 'cases.TabAdmin', adminOnly = true },
}

do
    DEFINE_BASECLASS('onyx.Frame')
    local PANEL = {}

    function PANEL:Init()
        local this = self
        Renderer.Frame = self
        self.toasts = {}

        local padding = ST(10)
        self.container = self:Add('Panel')
        self.container:DockPadding(padding, padding, padding, padding)

        self.sidebar = self:Add('onyx.Sidebar')
        self.sidebar:SetDescriptionEnabled(true)
        self.sidebar:SetContainer(self.container)
        self.sidebar:SetKeepTabContent(true)
        self:Combine(self.sidebar, 'ChooseTab')
        self.sidebar:On('OnTabSwitched', function(panel, tab)
            lastChosenTab = tab.tabIndex
            this.activeTabContent = tab.content
            if IsValid(tab.content) and tab.content.Refresh then
                tab.content:Refresh()
            end
        end)

        self:SetTitle('СИСТЕМА КЕЙСОВ')
        self.profile = self:InitProfile()
        self:LoadTabs()
        self:ChooseTab(lastChosenTab)

        self.balanceBlock = self.sidebar:Add('Panel')
        self.balanceBlock:Dock(BOTTOM)
        self.balanceBlock:SetTall(ST(90))
        self.balanceBlock:DockMargin(0, ST(10), 0, 0)
        self.balanceBlock.Paint = function(pnl, bw, bh)
            draw.RoundedBox(8, 0, 0, bw, bh, colorTertiary)
            draw.SimpleText('ВАШ БАЛАНС', 'CSF4.Small', ST(10), ST(10), colorGray, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(FormatMoney(GetIGSBalance()), 'CSF4.Bal', ST(10), ST(26), colorCanAfford, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        self.balanceBlock.Think = function(pnl)
            if (pnl.nextThink or 0) > CurTime() then return end
            pnl.nextThink = CurTime() + .33
            pnl:InvalidateLayout()
        end

        local btnTU = self.balanceBlock:Add('onyx.Button')
        btnTU:SetText('ПОПОЛНИТЬ')
        btnTU:Dock(BOTTOM)
        btnTU:SetTall(ST(28))
        btnTU:DockMargin(ST(8), 0, ST(8), ST(8))
        btnTU:SetMasking(true)
        btnTU:SetGradientColor(Color(255, 255, 255, 20))
        btnTU:SetGradientDirection(RIGHT)
        btnTU.DoClick = function()
            this:SelectTabByID('topup')
        end

        self:SetAlpha(0)
        self:AlphaTo(255, 0.15, 0)
    end

    function PANEL:InitProfile()
        local sidebar = self.sidebar
        local padding = ST(7.5)
        local client = LocalPlayer()

        local labelText = team.GetName(client:Team())
        local labelColor = (onyx.f4 and onyx.f4.ConvertJobColor) and
            onyx.f4.ConvertJobColor(team.GetColor(client:Team())) or (team.GetColor(client:Team()) or colorAccent)
        local labelFont = onyx.Font('Comfortaa@14')

        local profile = sidebar:Add('Panel')
        profile:SetTall(ST(50))
        profile:Dock(TOP)
        profile:DockMargin(0, 0, 0, ST(5))
        profile:DockPadding(padding, padding, padding, padding)
        profile.Paint = function(pnl, w, h)
            draw.RoundedBox(8, 0, 0, w, h, colorTertiary)
            draw.RoundedBox(8, 1, 1, w - 2, h - 2, colorPrimary)
        end
        profile.Think = function(pnl)
            if ((pnl.nextThink or 0) > CurTime()) then return end
            pnl.nextThink = CurTime() + .25
            labelColor = (onyx.f4 and onyx.f4.ConvertJobColor) and
                onyx.f4.ConvertJobColor(team.GetColor(client:Team())) or (team.GetColor(client:Team()) or colorAccent)
            labelText = team.GetName(client:Team())
            if IsValid(pnl.lblJob) then
                pnl.lblJob:SetText(labelText)
                pnl.lblJob:SetTextColor(labelColor)
            end
        end

        local avatar = profile:Add('onyx.RoundedAvatar')
        avatar:Dock(LEFT)
        avatar:SetWide(profile:GetTall() - padding * 2)
        avatar:SetPlayer(LocalPlayer(), 64)
        avatar:DockMargin(0, 0, SW(10), 0)
        avatar.PaintOver = function(pnl, w, h)
            onyx.DrawOutlinedCircle(w * .5, h * .5, h * .5, 4, labelColor)
        end

        local lblTitle = profile:Add('onyx.Label')
        lblTitle:Dock(TOP)
        lblTitle:SetText(client:Name())
        lblTitle:Font('Comfortaa Bold@16')
        lblTitle:SetContentAlignment(4)

        local lblJob = profile:Add('onyx.Label')
        lblJob:Dock(FILL)
        lblJob:SetText(labelText)
        lblJob:SetTextColor(labelColor)
        lblJob:SetFont(labelFont)
        lblJob:SetContentAlignment(7)
        profile.lblJob = lblJob

        profile.PerformLayout = function(pnl, w, h)
            lblTitle:SetTall((h - padding * 2) / 2)
        end

        return profile
    end

    function PANEL:LoadTabs()
        local isUserAdmin = LocalPlayer():IsSuperAdmin() or (LocalPlayer().GetUserGroup and string.lower(LocalPlayer():GetUserGroup()) == 'superadmin')

        for _, tab in ipairs(FRAME_TABS) do
            if tab.adminOnly and not isUserAdmin then continue end
            self.sidebar:AddTab({
                name  = tab.title,
                desc  = tab.desc,
                icon  = tab.icon,
                class = tab.class
            })
        end
    end

    function PANEL:EnableCasePreview(cdef)
        local this = self
        if not IsValid(self.casePreviewPanel) then
            self.casePreviewPanel = self:Add('cases.CasePreview')
            self.casePreviewPanel:SetZPos(2000)
        end
        self.sidebar:Hide()
        self.container:Hide()
        self.casePreviewPanel:Show()
        local headerH = IsValid(self.divHeader) and self.divHeader:GetTall() or ST(34)
        self.casePreviewPanel:SetPos(0, headerH)
        self.casePreviewPanel:SetSize(self:GetWide(), self:GetTall() - headerH)
        self.casePreviewPanel:SetupCase(cdef)

        -- 1. Заменяем заголовок сверху на название кейса
        self:SetTitle(cdef.name or cdef.id)

        -- 2. Добавляем кнопку назад слева в шапку (текст без фона, белый под размер креста, при наведении зеленый)
        if IsValid(self.divHeader) then
            if not IsValid(self.btnBackToMenu) then
                self.btnBackToMenu = self.divHeader:Add('DButton')
                self.btnBackToMenu:SetText('')
                self.btnBackToMenu.hoverProgress = 0
                self.btnBackToMenu.Paint = function(pnl, bw, bh)
                    local hovered = pnl:IsHovered()
                    pnl.hoverProgress = math.Approach(pnl.hoverProgress, hovered and 1 or 0, FrameTime() * 8)
                    local col = onyx.LerpColor(pnl.hoverProgress, color_white, Color(121, 255, 141))
                    draw.SimpleText('⬅ НАЗАД В МЕНЮ', 'CSF4.H1', ST(14), bh * .5, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end
                self.btnBackToMenu.DoClick = function()
                    this:DisableCasePreview()
                end
            end
            self.btnBackToMenu:Show()
            self.btnBackToMenu:SetPos(0, 0)
            self.btnBackToMenu:SetSize(SW(220), headerH)
            self.btnBackToMenu:SetZPos(3000)
        end

        self:InvalidateLayout()
    end

    function PANEL:DisableCasePreview()
        if IsValid(self.casePreviewPanel) then
            self.casePreviewPanel:Hide()
        end
        if IsValid(self.btnBackToMenu) then
            self.btnBackToMenu:Hide()
        end
        self.sidebar:Show()
        self.container:Show()

        -- Возвращаем стандартный заголовок
        self:SetTitle('СИСТЕМА КЕЙСОВ')

        self:InvalidateLayout()
    end

    function PANEL:PerformLayout(w, h)
        BaseClass.PerformLayout(self, w, h)
        local headerH = IsValid(self.divHeader) and self.divHeader:GetTall() or ST(34)
        if IsValid(self.casePreviewPanel) and self.casePreviewPanel:IsVisible() then
            self.casePreviewPanel:SetPos(0, headerH)
            self.casePreviewPanel:SetSize(w, h - headerH)
        end
        if IsValid(self.btnBackToMenu) and IsValid(self.divHeader) then
            self.btnBackToMenu:SetPos(0, 0)
            self.btnBackToMenu:SetSize(SW(180), headerH)
        end
        self.sidebar:Dock(LEFT)
        self.sidebar:SetWide(w * .2)
        self.container:Dock(FILL)
        self:LayoutToasts()
    end

    function PANEL:SelectTabByID(id)
        self:DisableCasePreview()
        local isUserAdmin = LocalPlayer():IsSuperAdmin() or (LocalPlayer().GetUserGroup and string.lower(LocalPlayer():GetUserGroup()) == 'superadmin')
        local tabIdx = 0
        for _, info in ipairs(FRAME_TABS) do
            if info.adminOnly and not isUserAdmin then continue end
            tabIdx = tabIdx + 1
            if info.id == id then
                self:ChooseTab(tabIdx)
                return
            end
        end
    end

    function PANEL:Toast(text, col)
        -- Отключено: уведомления скрыты в интерфейсе кейсов
    end

    function PANEL:LayoutToasts()
    end

    function PANEL:OnRemove()
        if Renderer.Frame == self then Renderer.Frame = nil end
    end

    onyx.gui.Register('cases.Frame', PANEL, 'onyx.Frame')
end

-- 13. RENDERER INTERFACE (CALLED BY cl_controller.lua)
function Renderer.Open(data)
    if IsValid(Renderer.Frame) and not Renderer.Frame.bClosing then
        Renderer.Frame:MoveToFront()
        if Renderer.Frame.activeTabContent and Renderer.Frame.activeTabContent.Refresh then
            Renderer.Frame.activeTabContent:Refresh()
        end
        return Renderer.Frame
    elseif IsValid(Renderer.Frame) and Renderer.Frame.bClosing then
        if isfunction(Renderer.Frame._Remove) then
            Renderer.Frame:_Remove()
        else
            Renderer.Frame:Remove()
        end
        Renderer.Frame = nil
    end

    local w = math.min(ScrW() - ST(60), math.floor(ScrW() * 0.65))
    local h = math.min(ScrH() - ST(60), math.floor(ScrH() * 0.65))
    w = math.max(ST(760), w)
    h = math.max(ST(480), h)

    Renderer.Frame = vgui.Create('cases.Frame')
    Renderer.Frame:SetSize(w, h)
    Renderer.Frame:Center()
    Renderer.Frame:MakePopup()

    surface.PlaySound('ui/buttonclickrelease.wav')
    return Renderer.Frame
end

function Renderer.Close()
    if not IsValid(Renderer.Frame) or Renderer.Frame.bClosing then return end
    Renderer.Frame.bClosing = true
    Renderer.Frame:Close()
end

function Renderer.Toggle()
    if IsValid(Renderer.Frame) and not Renderer.Frame.bClosing then
        Renderer.Close()
    else
        Renderer.Open()
    end
end

function Renderer.Refresh(data)
    if IsValid(Renderer.Frame) and Renderer.Frame.activeTabContent and Renderer.Frame.activeTabContent.Refresh then
        Renderer.Frame.activeTabContent:Refresh()
    end
end

function Renderer.PlayOpening(result)
    if not result or result.failed or result.error then return end
    local caseID = result.case_id
    local wonRewards = result.rewards or {}

    local cdef = nil
    for _, cd in ipairs((Client.Data and Client.Data.cases) or {}) do
        if cd.id == caseID then cdef = cd; break end
    end

    PlayOnyxRouletteAnimation(cdef, wonRewards)
end

function Client.PushNotification(data)
    -- Отключено по запросу: уведомления кейс-системы скрыты
end

local RussianTranslitCases = {
    ['сфыуы'] = 'cases',
    ['сфыу'] = 'case',
    ['кейсы'] = 'cases',
    ['кейс'] = 'cases',
    ['rtd'] = 'cases',
    ['cases'] = 'cases',
    ['case'] = 'case'
}

-- Keybind or commands
local function IsCaseOpenCommand(text)
    local trimmed = string.lower(string.Trim(tostring(text or '')))
    local prefix, rawCmd = string.match(trimmed, '^([/!%.%,%?юб])(%S+)')
    if not rawCmd then return false end
    local cmd = RussianTranslitCases[rawCmd] or rawCmd
    return cmd == 'cases' or cmd == 'case' or cmd == 'кейсы' or cmd == 'кейс' or cmd == 'rtd' or rawCmd == 'сфыуы' or rawCmd == 'сфыу'
end

local function OpenCases()
    if Renderer and isfunction(Renderer.Open) then
        Renderer.Open(Client.Data)
    end
    Client.RequestSnapshot()
end

hook.Add('OnPlayerChat', 'CasesOnyxF4.Commands', function(client, text)
    if client ~= LocalPlayer() then return end
    if not IsCaseOpenCommand(text) then return end
    timer.Simple(0, function() OpenCases() end)
    return true
end)

concommand.Add('cases_onyx_open', function() OpenCases() end)
concommand.Add('cases_onyx_close', function() Renderer.Close() end)
concommand.Add('cases_onyx_toggle', function() Renderer.Toggle() end)

hook.Remove('ShowTeam', 'CasesOnyxF4.ShowTeam')
hook.Remove('PlayerBindPress', 'CasesOnyxF4.BindPress')
hook.Remove('PlayerButtonDown', 'CasesOnyxF4.DirectKeybind')

CasesSystem.OpenUI = OpenCases
CasesSystem.CloseUI = Renderer.Close
CasesSystem.ToggleUI = Renderer.Toggle

    if onyx and onyx.f4 and onyx.f4.tabs then
        onyx.f4.tabs['cases'] = nil
    end

    print('[Cases System x Onyx F4] UI v4.2 successfully initialized!')
end

doCasesOnyxInit()

hook.Add('onyx.Loaded', 'CasesOnyxF4.WaitForOnyx', function()
    doCasesOnyxInit()
    if onyx and onyx.f4 and onyx.f4.tabs then
        onyx.f4.tabs['cases'] = nil
    end
end)

hook.Add('InitPostEntity', 'CasesOnyxF4.WaitForOnyxIPE', function()
    doCasesOnyxInit()
    if onyx and onyx.f4 and onyx.f4.tabs then
        onyx.f4.tabs['cases'] = nil
    end
end)

timer.Create('CasesOnyxF4.RetryInit', 0.5, 10, function()
    if onyx and onyx.gui and onyx.gui.Register then
        doCasesOnyxInit()
        if onyx and onyx.f4 and onyx.f4.tabs then
            onyx.f4.tabs['cases'] = nil
        end
        timer.Remove('CasesOnyxF4.RetryInit')
    end
end)


