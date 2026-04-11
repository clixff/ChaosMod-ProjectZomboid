---@class EffectDecreaseHungerLevel : ChaosEffectBase
EffectDecreaseHungerLevel = ChaosEffectBase:derive("EffectDecreaseHungerLevel", "decrease_hunger_level")

function EffectDecreaseHungerLevel:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local stats = player:getStats()
    stats:remove(CharacterStat.HUNGER, 0.3)
end
