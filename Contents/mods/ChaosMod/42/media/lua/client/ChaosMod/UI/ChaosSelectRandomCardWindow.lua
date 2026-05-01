require "ISUI/ISPanel"
require "ISUI/ISButton"

---@class ChaosSelectRandomCardWindow : ISPanel
---@field effect EffectSelectRandomCard
---@field listedEffectIds string[]
---@field cardEffectIds string[]
---@field listedEffectNames string[]
---@field cardEffectNames string[]
---@field selectButtons ISButton[]
---@field resolved boolean
ChaosSelectRandomCardWindow = ISPanel:derive("ChaosSelectRandomCardWindow")

local WINDOW_W = 860
local WINDOW_H = 520
local PAD = 28
local CARD_GAP = 20
local CARD_H = 220
local CARD_BTN_H = 36

---@param effect EffectSelectRandomCard
---@param listedEffectIds string[]
---@param cardEffectIds string[]
---@return ChaosSelectRandomCardWindow
function ChaosSelectRandomCardWindow:new(effect, listedEffectIds, cardEffectIds)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local x = math.floor((screenW - WINDOW_W) / 2)
    local y = math.floor((screenH - WINDOW_H) / 2)

    local o = ISPanel:new(x, y, WINDOW_W, WINDOW_H)
    setmetatable(o, self)
    self.__index = self
    ---@cast o ChaosSelectRandomCardWindow

    o.backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.95 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    o.moveWithMouse = false

    o.effect = effect
    o.listedEffectIds = listedEffectIds or {}
    o.cardEffectIds = cardEffectIds or {}
    o.listedEffectNames = {}
    o.cardEffectNames = {}
    o.selectButtons = {}
    o.resolved = false

    for i = 1, #o.listedEffectIds do
        local effectData = ChaosEffectsRegistry.effects[o.listedEffectIds[i]]
        o.listedEffectNames[i] = effectData and effectData.name or o.listedEffectIds[i]
    end

    for i = 1, #o.cardEffectIds do
        local effectData = ChaosEffectsRegistry.effects[o.cardEffectIds[i]]
        o.cardEffectNames[i] = effectData and effectData.name or o.cardEffectIds[i]
    end

    return o
end

function ChaosSelectRandomCardWindow:createChildren()
    local cardW = math.floor((WINDOW_W - PAD * 2 - CARD_GAP * 2) / 3)
    local cardsY = 220

    for i = 1, 3 do
        local cardX = PAD + (i - 1) * (cardW + CARD_GAP)
        local btnY = cardsY + CARD_H - CARD_BTN_H - 16
        local button = ISButton:new(cardX + 16, btnY, cardW - 32, CARD_BTN_H, "Select", self,
            ChaosSelectRandomCardWindow.onSelectClicked)
        button:initialise()
        button:instantiate()
        button.cardIndex = i
        self.selectButtons[i] = button
        self:addChild(button)
    end
end

function ChaosSelectRandomCardWindow:prerender()
    ISPanel.prerender(self)

    local title = "Select a card"
    local titleX = math.floor((WINDOW_W - getTextManager():MeasureStringX(UIFont.Large, title)) / 2)
    self:drawText(title, titleX, 18, 1, 1, 1, 1, UIFont.Large)

    for i = 1, math.min(3, #self.listedEffectNames) do
        local label = string.format("%d. %s", i, self.listedEffectNames[i] or "")
        self:drawText(label, PAD, 62 + (i - 1) * 38, 1, 1, 1, 1, UIFont.Medium)
    end

    self:drawCards()
end

function ChaosSelectRandomCardWindow:drawCards()
    local cardW = math.floor((WINDOW_W - PAD * 2 - CARD_GAP * 2) / 3)
    local cardsY = 220
    local revealCards = self.effect.selectedCardIndex ~= nil

    for i = 1, 3 do
        local cardX = PAD + (i - 1) * (cardW + CARD_GAP)
        self:drawRectBorder(cardX, cardsY, cardW, CARD_H, 1, 1, 1, 1)
        self:drawRect(cardX + 1, cardsY + 1, cardW - 2, CARD_H - 2, 0.88, 0.08, 0.08, 0.08)

        local cardTitle = string.format("Card %d", i)
        local cardTitleX = cardX + math.floor((cardW - getTextManager():MeasureStringX(UIFont.NewMedium, cardTitle)) / 2)
        self:drawText(cardTitle, cardTitleX, cardsY + 18, 0.9, 0.9, 0.9, 1, UIFont.NewMedium)

        local effectText = revealCards and (self.cardEffectNames[i] or "") or "?????"
        local effectTextX = cardX + math.floor((cardW - getTextManager():MeasureStringX(UIFont.NewLarge, effectText)) / 2)
        local textR, textG, textB = 1, 1, 1
        if revealCards and self.effect.selectedCardIndex == i then
            textR, textG, textB = 0.2, 1.0, 0.2
        end
        self:drawText(effectText, effectTextX, cardsY + 88, textR, textG, textB, 1, UIFont.NewLarge)

        local button = self.selectButtons[i]
        if button then
            button.enable = not revealCards and self.cardEffectIds[i] ~= nil
            button:setVisible(not revealCards)
        end
    end
end

function ChaosSelectRandomCardWindow.onSelectClicked(self, button)
    if self.resolved then return end
    if self.effect.selectedCardIndex then return end
    if not button or not button.cardIndex then return end

    self.effect:onCardSelected(button.cardIndex)
end
