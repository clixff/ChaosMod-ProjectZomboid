EffectGiveStoneAgeKit = ChaosEffectBase:derive("EffectGiveStoneAgeKit", "give_stone_age_kit")

function EffectGiveStoneAgeKit:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveStoneAgeKit] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local items = {
        { id = "Base.SpearCrafted", amount = 1 },
        { id = "Base.RippedSheets", amount = 2 },
        { id = "Base.Branch_Broken", amount = 1 },
        { id = "Base.Stone2", amount = 2 },
    }

    for _, entry in ipairs(items) do
        ---@type InventoryItem?
        local item = nil
        for i = 1, entry.amount do
            item = inventory:AddItem(entry.id)
        end
        if item then
            ChaosPlayer.SayLineNewItem(player, item, entry.amount)
        end
    end
end
