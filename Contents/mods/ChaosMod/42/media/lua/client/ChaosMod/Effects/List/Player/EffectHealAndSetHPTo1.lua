EffectHealAndSetHPTo1 = ChaosEffectBase:derive("EffectHealAndSetHPTo1", "heal_and_set_hp_to_1")

function EffectHealAndSetHPTo1:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local bodyDamage = player:getBodyDamage()
    bodyDamage:RestoreToFullHealth()
    bodyDamage:ReduceGeneralHealth(99)
    bodyDamage:calculateOverallHealth()
end
