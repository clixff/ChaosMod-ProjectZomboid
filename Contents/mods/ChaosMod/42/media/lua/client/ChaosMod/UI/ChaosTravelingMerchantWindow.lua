require "ISUI/ISPanel"
require "ISUI/ISButton"

---@class TravelingMerchantCardItem
---@field id string
---@field name string
---@field scriptItem Item | nil

---@class TravelingMerchantCard
---@field rarity string
---@field price integer
---@field item TravelingMerchantCardItem | nil
---@field maxPurchases integer
---@field purchasesLeft integer

---@class ChaosTravelingMerchantWindow : ISPanel
---@field effect EffectTravelingMerchant
---@field buyButtons ISButton[]
---@field closeButton ISButton
---@field resolved boolean
ChaosTravelingMerchantWindow = ISPanel:derive("ChaosTravelingMerchantWindow")

local WINDOW_W = 900
local WINDOW_H = 560
local PAD = 28
local CARD_GAP = 20
local CARD_TOP = 90
local CARD_H = 360
local CARD_BTN_H = 36
local CLOSE_BTN_W = 200
local CLOSE_BTN_H = 40
local CLOSE_BTN_BOTTOM_PAD = 20
local ICON_SIZE = 64

local RARITY_LABELS = {
    common = "Common",
    uncommon = "Uncommon",
    rare = "Rare",
    legendary = "Legendary",
}

---@param effect EffectTravelingMerchant
---@return ChaosTravelingMerchantWindow
function ChaosTravelingMerchantWindow:new(effect)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local x = math.floor((screenW - WINDOW_W) / 2)
    local y = math.floor((screenH - WINDOW_H) / 2)

    local o = ISPanel:new(x, y, WINDOW_W, WINDOW_H)
    setmetatable(o, self)
    self.__index = self
    ---@cast o ChaosTravelingMerchantWindow

    o.backgroundColor = { r = 0.02, g = 0.02, b = 0.02, a = 0.95 }
    o.borderColor = { r = 1, g = 1, b = 1, a = 1 }
    o.moveWithMouse = false

    o.effect = effect
    o.buyButtons = {}
    o.resolved = false

    return o
end

function ChaosTravelingMerchantWindow:createChildren()
    local cardW = math.floor((WINDOW_W - PAD * 2 - CARD_GAP * 2) / 3)
    local btnY = CARD_TOP + CARD_H - CARD_BTN_H - 16

    for i = 1, 3 do
        local cardX = PAD + (i - 1) * (cardW + CARD_GAP)
        local button = ISButton:new(cardX + 16, btnY, cardW - 32, CARD_BTN_H, "Buy", self,
            ChaosTravelingMerchantWindow.onBuyClicked)
        button:initialise()
        button:instantiate()
        ---@diagnostic disable-next-line: inject-field
        button.cardIndex = i
        self.buyButtons[i] = button
        self:addChild(button)
    end

    local closeX = math.floor((WINDOW_W - CLOSE_BTN_W) / 2)
    local closeY = WINDOW_H - CLOSE_BTN_H - CLOSE_BTN_BOTTOM_PAD
    self.closeButton = ISButton:new(closeX, closeY, CLOSE_BTN_W, CLOSE_BTN_H, "Close", self,
        ChaosTravelingMerchantWindow.onCloseClicked)
    self.closeButton:initialise()
    self.closeButton:instantiate()
    self:addChild(self.closeButton)
end

function ChaosTravelingMerchantWindow:prerender()
    ISPanel.prerender(self)

    if not self.resolved and self.effect and self.effect.tickExpiry then
        self.effect:tickExpiry()
    end

    local player = getPlayer()
    local currency = player and ChaosKillsCount.getPlayerKillsCountCurrency(player) or 0

    local killsLabel = string.format("Zombie Kills: %d", currency)
    self:drawText(killsLabel, PAD, 22, 1, 1, 0.4, 1, UIFont.Medium)

    local title = "Traveling Merchant"
    local titleX = math.floor((WINDOW_W - getTextManager():MeasureStringX(UIFont.Large, title)) / 2)
    self:drawText(title, titleX, 18, 1, 1, 1, 1, UIFont.Large)

    self:drawCards(currency)
end

---@param currency integer
function ChaosTravelingMerchantWindow:drawCards(currency)
    local cards = self.effect.cards or {}
    local cardW = math.floor((WINDOW_W - PAD * 2 - CARD_GAP * 2) / 3)

    for i = 1, 3 do
        local card = cards[i]
        local cardX = PAD + (i - 1) * (cardW + CARD_GAP)

        self:drawRectBorder(cardX, CARD_TOP, cardW, CARD_H, 1, 1, 1, 1)
        self:drawRect(cardX + 1, CARD_TOP + 1, cardW - 2, CARD_H - 2, 0.88, 0.08, 0.08, 0.08)

        local headerText = card and (RARITY_LABELS[card.rarity] or card.rarity) or "?"
        local headerR, headerG, headerB = 0.9, 0.9, 0.9
        if card then
            if card.rarity == "common" then
                headerR, headerG, headerB = 0.85, 0.85, 0.85
            elseif card.rarity == "uncommon" then
                headerR, headerG, headerB = 0.3, 1.0, 0.4
            elseif card.rarity == "rare" then
                headerR, headerG, headerB = 0.4, 0.6, 1.0
            elseif card.rarity == "legendary" then
                headerR, headerG, headerB = 1.0, 0.6, 0.1
            end
        end
        local headerX = cardX + math.floor((cardW - getTextManager():MeasureStringX(UIFont.NewMedium, headerText)) / 2)
        self:drawText(headerText, headerX, CARD_TOP + 14, headerR, headerG, headerB, 1, UIFont.NewMedium)

        if card and card.item then
            local iconX = cardX + math.floor((cardW - ICON_SIZE) / 2)
            local iconY = CARD_TOP + 56
            if card.item.scriptItem then
                self:drawScriptItemIcon(card.item.scriptItem, iconX, iconY, 1.0, ICON_SIZE, ICON_SIZE)
            end

            local nameText = card.item.name or card.item.id or "?"
            local nameX = cardX + math.floor((cardW - getTextManager():MeasureStringX(UIFont.Medium, nameText)) / 2)
            self:drawText(nameText, nameX, iconY + ICON_SIZE + 12, 1, 1, 1, 1, UIFont.Medium)

            local remainingText = string.format("Remaining: %d / %d",
                card.purchasesLeft or 0, card.maxPurchases or 0)
            local remainingX = cardX + math.floor((cardW - getTextManager():MeasureStringX(UIFont.Small, remainingText)) / 2)
            self:drawText(remainingText, remainingX, iconY + ICON_SIZE + 44, 0.85, 0.85, 0.85, 1, UIFont.Small)
        end

        local soldOut = card and (card.purchasesLeft or 0) <= 0
        local priceText
        if soldOut then
            priceText = "Sold Out"
        else
            priceText = string.format("Price: %d", card and card.price or 0)
        end
        local priceX = cardX + math.floor((cardW - getTextManager():MeasureStringX(UIFont.NewMedium, priceText)) / 2)
        self:drawText(priceText, priceX, CARD_TOP + CARD_H - CARD_BTN_H - 44, 1, 0.95, 0.4, 1, UIFont.NewMedium)

        local button = self.buyButtons[i]
        if button then
            local canBuy = card ~= nil and not soldOut and currency >= (card.price or 0) and card.item ~= nil
            button.enable = canBuy and not self.resolved
        end
    end
end

function ChaosTravelingMerchantWindow.onBuyClicked(self, button)
    if self.resolved then return end
    if not button or not button.cardIndex then return end
    self.effect:onBuyPressed(button.cardIndex)
end

function ChaosTravelingMerchantWindow.onCloseClicked(self)
    if self.resolved then return end
    self.effect:onClosePressed()
end
