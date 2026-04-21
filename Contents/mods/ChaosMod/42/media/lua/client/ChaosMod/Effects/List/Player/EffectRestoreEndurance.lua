EffectRestoreEndurance = ChaosEffectBase:derive("EffectRestoreEndurance", "restore_endurance")

function EffectRestoreEndurance:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    player:getStats():set(CharacterStat.ENDURANCE, 1.0)
end
