EffectReplaceFoodWithMaggots = ChaosEffectBase:derive("EffectReplaceFoodWithMaggots", "replace_food_with_maggots")

function EffectReplaceFoodWithMaggots:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectReplaceFoodWithMaggots] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local removedCount = 0

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
        if not item then return end
        if not item:isFood() then return end
        item:Remove()
        removedCount = removedCount + 1
    end)

    local imgCode = ChaosUtils.GetImgCodeByItemTextureByString("Base.Bread")
    local str = string.format(ChaosLocalization.GetString("misc", "items_removed"), imgCode, removedCount)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)

    if removedCount > 0 then
        ---@type InventoryItem?
        local maggotItem = nil
        for i = 1, removedCount do
            maggotItem = inventory:AddItem("Base.Maggots")
        end
        if maggotItem then
            ChaosPlayer.SayLineNewItem(player, maggotItem, removedCount)
        end
    end
end
