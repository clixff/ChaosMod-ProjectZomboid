---@class EffectLessInventoryCapacity : ChaosEffectBase
EffectLessInventoryCapacity = ChaosEffectBase:derive("EffectLessInventoryCapacity", "less_inventory_capacity")

function EffectLessInventoryCapacity:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local oldWeight = player:getMaxWeightBase()
    local newWeight = math.max(1, oldWeight - 3)
    print(string.format("[EffectLessInventoryCapacity] Old weight: %d, new weight: %d", oldWeight, newWeight))


    player:setMaxWeightBase(newWeight)
    player:getBodyDamage():UpdateStrength()
    ChaosPlayer.SayLineByColor(player, "-Inventory Capacity", ChaosPlayerChatColors.removedItem)
end
