---@class EffectPlayerIsBored : ChaosEffectBase
EffectPlayerIsBored = ChaosEffectBase:derive("EffectPlayerIsBored", "player_is_bored")

function EffectPlayerIsBored:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local stats = player:getStats()
    stats:set(CharacterStat.BOREDOM, 70)
end

function EffectPlayerIsBored:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end
end
