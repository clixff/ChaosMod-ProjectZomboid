---@class EffectTravelingMerchant : ChaosEffectBase
---@field cards TravelingMerchantCard[]
---@field window ChaosTravelingMerchantWindow | nil
---@field finished boolean
---@field startTimeMs integer
EffectTravelingMerchant = ChaosEffectBase:derive("EffectTravelingMerchant", "traveling_merchant")

local CARD_MAX_PURCHASES = { 4, 2, 1 }

local RARITY_PRICES = {
    common = 5,
    uncommon = 10,
    rare = 20,
    legendary = 30,
}

---@param rarity string
---@return TravelingMerchantCardItem | nil
local function rollItemFromPool(rarity)
    local pool = LOOTBOX_ITEMS[rarity]
    if not pool or #pool == 0 then return nil end
    local id = pool[ChaosUtils.RandArrayIndex(pool)]
    local item = instanceItem(id)
    local name = item and item:getDisplayName() or id
    local scriptItem = getItem(id)
    return { id = id, name = name, scriptItem = scriptItem }
end

function EffectTravelingMerchant:OnStart()
    ChaosEffectBase:OnStart()

    setGameSpeed(0)

    local secondRarity = ChaosUtils.RandInteger(2) == 0 and "uncommon" or "rare"

    ---@type string[]
    local rarities = { "common", secondRarity, "legendary" }
    self.cards = {}
    for i = 1, 3 do
        local rarity = rarities[i] or "common"
        local maxPurchases = CARD_MAX_PURCHASES[i] or 1
        ---@type TravelingMerchantCard
        local card = {
            rarity = rarity,
            price = RARITY_PRICES[rarity] or 0,
            item = rollItemFromPool(rarity),
            maxPurchases = maxPurchases,
            purchasesLeft = maxPurchases,
        }
        self.cards[i] = card
    end

    self.finished = false
    self.startTimeMs = getTimestampMs()

    self.window = ChaosTravelingMerchantWindow:new(self)
    self.window:initialise()
    self.window:addToUIManager()
    self.window:setVisible(true)
end

---@param cardIndex integer
function EffectTravelingMerchant:onBuyPressed(cardIndex)
    if self.finished then return end
    local card = self.cards and self.cards[cardIndex]
    if not card or not card.item or card.purchasesLeft <= 0 then return end

    local player = getPlayer()
    if not player then return end

    if not ChaosKillsCount.hasEnoughCurrency(player, card.price) then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local item = inventory:AddItem(card.item.id)
    if not item then return end

    ChaosKillsCount.spendKills(player, card.price)
    card.purchasesLeft = card.purchasesLeft - 1

    ChaosPlayer.SayLineNewItem(player, item)

    if item then
        ChaosItems.SetFullAmmoIfWeapon(item)
    end
end

function EffectTravelingMerchant:onClosePressed()
    if self.finished then return end
    self.finished = true
    ChaosEffectsManager.DisableSpecificEffects({ "traveling_merchant" })
end

--- Drives expiry from the window's prerender so timers fire while the game is
--- paused via setGameSpeed(0) — Events.OnTick does not advance reliably then.
function EffectTravelingMerchant:tickExpiry()
    if self.finished then return end

    local now = getTimestampMs()
    local maxMs = math.floor((self.duration or 0) * 1000)
    if maxMs > 0 and (now - (self.startTimeMs or 0)) >= maxMs then
        self.finished = true
        ChaosEffectsManager.DisableSpecificEffects({ "traveling_merchant" })
    end
end

---@param deltaMs integer
function EffectTravelingMerchant:OnTick(deltaMs)
end

function EffectTravelingMerchant:closeWindow()
    if self.window and not self.window.resolved then
        self.window.resolved = true
        self.window:setVisible(false)
        self.window:removeFromUIManager()
    end
    self.window = nil
end

function EffectTravelingMerchant:OnEnd()
    ChaosEffectBase:OnEnd()
    self:closeWindow()
    setGameSpeed(1)
end
