EffectNightVision = ChaosEffectBase:derive("EffectNightVision", "night_vision")

function EffectNightVision:OnStart()
    ChaosEffectBase:OnStart()
end

function EffectNightVision:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end
    player:setWearingNightVisionGoggles(true)
end

function EffectNightVision:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end
    player:setWearingNightVisionGoggles(false)
end
