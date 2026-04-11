EffectForceZoomIn = ChaosEffectBase:derive("EffectForceZoomIn", "force_zoom_in")

function EffectForceZoomIn:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    print("[EffectForceZoomIn] OnStart " .. tostring(self.effectId))
end

function EffectForceZoomIn:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    Core.getInstance():doZoomScroll(0, -1)
end
