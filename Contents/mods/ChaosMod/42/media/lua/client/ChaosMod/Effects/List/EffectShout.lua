EffectShout = ChaosEffectBase:derive("EffectShout", "effect_shout")

function EffectShout:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if player then
        player:Callout(true)
    end
end
