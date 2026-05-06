---@class EffectForceZoomOut : ChaosEffectBase
---@field old1x string?
---@field old2x string?
EffectForceZoomOut = ChaosEffectBase:derive("EffectForceZoomOut", "force_zoom_out")

function EffectForceZoomOut:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local core = getCore()
    self.old1x = core:getOptionZoomLevels1x()
    self.old2x = core:getOptionZoomLevels2x()
    core:setOptionZoomLevels1x("25;50;75;100;125;150;175;200;225;250")
    core:setOptionZoomLevels2x("25;50;75;100;125;150;175;200;225;250")
    core:zoomLevelsChanged()

    print("[EffectForceZoomOut] OnStart " .. tostring(self.effectId))
end

function EffectForceZoomOut:OnEnd()
    ChaosEffectBase:OnEnd()

    local core = getCore()
    if self.old1x then
        core:setOptionZoomLevels1x(self.old1x)
    end
    if self.old2x then
        core:setOptionZoomLevels2x(self.old2x)
    end
    core:zoomLevelsChanged()
end

function EffectForceZoomOut:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end


    Core.getInstance():doZoomScroll(0, 1)
end
