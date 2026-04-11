EffectForceZoomOut = ChaosEffectBase:derive("EffectForceZoomOut", "force_zoom_out")

function EffectForceZoomOut:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end


    print("[EffectForceZoomOut] OnStart " .. tostring(self.effectId))
end

function EffectForceZoomOut:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    local fbo = Core.getInstance():getOffscreenBuffer()
    if not fbo then return end


    Core.getInstance():doZoomScroll(0, 1)
end
