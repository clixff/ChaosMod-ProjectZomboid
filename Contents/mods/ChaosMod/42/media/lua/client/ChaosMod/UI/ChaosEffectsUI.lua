require "ISUI/ISPanel"
require "ISUI/ISButton"

---@class ChaosEffectsUI : ISPanel
---@field renderMode string
---@field anchorRight boolean
---@field adornmentsVisible boolean
---@field anchorX number
---@field anchorY number
---@field dragging boolean
---@field titleBarH number
---@field toolbarH number
---@field effectRowH number
---@field effectGap number
---@field windowW number
---@field textPadH number
---@field margin number
---@field btnToggle ISButton
---@field btnAnchor ISButton
ChaosEffectsUI = ISPanel:derive("ChaosEffectsUI")

local MIN_WINDOW_W = 280

function ChaosEffectsUI:new()
    local titleBarH  = ChaosUIManager.GetScaledWidth(24)
    local toolbarH   = ChaosUIManager.GetScaledWidth(30)
    local effectRowH = ChaosUIManager.GetScaledWidth(36)
    local effectGap  = ChaosUIManager.GetScaledWidth(4)
    local windowW    = ChaosUIManager.GetScaledWidth(MIN_WINDOW_W)
    local margin     = ChaosUIManager.GetScaledWidth(6)
    local anchorRight = ChaosConfig.ui.effects_anchor_right

    -- effects_default_x/y always describe the left edge of the window
    local defaultX   = ChaosUIManager.GetScaledWidth(ChaosConfig.ui.effects_default_x)
    local anchorX    = anchorRight and (defaultX + windowW) or defaultX
    local anchorY    = ChaosUIManager.GetScaledHeight(ChaosConfig.ui.effects_default_y)

    local initH      = effectRowH
    local initX      = defaultX  -- always the left edge regardless of anchor mode
    local initY      = anchorY - initH

    ---@type ChaosEffectsUI
    local o          = ISPanel:new(initX, initY, windowW, initH)
    setmetatable(o, self)
    self.__index        = self

    o.backgroundColor   = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor       = { r = 0, g = 0, b = 0, a = 0 }

    o.renderMode        = ChaosConfig.ui.effects_from_bottom_to_top and "bottom_to_top" or "top_to_bottom"
    o.anchorRight       = anchorRight
    o.adornmentsVisible = false
    o.anchorX           = anchorX
    o.anchorY           = anchorY
    o.dragging          = false

    o.titleBarH         = titleBarH
    o.toolbarH          = toolbarH
    o.effectRowH        = effectRowH
    o.effectGap         = effectGap
    o.windowW           = windowW
    o.textPadH          = ChaosUIManager.GetScaledWidth(16)
    o.margin            = margin

    return o
end

function ChaosEffectsUI:initialise()
    ISPanel.initialise(self)
end

function ChaosEffectsUI:createChildren()
    local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
    local btnW = ChaosUIManager.GetScaledWidth(50)
    local btnH = self.toolbarH - self.margin * 2

    self.btnToggle = ISButton:new(0, 0, btnW, btnH, "", self, ChaosEffectsUI.onToggleModeClick)
    self.btnToggle:initialise()
    self.btnToggle:instantiate()
    self.btnToggle:setImage(getTexture("media/ui/chaos_icon_up.png"))
    self.btnToggle:forceImageSize(FONT_HGT_SMALL, FONT_HGT_SMALL)
    self.btnToggle:setVisible(false)
    self:addChild(self.btnToggle)

    self.btnAnchor = ISButton:new(0, 0, btnW, btnH, "", self, ChaosEffectsUI.onToggleAnchorClick)
    self.btnAnchor:initialise()
    self.btnAnchor:instantiate()
    local anchorIcon = self.anchorRight and "media/ui/chaos_icon_left.png" or "media/ui/chaos_icon_right.png"
    self.btnAnchor:setImage(getTexture(anchorIcon))
    self.btnAnchor:forceImageSize(FONT_HGT_SMALL, FONT_HGT_SMALL)
    self.btnAnchor:setVisible(false)
    self:addChild(self.btnAnchor)
end

function ChaosEffectsUI:getEffectsAreaH()
    local N = #ChaosEffectsManager.activeEffects
    if N == 0 then
        return self.effectRowH
    end
    return N * self.effectRowH + (N - 1) * self.effectGap
end

function ChaosEffectsUI:computeWindowW()
    local minW = ChaosUIManager.GetScaledWidth(MIN_WINDOW_W)
    local maxTextW = 0
    local activeEffects = ChaosEffectsManager.activeEffects
    for i = 1, #activeEffects do
        local effect = activeEffects[i]
        local effectString = tostring(effect.effectName)
        if effect.withDuration then
            local msToEnd = effect.maxTicks - effect.ticksActiveTime
            effectString = string.format("%s (%.1fs)", effectString, msToEnd / 1000)
        end
        local tw = getTextManager():MeasureStringX(UIFont.NewLarge, effectString)
        if tw > maxTextW then maxTextW = tw end
    end
    local needed = maxTextW + self.textPadH * 2 + self.margin * 2
    return math.max(minW, needed)
end

function ChaosEffectsUI:updateAnchorFromPosition()
    local titleH = self.adornmentsVisible and self.titleBarH or 0
    local effectsAreaH = self:getEffectsAreaH()
    if self.renderMode == "bottom_to_top" then
        self.anchorY = self.y + titleH + effectsAreaH
    else
        self.anchorY = self.y + titleH
    end
    if self.anchorRight then
        self.anchorX = self.x + self.windowW
    else
        self.anchorX = self.x
    end
end

function ChaosEffectsUI:setAdornmentsVisible(visible)
    if visible == self.adornmentsVisible then return end
    if visible then
        self:setY(self.y - self.titleBarH)
        self.btnToggle:setVisible(true)
        self.btnAnchor:setVisible(true)
    else
        self:setY(self.y + self.titleBarH)
        self.btnToggle:setVisible(false)
        self.btnAnchor:setVisible(false)
    end
    self.adornmentsVisible = visible
    self:updateAnchorFromPosition()
end

function ChaosEffectsUI:updateLayout()
    self.windowW = self:computeWindowW()

    local effectsAreaH = self:getEffectsAreaH()
    local titleH       = self.adornmentsVisible and self.titleBarH or 0
    local toolH        = self.adornmentsVisible and self.toolbarH or 0
    local totalH       = titleH + effectsAreaH + toolH

    self:setWidth(self.windowW)
    self:setHeight(totalH)

    if not self.dragging then
        if self.anchorRight then
            self:setX(self.anchorX - self.windowW)
        else
            self:setX(self.anchorX)
        end
        if self.renderMode == "bottom_to_top" then
            self:setY(self.anchorY - titleH - effectsAreaH)
        else
            self:setY(self.anchorY - titleH)
        end
    end

    if self.btnToggle then
        local btnW   = ChaosUIManager.GetScaledWidth(50)
        local btnGap = ChaosUIManager.GetScaledWidth(4)
        local btnH   = self.toolbarH - self.margin * 2
        local btnY   = titleH + effectsAreaH + self.margin
        local groupX = math.floor((self.windowW - btnW * 2 - btnGap) / 2)

        self.btnToggle:setX(groupX)
        self.btnToggle:setY(btnY)
        self.btnToggle:setWidth(btnW)
        self.btnToggle:setHeight(btnH)

        if self.btnAnchor then
            self.btnAnchor:setX(groupX + btnW + btnGap)
            self.btnAnchor:setY(btnY)
            self.btnAnchor:setWidth(btnW)
            self.btnAnchor:setHeight(btnH)
        end
    end
end

function ChaosEffectsUI:prerender()
    ISPanel.prerender(self)

    local hovered = self:isMouseOver()
    self:setAdornmentsVisible(hovered)
    self:updateLayout()

    local effectsAreaH = self:getEffectsAreaH()
    local titleH = self.adornmentsVisible and self.titleBarH or 0

    -- Title bar
    if self.adornmentsVisible then
        self:drawRect(0, 0, self.width, self.titleBarH, 0.85, 0.12, 0.12, 0.12)
        local fh = getTextManager():getFontHeight(UIFont.Small)
        local textY = math.floor((self.titleBarH - fh) / 2)
        local titleStr = ChaosLocalization.GetString("core", "active_effects")
        self:drawText(titleStr, self.margin, textY, 1, 1, 1, 0.9, UIFont.Small)
    end

    -- Effect rows
    local activeEffects = ChaosEffectsManager.activeEffects
    local fontHeight = getTextManager():getFontHeight(UIFont.NewLarge)
    local rectW = self.windowW - self.margin * 2
    for i = 1, #activeEffects do
        local effect = activeEffects[i]
        local rowY = titleH + (i - 1) * (self.effectRowH + self.effectGap)

        local effectString = tostring(effect.effectName)
        if effect.withDuration then
            local msToEnd = effect.maxTicks - effect.ticksActiveTime
            effectString = string.format("%s (%.1fs)", effectString, msToEnd / 1000)
        end

        self:drawRect(self.margin, rowY, rectW, self.effectRowH, 0.7, 0.1, 0.1, 0.1)

        if effect.withDuration and effect.maxTicks > 0 then
            local progress = 1 - (effect.ticksActiveTime / effect.maxTicks)
            local fgWidth = math.floor(rectW * progress)
            if fgWidth > 0 then
                local c = ChaosConfig.ui.effect_progress_rgb
                self:drawRect(self.margin, rowY, fgWidth, self.effectRowH, 1, c.r, c.g, c.b)
            end
        end

        local textVertOffset = math.floor((self.effectRowH - fontHeight) / 2)
        local tc = ChaosConfig.ui.effect_progress_text_rgb
        self:drawText(effectString, self.margin + self.textPadH, rowY + textVertOffset, tc.r, tc.g, tc.b, 1, UIFont.NewLarge)
    end

    -- Toolbar background
    if self.adornmentsVisible then
        self:drawRect(0, titleH + effectsAreaH, self.width, self.toolbarH, 0.85, 0.12, 0.12, 0.12)
    end
end

function ChaosEffectsUI:onMouseDown(x, y)
    if self.adornmentsVisible and y <= self.titleBarH then
        self.dragging = true
        self:setCapture(true)
    end
    return true
end

function ChaosEffectsUI:onMouseUp(x, y)
    if self.dragging then
        self.dragging = false
        self:setCapture(false)
        self:updateAnchorFromPosition()
        local baseX = math.floor(self.x * (1920 / ChaosUIManager.cachedWidth))
        local baseY = math.floor(self.y * (1080 / ChaosUIManager.cachedHeight))
        print(string.format("[ChaosEffectsUI] Moved to screen (%d, %d), baseline 1920x1080: (%d, %d)", self.x, self.y,
            baseX, baseY))
    end
end

function ChaosEffectsUI:onMouseMove(dx, dy)
    if self.dragging then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
    end
end

function ChaosEffectsUI:onMouseMoveOutside(dx, dy)
    self:onMouseMove(dx, dy)
end

function ChaosEffectsUI:onToggleModeClick()
    if self.renderMode == "bottom_to_top" then
        self.renderMode = "top_to_bottom"
        self.btnToggle:setImage(getTexture("media/ui/chaos_icon_down.png"))
    else
        self.renderMode = "bottom_to_top"
        self.btnToggle:setImage(getTexture("media/ui/chaos_icon_up.png"))
    end
    self:updateAnchorFromPosition()
end

function ChaosEffectsUI:onToggleAnchorClick()
    self.anchorRight = not self.anchorRight
    if self.anchorRight then
        self.btnAnchor:setImage(getTexture("media/ui/chaos_icon_left.png"))
    else
        self.btnAnchor:setImage(getTexture("media/ui/chaos_icon_right.png"))
    end
    self:updateAnchorFromPosition()
end
