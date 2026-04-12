EffectBreakAllItems = ChaosEffectBase:derive("EffectBreakAllItems", "break_all_items")

---@param item InventoryItem
local function handleItemBreak(item)
    if not item then return end
    if not item:IsWeapon() and not item:IsClothing() then return end
    local max = item:getConditionMax()
    if max <= 0 then return end
    item:setConditionNoSound(math.floor(max * 0.01))
end

function EffectBreakAllItems:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectBreakAllItems] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, handleItemBreak)
end
