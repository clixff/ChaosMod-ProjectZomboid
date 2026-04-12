---@class EffectMakePlayerUnhappy : ChaosEffectBase
EffectMakePlayerUnhappy = ChaosEffectBase:derive("EffectMakePlayerUnhappy", "make_player_unhappy")

function EffectMakePlayerUnhappy:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local stats = player:getStats()
    local current = stats:get(CharacterStat.UNHAPPINESS)
    stats:set(CharacterStat.UNHAPPINESS, current + 25)
end

function EffectMakePlayerUnhappy:OnEnd()
    ChaosEffectBase:OnEnd()
end
