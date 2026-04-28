require "ISUI/ISPanel"
require "ISUI/ISButton"
---@class ChaosHUD : ISPanel
---@field toasts table<string, string>
---@field text string
---@field btn ISButton
---@field messages table<integer, {text: string, expireTime: integer}>
ChaosHUD = ISPanel:derive("ChaosHUD")

local PANEL_HEIGHT = 100
local MESSAGE_TIMEOUT_MS = 5000

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

    local buttonWidth = ChaosUIManager.GetScaledWidth(120)
    local buttonX = ChaosUIManager.GetScaledWidth(10)

    self.btn = ISButton:new(buttonX, buttonY, buttonWidth, buttonHeight, "Button", self, ChaosHUD.OnMainButtonClick)
    self.btn:initialise()
    self.btn:instantiate()
    self:addChild(self.btn)
    self:OnModStatusChanged(ChaosMod.enabled)

    local secondButtonWidth = ChaosUIManager.GetScaledWidth(100)
    local secondButtonX = buttonX + buttonWidth + ChaosUIManager.GetScaledWidth(6)

    self.secondBtn = ISButton:new(secondButtonX, buttonY, secondButtonWidth, buttonHeight,
        ChaosLocalization.GetString("core", "select_effect"),
        self,
        ChaosHUD.OnSecondButtonClick)
    self.secondBtn:initialise()
    self.secondBtn:instantiate()
    self:addChild(self.secondBtn)
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
            if ChaosConfig.use_voting_progress_bar_color and sm and sm.streamer_mode_enabled == true and sm.voting_enabled == true and ChaosEffectsManager.lastVotingActive == 1 then
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
            local msgFont = UIFont.Medium
            local msgFontHeight = getTextManager():getFontHeight(msgFont)
            local msgPadX = ChaosUIManager.GetScaledWidth(12)
            local msgPadY = ChaosUIManager.GetScaledWidth(6)
            local msgGap  = ChaosUIManager.GetScaledWidth(4)
            local msgLineHeight = msgFontHeight + msgPadY * 2
            local msgX = ChaosUIManager.GetScaledWidth(10)

            local buttonHeight = ChaosUIManager.GetScaledWidth(25)
            local buttonMargin = ChaosUIManager.GetScaledWidth(6)
            local buttonY = panelHeight - barHeight - buttonMargin - buttonHeight
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

    local buttonWidth = ChaosUIManager.GetScaledWidth(120)
    self.btn:setWidthToTitle(buttonWidth)
end

function ChaosHUD:OnLanguageLoaded()
    -- Update text of select_effect button
    self.secondBtn:setTitle(ChaosLocalization.GetString("core", "select_effect"))
    self.secondBtn:setWidthToTitle(ChaosUIManager.GetScaledWidth(100))
    -- Update width of main button
    self:OnModStatusChanged(ChaosMod.enabled)
end

function ChaosHUD:OnSecondButtonClick()
    print("Second button clicked")
    ChaosUIManager:ToggleEffectsWindow()
end
