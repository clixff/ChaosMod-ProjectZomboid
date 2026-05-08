---@class EffectMoreInventoryCapacity : ChaosEffectBase
EffectMoreInventoryCapacity = ChaosEffectBase:derive("EffectMoreInventoryCapacity", "more_inventory_capacity")

function EffectMoreInventoryCapacity:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    player:setMaxWeightBase(player:getMaxWeightBase() + 3)
    player:getBodyDamage():UpdateStrength()
    ChaosPlayer.SayLineByColor(player, "+Inventory Capacity", ChaosPlayerChatColors.newItem)
end
