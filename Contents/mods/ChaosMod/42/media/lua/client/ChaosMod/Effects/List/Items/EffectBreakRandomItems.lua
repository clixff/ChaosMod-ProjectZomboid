EffectBreakRandomItems = ChaosEffectBase:derive("EffectBreakRandomItems", "break_random_items")

function EffectBreakRandomItems:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectBreakRandomItems] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local brokenCount = 0

    ---@param item InventoryItem
    local function handleItemBreak(item)
        if not item then return end
        if not item:IsWeapon() and not item:IsClothing() then return end
        local max = item:getConditionMax()
        if max <= 0 then return end
        if ChaosUtils.RandInteger(4) ~= 0 then return end
        item:setConditionNoSound(math.floor(max * 0.01))
        brokenCount = brokenCount + 1
    end

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, handleItemBreak)

    if brokenCount > 0 then
        ChaosPlayer.SayLineByColor(player, string.format("Broken Items: %d", brokenCount), ChaosPlayerChatColors.removedItem)
    end
end
