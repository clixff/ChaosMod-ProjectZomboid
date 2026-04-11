---@class EffectPlayerIsHungry : ChaosEffectBase
EffectPlayerIsHungry = ChaosEffectBase:derive("EffectPlayerIsHungry", "player_is_hungry")

function EffectPlayerIsHungry:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local stats = player:getStats()
    stats:set(CharacterStat.HUNGER, 0.6)
end

function EffectPlayerIsHungry:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end
end
