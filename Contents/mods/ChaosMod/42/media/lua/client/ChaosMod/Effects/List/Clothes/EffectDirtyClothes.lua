---@class EffectDirtyClothes : ChaosEffectBase
EffectDirtyClothes = ChaosEffectBase:derive("EffectDirtyClothes", "dirty_clothes")

function EffectDirtyClothes:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, false, function(item)
        if item and item:IsClothing() then
            ---@type Clothing
            local clothing = item
            clothing:setDirtiness(100)
        end
    end)

    player:OnClothingUpdated()
end
