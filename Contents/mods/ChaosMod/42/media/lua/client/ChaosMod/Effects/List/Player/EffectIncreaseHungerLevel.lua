---@class EffectIncreaseHungerLevel : ChaosEffectBase
EffectIncreaseHungerLevel = ChaosEffectBase:derive("EffectIncreaseHungerLevel", "increase_hunger_level")

function EffectIncreaseHungerLevel:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local stats = player:getStats()
    stats:add(CharacterStat.HUNGER, 0.3)
end
