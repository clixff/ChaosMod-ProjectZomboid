EffectSupersonic = ChaosEffectBase:derive("EffectSupersonic", "supersonic")

function EffectSupersonic:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    player:setVariable("ChaosModSuperSonic", true)
end

function EffectSupersonic:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end

    player:setVariable("ChaosModSuperSonic", false)
end
