EffectHealPlayer = ChaosEffectBase:derive("EffectHealPlayer", "heal_player")

function EffectHealPlayer:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    player:getBodyDamage():RestoreToFullHealth()
end
