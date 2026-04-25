---@class EffectDryMouth : ChaosEffectBase
EffectDryMouth = ChaosEffectBase:derive("EffectDryMouth", "dry_mouth")

function EffectDryMouth:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local stats = player:getStats()
    if stats:get(CharacterStat.THIRST) < 0.5 then
        stats:set(CharacterStat.THIRST, 0.5)
    end
end
