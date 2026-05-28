require "ISUI/ISPanel"
require "ISUI/ISButton"

---@class ChaosLootboxRollWindow : ISPanel
---@field effect EffectLootboxRoll
---@field rollButton ISButton
---@field resolved boolean
ChaosLootboxRollWindow = ISPanel:derive("ChaosLootboxRollWindow")

local WINDOW_W = 600
local WINDOW_H = 380
local HEADER_Y = 24
local LINE_FIRST_Y = 90
local LINE_GAP = 45
local ICON_SIZE = 32
local ICON_TEXT_GAP = 8
local BTN_W = 220
local BTN_H = 44
local BTN_BOTTOM_PAD = 32

---@param effect EffectLootboxRoll
---@return ChaosLootboxRollWindow
function ChaosLootboxRollWindow:new(effect)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local x = math.floor((screenW - WINDOW_W) / 2)
    local y = math.floor((screenH - WINDOW_H) / 2)

    local o = ISPanel:new(x, y, WINDOW_W, WINDOW_H)
    setmetatable(o, self)
    self.__index = self
    ---@cast o ChaosLootboxRollWindow

    o.backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.95 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    o.moveWithMouse = false

    o.effect = effect
    o.resolved = false

    return o
end

function ChaosLootboxRollWindow:createChildren()
    local btnY = WINDOW_H - BTN_BOTTOM_PAD - BTN_H
    local btnX = math.floor((WINDOW_W - BTN_W) / 2)

    self.rollButton = ISButton:new(btnX, btnY, BTN_W, BTN_H, "Roll", self,
        ChaosLootboxRollWindow.onRollClicked)
    self.rollButton:initialise()
    self.rollButton:instantiate()
    self:addChild(self.rollButton)
end

function ChaosLootboxRollWindow:prerender()
    ISPanel.prerender(self)

    if not self.resolved and self.effect and self.effect.tickExpiry then
        self.effect:tickExpiry()
    end

    local header = "Lootbox Roll"
    local headerX = math.floor((WINDOW_W - getTextManager():MeasureStringX(UIFont.Large, header)) / 2)
    self:drawText(header, headerX, HEADER_Y, 1, 1, 1, 1, UIFont.Large)

    local entries = self.effect.entries or {}
    local total = self.effect.totalRolls or 0
    for i = 1, total do
        local entry = entries[i] or { text = "????" }
        local prefix = string.format("%d. ", i)
        local text = prefix .. (entry.text or "????")
        local textW = getTextManager():MeasureStringX(UIFont.NewLarge, text)

        local rolled = (self.effect.rollIndex or 0) >= i
        local scriptItem = rolled and entry.scriptItem or nil
        local hasIcon = scriptItem ~= nil
        local totalW = textW + (hasIcon and (ICON_SIZE + ICON_TEXT_GAP) or 0)
        local lineX = math.floor((WINDOW_W - totalW) / 2)
        local lineY = LINE_FIRST_Y + (i - 1) * LINE_GAP

        local r, g, b = 1.0, 1.0, 1.0
        if rolled then
            r, g, b = 0.2, 1.0, 0.2
        end

        local textX = lineX
        if scriptItem then
            local fontH = getTextManager():getFontHeight(UIFont.NewLarge)
            local iconY = lineY + math.floor((fontH - ICON_SIZE) / 2)
            self:drawScriptItemIcon(scriptItem, lineX, iconY, 1.0, ICON_SIZE, ICON_SIZE)
            textX = lineX + ICON_SIZE + ICON_TEXT_GAP
        end

        self:drawText(text, textX, lineY, r, g, b, 1, UIFont.NewLarge)
    end

    if self.rollButton then
        local rollIndex = self.effect.rollIndex or 0
        self.rollButton.enable = (rollIndex < total) and not self.resolved and not self.effect.finished
    end
end

function ChaosLootboxRollWindow.onRollClicked(self)
    if self.resolved then return end
    self.effect:onRollPressed()
end
