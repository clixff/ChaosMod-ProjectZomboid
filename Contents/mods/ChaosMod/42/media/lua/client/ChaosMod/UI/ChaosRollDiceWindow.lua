require "ISUI/ISPanel"
require "ISUI/ISButton"

---@class ChaosRollDiceWindow : ISPanel
---@field effect EffectRollDice
---@field listedEffectIds string[]
---@field listedEffectNames string[]
---@field rollButton ISButton
---@field resolved boolean
ChaosRollDiceWindow = ISPanel:derive("ChaosRollDiceWindow")

local WINDOW_W = 560
local WINDOW_H = 620
local PAD = 28
local LIST_TOP = 64
local LIST_ITEM_H = 30
local DICE_SIZE = 170
local DICE_TOP_PAD = 24
local BTN_W = 180
local BTN_H = 40
local BTN_TOP_PAD = 18

local WINNER_R, WINNER_G, WINNER_B = 1.0, 0.84, 0.2

---@param effect EffectRollDice
---@param listedEffectIds string[]
---@return ChaosRollDiceWindow
function ChaosRollDiceWindow:new(effect, listedEffectIds)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local x = math.floor((screenW - WINDOW_W) / 2)
    local y = math.floor((screenH - WINDOW_H) / 2)

    local o = ISPanel:new(x, y, WINDOW_W, WINDOW_H)
    setmetatable(o, self)
    self.__index = self
    ---@cast o ChaosRollDiceWindow

    o.backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.95 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    o.moveWithMouse = false

    o.effect = effect
    o.listedEffectIds = listedEffectIds or {}
    o.listedEffectNames = {}
    o.resolved = false

    for i = 1, #o.listedEffectIds do
        local id = o.listedEffectIds[i]
        if id then
            local effectData = ChaosEffectsRegistry.effects[id]
            o.listedEffectNames[i] = (effectData and effectData.name) or id
        else
            o.listedEffectNames[i] = "-"
        end
    end

    return o
end

function ChaosRollDiceWindow:createChildren()
    local listCount = math.max(#self.listedEffectNames, 6)
    local diceY = LIST_TOP + listCount * LIST_ITEM_H + DICE_TOP_PAD
    local btnY = diceY + DICE_SIZE + BTN_TOP_PAD
    local btnX = math.floor((WINDOW_W - BTN_W) / 2)

    self.rollButton = ISButton:new(btnX, btnY, BTN_W, BTN_H, "Roll", self,
        ChaosRollDiceWindow.onRollClicked)
    self.rollButton:initialise()
    self.rollButton:instantiate()
    self:addChild(self.rollButton)
end

function ChaosRollDiceWindow:prerender()
    ISPanel.prerender(self)

    if not self.resolved and self.effect then
        self.effect:updateRollPhase()
    end

    local title = "Roll The Dice"
    local titleX = math.floor((WINDOW_W - getTextManager():MeasureStringX(UIFont.Large, title)) / 2)
    self:drawText(title, titleX, 18, 1, 1, 1, 1, UIFont.Large)

    local phase = self.effect.rollDicePhase
    local winnerIndex = self.effect.winnerIndex

    for i = 1, #self.listedEffectNames do
        local label = string.format("%d. %s", i, self.listedEffectNames[i] or "")
        local r, g, b = 1.0, 1.0, 1.0
        if (phase == "revealing" or phase == "completed") and winnerIndex == i then
            r, g, b = WINNER_R, WINNER_G, WINNER_B
        end
        self:drawText(label, PAD, LIST_TOP + (i - 1) * LIST_ITEM_H, r, g, b, 1, UIFont.Medium)
    end

    self:drawDice()

    if self.rollButton then
        self.rollButton.enable = (phase == "idle")
    end
end

function ChaosRollDiceWindow:drawDice()
    local listCount = math.max(#self.listedEffectNames, 6)
    local diceY = LIST_TOP + listCount * LIST_ITEM_H + DICE_TOP_PAD
    local diceX = math.floor((WINDOW_W - DICE_SIZE) / 2)

    local phase = self.effect.rollDicePhase
    local isReveal = (phase == "revealing" or phase == "completed")

    local borderR, borderG, borderB = 1.0, 1.0, 1.0
    if isReveal then
        borderR, borderG, borderB = WINNER_R, WINNER_G, WINNER_B
    end

    self:drawRectBorder(diceX, diceY, DICE_SIZE, DICE_SIZE, 1, borderR, borderG, borderB)
    if isReveal then
        self:drawRectBorder(diceX + 1, diceY + 1, DICE_SIZE - 2, DICE_SIZE - 2, 1, borderR, borderG, borderB)
        self:drawRectBorder(diceX + 2, diceY + 2, DICE_SIZE - 4, DICE_SIZE - 4, 1, borderR, borderG, borderB)
    end
    self:drawRect(diceX + 3, diceY + 3, DICE_SIZE - 6, DICE_SIZE - 6, 0.95, 0.08, 0.08, 0.08)

    local text
    if phase == "rolling" or phase == "revealing" or phase == "completed" then
        text = tostring(self.effect.currentDiceFace or "?")
    else
        text = "?"
    end

    local textR, textG, textB = 1.0, 1.0, 1.0
    if isReveal then
        textR, textG, textB = WINNER_R, WINNER_G, WINNER_B
    end

    local font = UIFont.Massive
    local textW = getTextManager():MeasureStringX(font, text)
    local textH = getTextManager():getFontHeight(font)
    local textX = diceX + math.floor((DICE_SIZE - textW) / 2)
    local textY = diceY + math.floor((DICE_SIZE - textH) / 2)
    self:drawText(text, textX, textY, textR, textG, textB, 1, font)
end

function ChaosRollDiceWindow.onRollClicked(self)
    if self.resolved then return end
    if self.effect.rollDicePhase ~= "idle" then return end
    self.effect:onRollPressed()
end
