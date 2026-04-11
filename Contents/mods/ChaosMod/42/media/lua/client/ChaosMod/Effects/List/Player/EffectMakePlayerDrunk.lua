---@class EffectMakePlayerDrunk : ChaosEffectBase
---@field originalIntoxication number
EffectMakePlayerDrunk = ChaosEffectBase:derive("EffectMakePlayerDrunk", "make_player_drunk")

function EffectMakePlayerDrunk:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local stats = player:getStats()
    self.originalIntoxication = stats:get(CharacterStat.INTOXICATION)
    stats:set(CharacterStat.INTOXICATION, 80.0)
end

function EffectMakePlayerDrunk:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end

    local stats = player:getStats()
    stats:set(CharacterStat.INTOXICATION, self.originalIntoxication)
end
