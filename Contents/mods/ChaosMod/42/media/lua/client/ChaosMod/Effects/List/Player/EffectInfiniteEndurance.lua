---@class EffectInfiniteEndurance : ChaosEffectBase
EffectInfiniteEndurance = ChaosEffectBase:derive("EffectInfiniteEndurance", "infinite_endurance")

function EffectInfiniteEndurance:OnStart()
    ChaosEffectBase:OnStart()
end

---@param deltaMs integer
function EffectInfiniteEndurance:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    player:getStats():set(CharacterStat.ENDURANCE, 1.0)
end

function EffectInfiniteEndurance:OnEnd()
    ChaosEffectBase:OnEnd()
end
