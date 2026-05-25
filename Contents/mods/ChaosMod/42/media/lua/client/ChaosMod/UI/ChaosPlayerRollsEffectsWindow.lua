require "ISUI/ISPanel"
require "ISUI/ISButton"

---@class ChaosPlayerRollsEffectsWindow : ISPanel
---@field effect EffectPlayerRollsEffects
---@field activateButton ISButton
---@field rollButton ISButton
---@field resolved boolean
ChaosPlayerRollsEffectsWindow = ISPanel:derive("ChaosPlayerRollsEffectsWindow")

local WINDOW_W = 600
local WINDOW_H = 280
local HEADER_Y = 24
local EFFECT_NAME_Y = 110
local BTN_W = 220
local BTN_H = 44
local BTN_GAP = 24
local BTN_BOTTOM_PAD = 32

---@param effect EffectPlayerRollsEffects
---@return ChaosPlayerRollsEffectsWindow
function ChaosPlayerRollsEffectsWindow:new(effect)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local x = math.floor((screenW - WINDOW_W) / 2)
    local y = math.floor((screenH - WINDOW_H) / 2)

    local o = ISPanel:new(x, y, WINDOW_W, WINDOW_H)
    setmetatable(o, self)
    self.__index = self
    ---@cast o ChaosPlayerRollsEffectsWindow

    o.backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.95 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    o.moveWithMouse = false

    o.effect = effect
    o.resolved = false

    return o
end

function ChaosPlayerRollsEffectsWindow:createChildren()
    local btnY = WINDOW_H - BTN_BOTTOM_PAD - BTN_H
    local totalBtnW = BTN_W * 2 + BTN_GAP
    local startX = math.floor((WINDOW_W - totalBtnW) / 2)

    self.activateButton = ISButton:new(startX, btnY, BTN_W, BTN_H, "Activate", self,
        ChaosPlayerRollsEffectsWindow.onActivateClicked)
    self.activateButton:initialise()
    self.activateButton:instantiate()
    self:addChild(self.activateButton)

    self.rollButton = ISButton:new(startX + BTN_W + BTN_GAP, btnY, BTN_W, BTN_H, "Roll", self,
        ChaosPlayerRollsEffectsWindow.onRollClicked)
    self.rollButton:initialise()
    self.rollButton:instantiate()
    self:addChild(self.rollButton)
end

function ChaosPlayerRollsEffectsWindow:prerender()
    ISPanel.prerender(self)

    if not self.resolved and self.effect and self.effect.tickExpiry then
        self.effect:tickExpiry()
    end

    local header = string.format("Reroll: %d", self.effect.rerollsLeft or 0)
    local headerX = math.floor((WINDOW_W - getTextManager():MeasureStringX(UIFont.Large, header)) / 2)
    self:drawText(header, headerX, HEADER_Y, 1, 1, 1, 1, UIFont.Large)

    local effectText = "?????"
    if self.effect.rolledEffectId then
        local data = ChaosEffectsRegistry.effects[self.effect.rolledEffectId]
        effectText = (data and data.name) or self.effect.rolledEffectId
    end

    local effectX = math.floor((WINDOW_W - getTextManager():MeasureStringX(UIFont.NewLarge, effectText)) / 2)
    self:drawText(effectText, effectX, EFFECT_NAME_Y, 0.2, 1.0, 0.2, 1, UIFont.NewLarge)

    if self.activateButton then
        self.activateButton.enable = (self.effect.rolledEffectId ~= nil) and not self.resolved
    end

    if self.rollButton then
        local hasRolled = self.effect.rolledEffectId ~= nil
        local rerollsLeft = self.effect.rerollsLeft or 0
        self.rollButton.enable = (rerollsLeft > 0) and not self.resolved
        self.rollButton:setTitle(hasRolled and "Reroll" or "Roll")
    end
end

function ChaosPlayerRollsEffectsWindow.onActivateClicked(self)
    if self.resolved then return end
    self.effect:onActivatePressed()
end

function ChaosPlayerRollsEffectsWindow.onRollClicked(self)
    if self.resolved then return end
    self.effect:onRollPressed()
end
