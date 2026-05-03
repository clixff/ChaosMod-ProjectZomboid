---@class SelectCardItemPair
---@field id1 string
---@field id2 string
---@field name1 string
---@field name2 string

---@class EffectSelectCardAddItems : ChaosCardSelectEffect
---@field itemPairs SelectCardItemPair[]
---@field cardItemPairs SelectCardItemPair[]
---@field revealEndTimeMs integer | nil
---@field selectRandomCardWindow ChaosSelectRandomCardWindow | nil
EffectSelectCardAddItems = ChaosEffectBase:derive("EffectSelectCardAddItems", "select_card_add_items")

---@param id string
---@return string
local function getItemDisplayName(id)
    local item = instanceItem(id)
    return item and item:getDisplayName() or id
end

function EffectSelectCardAddItems:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    self.itemPairs = {}
    for i = 1, 3 do
        local id1 = GetRandomLootboxItem()
        local id2 = GetRandomLootboxItem()
        self.itemPairs[i] = {
            id1 = id1,
            id2 = id2,
            name1 = getItemDisplayName(id1),
            name2 = getItemDisplayName(id2),
        }
    end

    self.cardItemPairs = {}
    for i = 1, 3 do self.cardItemPairs[i] = self.itemPairs[i] end
    for i = 3, 2, -1 do
        local j = ChaosUtils.RandInteger(i) + 1
        self.cardItemPairs[i], self.cardItemPairs[j] = self.cardItemPairs[j], self.cardItemPairs[i]
    end

    local listedLabels = {}
    local cardLabels = {}
    for i = 1, 3 do
        local pair = self.itemPairs[i]
        if pair then
            listedLabels[i] = pair.name1 .. " + " .. pair.name2
        end
    end
    for i = 1, 3 do
        local pair = self.cardItemPairs[i]
        if pair then
            cardLabels[i] = pair.name1:gsub(" ", "\n") .. "\n+\n" .. pair.name2:gsub(" ", "\n")
        end
    end

    self.selectedCardIndex = nil
    self.revealEndTimeMs = nil

    setGameSpeed(0)

    self.selectRandomCardWindow = ChaosSelectRandomCardWindow:new(self, {}, {})
    self.selectRandomCardWindow.title = "Select Items To Add"
    self.selectRandomCardWindow.listedLabels = listedLabels
    self.selectRandomCardWindow.cardLabels = cardLabels
    self.selectRandomCardWindow:initialise()
    self.selectRandomCardWindow:addToUIManager()
    self.selectRandomCardWindow:setVisible(true)
end

---@param cardIndex integer
function EffectSelectCardAddItems:onCardSelected(cardIndex)
    if self.selectedCardIndex then return end
    if not self.cardItemPairs then return end
    local pair = self.cardItemPairs[cardIndex]
    if not pair then return end

    self.selectedCardIndex = cardIndex
    self.revealEndTimeMs = getTimestampMs() + 3000

    setGameSpeed(1)

    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local item1 = inventory:AddItem(pair.id1)
    if item1 then ChaosPlayer.SayLineNewItem(player, item1) end

    local item2 = inventory:AddItem(pair.id2)
    if item2 then ChaosPlayer.SayLineNewItem(player, item2) end
end

---@param deltaMs integer
function EffectSelectCardAddItems:OnTick(deltaMs)
    if not self.selectedCardIndex and (self.ticksActiveTime + deltaMs) >= self.maxTicks then
        self:onCardSelected(ChaosUtils.RandInteger(3) + 1)
        return
    end

    if not self.revealEndTimeMs then return end

    if getTimestampMs() >= self.revealEndTimeMs then
        ChaosEffectsManager.DisableSpecificEffects({ "select_card_add_items" })
    end
end

function EffectSelectCardAddItems:OnEnd()
    ChaosEffectBase:OnEnd()
    setGameSpeed(1)

    if self.selectRandomCardWindow and not self.selectRandomCardWindow.resolved then
        self.selectRandomCardWindow.resolved = true
        self.selectRandomCardWindow:setVisible(false)
        self.selectRandomCardWindow:removeFromUIManager()
    end
    self.selectRandomCardWindow = nil
end
