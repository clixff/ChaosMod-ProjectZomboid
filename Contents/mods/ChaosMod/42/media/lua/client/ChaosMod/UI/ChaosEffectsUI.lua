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

ChaosEffectsUI.hideEffectNames = false

local MIN_WINDOW_W = 280

-- Meta progress-bar animated gradient anchors (~2s period).
-- Start: orange. End: default red progress-bar color (hex 9f211f).
local META_GRADIENT_PERIOD_MS = 2000
local META_GRADIENT_START = { r = 1.0, g = 0.45, b = 0.05 }
local META_GRADIENT_END = { r = 159 / 255, g = 33 / 255, b = 31 / 255 }

--- Returns the current frame's lerped meta-gradient color. Phase is driven off
--- getTimestampMs so the global HUD bar and every meta effect row pulse in
--- lockstep.
---@return table -- {r, g, b} color table
function ChaosEffectsUI.GetMetaGradientColor()
    local phase = (getTimestampMs() % META_GRADIENT_PERIOD_MS) / META_GRADIENT_PERIOD_MS
    local t = 0.5 - 0.5 * math.cos(2 * math.pi * phase)
    return ChaosUtils.LerpColor(META_GRADIENT_START, META_GRADIENT_END, t)
end

---@param effect ChaosEffectBase
---@return boolean
local function shouldHideEffectName(effect)
    if effect.showNameAlways then
        return false
    end
    return ChaosEffectsUI.hideEffectNames or ChaosConfig.hide_effect_names == true
end

---@param effect ChaosEffectBase
---@return string
local function buildEffectString(effect)
    if shouldHideEffectName(effect) then
        return "???"
    end
    local effectString
    if effect.fakeEffectNameId and effect.fakeEffectNameId ~= "" then
        effectString = ChaosLocalization.GetString("effects", effect.fakeEffectNameId)
    else
        effectString = tostring(effect.effectName)
    end
    if effect.uiRevealPrefix and effect.uiRevealPrefix ~= "" then
        effectString = effect.uiRevealPrefix .. effectString
    end
    if effect.withDuration then
        local msToEnd = effect.maxTicks - effect.ticksActiveTime
        if effect.effectNickname and effect.effectNickname ~= "" then
            effectString = string.format("%s %.1fs (%s)", effectString, msToEnd / 1000, effect.effectNickname)
        else
            effectString = string.format("%s (%.1fs)", effectString, msToEnd / 1000)
        end
    elseif effect.effectNickname and effect.effectNickname ~= "" then
        effectString = string.format("%s (%s)", effectString, effect.effectNickname)
    end
    return effectString
end

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

--- Builds a row for a meta effect. Meta rows are always visible and use the
--- hardcoded "[META] {name} (Ns)" format regardless of hide_effect_names.
---@param meta ChaosMetaEffectBase
---@return string
local function buildMetaEffectString(meta)
    local msToEnd = meta.maxTicks - meta.ticksActiveTime
    if msToEnd < 0 then msToEnd = 0 end
    return string.format("[META] %s (%.1fs)", tostring(meta.effectName), msToEnd / 1000)
end

--- Builds the list of rows to render: meta effects (always shown, prepended),
--- visible (non-concealed) real effects, plus fake decoy rows. Concealed
--- (uiHidden) regular effects are omitted.
---@return { text: string, effect: ChaosEffectBase | nil, meta: ChaosMetaEffectBase | nil }[]
function ChaosEffectsUI:buildRenderRows()
    local rows = {}
    if ChaosMetaEffectsManager and ChaosMetaEffectsManager.activeEffects then
        for i = 1, #ChaosMetaEffectsManager.activeEffects do
            local meta = ChaosMetaEffectsManager.activeEffects[i]
            if meta then
                rows[#rows + 1] = { text = buildMetaEffectString(meta), effect = nil, meta = meta }
            end
        end
    end
    local activeEffects = ChaosEffectsManager.activeEffects
    for i = 1, #activeEffects do
        local effect = activeEffects[i]
        if effect and not effect.uiHidden then
            rows[#rows + 1] = { text = buildEffectString(effect), effect = effect, meta = nil }
        end
    end
    local fakeVisuals = ChaosEffectsManager.fakeVisualEffects
    if fakeVisuals then
        for i = 1, #fakeVisuals do
            local fv = fakeVisuals[i]
            if fv then
                rows[#rows + 1] = { text = tostring(fv.displayName), effect = nil, meta = nil }
            end
        end
    end
    return rows
end

function ChaosEffectsUI:getEffectsAreaH()
    local N = #self:buildRenderRows()
    if N == 0 then
        return self.effectRowH
    end
    return N * self.effectRowH + (N - 1) * self.effectGap
end

function ChaosEffectsUI:computeWindowW()
    local minW = ChaosUIManager.GetScaledWidth(MIN_WINDOW_W)
    local maxTextW = 0
    local rows = self:buildRenderRows()
    for i = 1, #rows do
        local tw = getTextManager():MeasureStringX(UIFont.NewLarge, rows[i].text)
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
    local rows = self:buildRenderRows()
    local fontHeight = getTextManager():getFontHeight(UIFont.NewLarge)
    local rectW = self.windowW - self.margin * 2
    local metaColor = ChaosEffectsUI.GetMetaGradientColor()
    for i = 1, #rows do
        local effect = rows[i].effect
        local meta = rows[i].meta
        local effectString = rows[i].text
        local rowY = titleH + (i - 1) * (self.effectRowH + self.effectGap)

        self:drawRect(self.margin, rowY, rectW, self.effectRowH, 0.7, 0.1, 0.1, 0.1)

        if meta and meta.maxTicks > 0 then
            local progress = 1 - (meta.ticksActiveTime / meta.maxTicks)
            if progress < 0 then progress = 0 end
            local fgWidth = math.floor(rectW * progress)
            if fgWidth > 0 then
                self:drawRect(self.margin, rowY, fgWidth, self.effectRowH, 1, metaColor.r, metaColor.g, metaColor.b)
            end
        elseif effect and effect.withDuration and effect.maxTicks > 0 and not shouldHideEffectName(effect) then
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
