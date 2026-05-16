require "ISUI/ISPanel"
require "ISUI/ISButton"
---@class ChaosHUD : ISPanel
---@field toasts table<string, string>
---@field text string
---@field btn ISButton
---@field messages table<integer, {text: string, expireTime: integer}>
---@field introStartMs integer?
---@field introModVersion string?
---@field introEffectsCount number?
ChaosHUD = ISPanel:derive("ChaosHUD")

local PANEL_HEIGHT = 100
local MESSAGE_TIMEOUT_MS = 5000
local BUTTON_HORIZONTAL_PADDING = 24
local MAIN_BUTTON_MIN_WIDTH = 120
local SECOND_BUTTON_MIN_WIDTH = 100
local INTRO_VISIBLE_MS = 8000
local INTRO_FADEOUT_MS = 1000
local INTRO_BOTTOM_OFFSET = 100
local INTRO_BG_PAD_X = 24
local INTRO_BG_PAD_Y = 12
local INTRO_BG_OPACITY = 0.7

---@param button ISButton
---@param minWidth number
---@return number
function ChaosHUD:GetButtonWidth(button, minWidth)
    local textManager = getTextManager()
    local font = button.font or UIFont.Small
    local title = button.title or ""
    local textWidth = textManager:MeasureStringX(font, title)
    local padding = ChaosUIManager.GetScaledWidth(BUTTON_HORIZONTAL_PADDING)
    local scaledMinWidth = ChaosUIManager.GetScaledWidth(minWidth)

    return math.max(scaledMinWidth, textWidth + padding)
end

function ChaosHUD:RefreshButtonLayout()
    if not self.btn or not self.secondBtn then return end

    local buttonGap = ChaosUIManager.GetScaledWidth(6)
    local mainButtonWidth = self:GetButtonWidth(self.btn, MAIN_BUTTON_MIN_WIDTH)
    local secondButtonWidth = self:GetButtonWidth(self.secondBtn, SECOND_BUTTON_MIN_WIDTH)

    self.btn:setWidth(mainButtonWidth)
    self.secondBtn:setWidth(secondButtonWidth)
    self.secondBtn:setX(self.btn:getX() + mainButtonWidth + buttonGap)

    if self.settingsBtn then
        self.settingsBtn:setX(self.secondBtn:getX() + secondButtonWidth + buttonGap)
    end
end

function ChaosHUD:initialise()
    ISPanel.initialise(self)
    self.text = "Test String"
end

function ChaosHUD:new()
    local panelWidth = ChaosUIManager.GetScaledWidth(1920 * 0.2)
    local panelHeight = ChaosUIManager.GetScaledWidth(PANEL_HEIGHT)
    local panelX = 0
    local panelY = ChaosUIManager.cachedHeight - panelHeight
    ---@type ChaosHUD
    local o = ISPanel:new(panelX, panelY, panelWidth, panelHeight)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o.anchorLeft = true
    o.anchorBottom = true
    o.messages = {}

    return o
end

function ChaosHUD:createChildren()
    local panelHeight = ChaosUIManager.GetScaledWidth(PANEL_HEIGHT)
    local barHeight = ChaosUIManager.GetScaledWidth(ChaosConfig.ui.progress_bar_height)
    local buttonHeight = ChaosUIManager.GetScaledWidth(25)
    local buttonMargin = ChaosUIManager.GetScaledWidth(6)
    local buttonY = panelHeight - barHeight - buttonMargin - buttonHeight

    local buttonWidth = ChaosUIManager.GetScaledWidth(MAIN_BUTTON_MIN_WIDTH)
    local buttonX = ChaosUIManager.GetScaledWidth(10)

    self.btn = ISButton:new(buttonX, buttonY, buttonWidth, buttonHeight, "Button", self, ChaosHUD.OnMainButtonClick)
    self.btn:initialise()
    self.btn:instantiate()
    self:addChild(self.btn)
    self:OnModStatusChanged(ChaosMod.enabled)

    local secondButtonWidth = ChaosUIManager.GetScaledWidth(SECOND_BUTTON_MIN_WIDTH)
    local secondButtonX = buttonX + buttonWidth + ChaosUIManager.GetScaledWidth(6)

    self.secondBtn = ISButton:new(secondButtonX, buttonY, secondButtonWidth, buttonHeight,
        ChaosLocalization.GetString("core", "select_effect"),
        self,
        ChaosHUD.OnSecondButtonClick)
    self.secondBtn:initialise()
    self.secondBtn:instantiate()
    self:addChild(self.secondBtn)

    local settingsButtonX = secondButtonX + secondButtonWidth + ChaosUIManager.GetScaledWidth(6)
    self.settingsBtn = ISButton:new(settingsButtonX, buttonY, buttonHeight, buttonHeight, "",
        self,
        ChaosHUD.OnSettingsButtonClick)
    self.settingsBtn:initialise()
    self.settingsBtn:instantiate()
    self.settingsBtn:setImage(getTexture("media/ui/chaos_gear.png"))
    local iconSize = math.floor(buttonHeight * 0.6)
    self.settingsBtn:forceImageSize(iconSize, iconSize)
    self:addChild(self.settingsBtn)

    self:RefreshButtonLayout()
end

---@param text string
function ChaosHUD:addText(text)
    self.text = text
end

---@param text string
---@param timeoutMs integer?
function ChaosHUD:AddMessage(text, timeoutMs)
    if not self.messages then self.messages = {} end
    table.insert(self.messages, {
        text = text,
        expireTime = getTimestampMs() + (timeoutMs or MESSAGE_TIMEOUT_MS),
    })
end

---@param modVersion string
---@param effectsCount number
function ChaosHUD:ShowIntro(modVersion, effectsCount)
    self.introStartMs = getTimestampMs()
    self.introModVersion = modVersion or "0"
    self.introEffectsCount = effectsCount or 0
end

function ChaosHUD:RenderIntro()
    if not self.introStartMs then return end

    local elapsed = getTimestampMs() - self.introStartMs
    if elapsed >= INTRO_VISIBLE_MS + INTRO_FADEOUT_MS then
        self.introStartMs = nil
        return
    end

    local alpha = 1.0
    if elapsed > INTRO_VISIBLE_MS then
        alpha = 1.0 - ((elapsed - INTRO_VISIBLE_MS) / INTRO_FADEOUT_MS)
        if alpha < 0 then alpha = 0 end
    end

    local introFont = UIFont.Intro
    local textManager = getTextManager()
    local line1 = string.format("Chaos Mod v%s Started", self.introModVersion or "0")
    local line2 = string.format("%d effects", self.introEffectsCount or 0)
    local fontHeight = textManager:getFontHeight(introFont)
    local line1Width = textManager:MeasureStringX(introFont, line1)
    local line2Width = textManager:MeasureStringX(introFont, line2)

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local centerX = screenW / 2 - self:getX()
    local centerY = screenH / 2 - self:getY() + ChaosUIManager.GetScaledHeight(INTRO_BOTTOM_OFFSET)

    local totalHeight = fontHeight * 2
    local line1Y = centerY - math.floor(totalHeight / 2)
    local line2Y = line1Y + fontHeight

    local maxTextWidth = math.max(line1Width, line2Width)
    local padX = ChaosUIManager.GetScaledWidth(INTRO_BG_PAD_X)
    local padY = ChaosUIManager.GetScaledHeight(INTRO_BG_PAD_Y)
    local bgWidth = maxTextWidth + padX * 2
    local bgHeight = totalHeight + padY * 2
    local bgX = centerX - math.floor(bgWidth / 2)
    local bgY = line1Y - padY
    self:drawRect(bgX, bgY, bgWidth, bgHeight, INTRO_BG_OPACITY * alpha, 0.1, 0.1, 0.1)

    self:drawText(line1, centerX - math.floor(line1Width / 2), line1Y, 1, 1, 1, alpha, introFont)
    self:drawText(line2, centerX - math.floor(line2Width / 2), line2Y, 1, 1, 1, alpha, introFont)
end

function ChaosHUD:prerender()
    ISPanel.prerender(self)

    local barMaxWidth = getCore():getScreenWidth()
    local panelHeight = ChaosUIManager.GetScaledWidth(PANEL_HEIGHT)
    local barHeight = ChaosUIManager.GetScaledWidth(ChaosConfig.ui.progress_bar_height)
    local barY = panelHeight - barHeight

    -- Effects Progress Bar — at the bottom of the panel
    if ChaosMod.enabled and ChaosConfig.IsEffectsEnabled() and not ChaosConfig.hide_progress_bar then
        local timerMax = ChaosEffectsManager.globalTimerMaxMs
        local fgWidth = 0
        if timerMax > 0 then
            fgWidth = math.floor(barMaxWidth * (ChaosEffectsManager.globalTimerMs / timerMax))
        end
        local uiCfg = ChaosConfig.ui
        -- Colored on left (elapsed)
        if fgWidth > 0 then
            local c = uiCfg.progress_bar_rgb
            local sm = ChaosConfig.streamer_mode
            if ChaosConfig.use_voting_progress_bar_color and sm and sm.streamer_mode_enabled == true and sm.voting_enabled == true and ChaosEffectsManager.voteStartedThisInterval then
                c = uiCfg.progress_bar_voting_rgb
            end
            self:drawRect(0, barY, fgWidth, barHeight, uiCfg.progress_bar_opacity, c.r, c.g, c.b)
        end
        -- Gray on right (remaining)
        local bgWidth = barMaxWidth - fgWidth
        if bgWidth > 0 then
            self:drawRect(fgWidth, barY, bgWidth, barHeight, 0.7, 0.1, 0.1, 0.1)
        end

        -- Countdown text: shows time remaining (timerMax -> 0)
        local remainingMs = (timerMax > 0) and (timerMax - ChaosEffectsManager.globalTimerMs) or 0
        local timerText = string.format("%.1fs", remainingMs / 1000)
        local timerFontHeight = getTextManager():getFontHeight(UIFont.Large)
        local timerTextY = barY + math.floor((barHeight - timerFontHeight) / 2)
        local tc = uiCfg.progress_bar_text_rgb
        self:drawText(timerText, ChaosUIManager.GetScaledWidth(8), timerTextY, tc.r, tc.g, tc.b, 1, UIFont.Large)
    end

    -- Message log above the Enable/Disable button
    if self.messages and #self.messages > 0 then
        local now = getTimestampMs()
        local i = 1
        while i <= #self.messages do
            if now >= self.messages[i].expireTime then
                table.remove(self.messages, i)
            else
                i = i + 1
            end
        end

        if #self.messages > 0 then
            local msgFont       = UIFont.Medium
            local msgFontHeight = getTextManager():getFontHeight(msgFont)
            local msgPadX       = ChaosUIManager.GetScaledWidth(12)
            local msgPadY       = ChaosUIManager.GetScaledWidth(6)
            local msgGap        = ChaosUIManager.GetScaledWidth(4)
            local msgLineHeight = msgFontHeight + msgPadY * 2
            local msgX          = ChaosUIManager.GetScaledWidth(10)

            local buttonHeight  = ChaosUIManager.GetScaledWidth(25)
            local buttonMargin  = ChaosUIManager.GetScaledWidth(6)
            local buttonY       = panelHeight - barHeight - buttonMargin - buttonHeight
            local msgAreaBottom = buttonY - ChaosUIManager.GetScaledWidth(10)

            for idx = 1, #self.messages do
                -- idx=1 is oldest (bottom/closest to button), idx=n is newest (top)
                local msgY = msgAreaBottom - idx * msgLineHeight - (idx - 1) * msgGap
                local msg = self.messages[idx]
                local textWidth = getTextManager():MeasureStringX(msgFont, msg.text)
                self:drawRect(msgX, msgY, textWidth + msgPadX * 2, msgLineHeight, 0.7, 0.15, 0.15, 0.15)
                self:drawText(msg.text, msgX + msgPadX, msgY + msgPadY, 1, 1, 1, 1, msgFont)
            end
        end
    end

    local fontsTest = {
        "Small",
        "Medium",
        "Large",
        "Massive",
        "MainMenu1",
        "MainMenu2",
        "Cred1",
        "Cred2",
        "NewSmall",
        "NewMedium",
        "NewLarge",
        "Code",
        "CodeSmall",
        "CodeMedium",
        "CodeLarge",
        "MediumNew",
        "AutoNormSmall",
        "AutoNormMedium",
        "AutoNormLarge",
        "Dialogue",
        "Intro",
        "Handwritten",
        "DebugConsole",
        "Title",
        "SdfRegular",
        "SdfBold",
        "SdfItalic",
        "SdfBoldItalic",
        "SdfOldRegular",
        "SdfOldBold",
        "SdfOldItalic",
        "SdfOldBoldItalic",
        "SdfRobertoSans",
        "SdfCaveat",
    }

    -- local i = 0
    -- for i, fontName in pairs(fontsTest) do
    --     self:drawText(string.format("%s - Пример", fontName), 200, 0 - (i * 40), 1, 1, 1, 1, UIFont[fontName])
    -- end

    self:RenderIntro()
end

function ChaosHUD:OnMainButtonClick()
    print("Main button clicked")
    if ChaosMod.enabled then
        ChaosMod.StopMod()
    else
        ChaosMod.StartMod()
    end
end

---@param enabled boolean
function ChaosHUD:OnModStatusChanged(enabled)
    if enabled then
        self.btn:setTitle(ChaosLocalization.GetString("core", "stop_mod"))
        self.btn:enableCancelColor()
    else
        self.btn:setTitle(ChaosLocalization.GetString("core", "start_mod"))
        self.btn:enableAcceptColor()
    end

    self:RefreshButtonLayout()
end

function ChaosHUD:OnLanguageLoaded()
    -- Update text of select_effect button
    self.secondBtn:setTitle(ChaosLocalization.GetString("core", "select_effect"))
    -- Update width of main button
    self:OnModStatusChanged(ChaosMod.enabled)
end

function ChaosHUD:OnSecondButtonClick()
    print("Second button clicked")
    ChaosUIManager:ToggleEffectsWindow()
end

function ChaosHUD:OnSettingsButtonClick()
    ChaosUIManager:ToggleSettingsWindow()
end
