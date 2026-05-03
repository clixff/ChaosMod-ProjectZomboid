---@class RemoveCardItemPair
---@field [1] InventoryItem
---@field [2] InventoryItem

---@class EffectSelectCardRemoveItems : ChaosCardSelectEffect
---@field itemPairs RemoveCardItemPair[]
---@field cardItemPairs RemoveCardItemPair[]
---@field revealEndTimeMs integer | nil
---@field selectRandomCardWindow ChaosSelectRandomCardWindow | nil
EffectSelectCardRemoveItems = ChaosEffectBase:derive("EffectSelectCardRemoveItems", "select_card_remove_items")

function EffectSelectCardRemoveItems:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local allItems = {}
    ChaosPlayer.CollectAllItems(inventory, allItems)

    if #allItems < 2 then return end

    for i = #allItems, 2, -1 do
        local j = ChaosUtils.RandInteger(i) + 1
        allItems[i], allItems[j] = allItems[j], allItems[i]
    end

    self.itemPairs = {}
    for i = 1, 3 do
        local a = allItems[((i - 1) * 2) % #allItems + 1]
        local b = allItems[((i - 1) * 2 + 1) % #allItems + 1]
        self.itemPairs[i] = { a, b } --[[@as RemoveCardItemPair]]
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
            local n1 = pair[1]:getDisplayName() or "?"
            local n2 = pair[2]:getDisplayName() or "?"
            listedLabels[i] = n1 .. " + " .. n2
        end
    end
    for i = 1, 3 do
        local pair = self.cardItemPairs[i]
        if pair then
            local n1 = pair[1]:getDisplayName() or "?"
            local n2 = pair[2]:getDisplayName() or "?"
            cardLabels[i] = n1:gsub(" ", "\n") .. "\n+\n" .. n2:gsub(" ", "\n")
        end
    end

    self.selectedCardIndex = nil
    self.revealEndTimeMs = nil

    setGameSpeed(0)

    self.selectRandomCardWindow = ChaosSelectRandomCardWindow:new(self, {}, {})
    self.selectRandomCardWindow.title = "Select Items To Destroy"
    self.selectRandomCardWindow.listedLabels = listedLabels
    self.selectRandomCardWindow.cardLabels = cardLabels
    self.selectRandomCardWindow:initialise()
    self.selectRandomCardWindow:addToUIManager()
    self.selectRandomCardWindow:setVisible(true)
end

---@param cardIndex integer
function EffectSelectCardRemoveItems:onCardSelected(cardIndex)
    if self.selectedCardIndex then return end
    if not self.cardItemPairs then return end
    local pair = self.cardItemPairs[cardIndex]
    if not pair then return end

    self.selectedCardIndex = cardIndex
    self.revealEndTimeMs = getTimestampMs() + 3000

    setGameSpeed(1)

    local player = getPlayer()
    if not player then return end

    for _, item in ipairs(pair) do
        local container = item:getContainer()
        if container then
            local worn = player:getWornItems()
            if worn and worn:contains(item) then
                player:removeWornItem(item)
            end
            player:removeFromHands(item)
            container:Remove(item)
            ChaosPlayer.SayLineRemovedItem(player, item)
        end
    end
end

---@param deltaMs integer
function EffectSelectCardRemoveItems:OnTick(deltaMs)
    if not self.selectedCardIndex and (self.ticksActiveTime + deltaMs) >= self.maxTicks then
        self:onCardSelected(ChaosUtils.RandInteger(3) + 1)
        return
    end

    if not self.revealEndTimeMs then return end

    if getTimestampMs() >= self.revealEndTimeMs then
        ChaosEffectsManager.DisableSpecificEffects({ "select_card_remove_items" })
    end
end

function EffectSelectCardRemoveItems:OnEnd()
    ChaosEffectBase:OnEnd()
    setGameSpeed(1)

    if self.selectRandomCardWindow and not self.selectRandomCardWindow.resolved then
        self.selectRandomCardWindow.resolved = true
        self.selectRandomCardWindow:setVisible(false)
        self.selectRandomCardWindow:removeFromUIManager()
    end
    self.selectRandomCardWindow = nil
end
