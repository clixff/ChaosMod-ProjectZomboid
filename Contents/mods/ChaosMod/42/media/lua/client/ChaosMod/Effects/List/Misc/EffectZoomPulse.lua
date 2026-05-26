---@class EffectZoomPulse : ChaosEffectBase
---@field old1x string?
---@field old2x string?
---@field zoomTimer number
---@field zoomDir integer
EffectZoomPulse = ChaosEffectBase:derive("EffectZoomPulse", "zoom_pulse")

local ZOOM_LEVELS =
"25;150"

function EffectZoomPulse:OnStart()
    ChaosEffectBase:OnStart()

    local core = getCore()
    self.old1x = core:getOptionZoomLevels1x()
    self.old2x = core:getOptionZoomLevels2x()

    core:setOptionZoomLevels1x(ZOOM_LEVELS)
    core:setOptionZoomLevels2x(ZOOM_LEVELS)
    core:zoomLevelsChanged()

    self.zoomTimer = 0
    self.zoomDir = -1
end

---@param deltaMs integer
function EffectZoomPulse:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local core = getCore()
    self.zoomTimer = self.zoomTimer + deltaMs

    if self.zoomTimer < 100 then
        return
    end
    self.zoomTimer = 0

    local current = core:getCurrentPlayerZoom()
    local minZoom = core:getMinZoom()
    local maxZoom = core:getMaxZoom()

    if math.abs(current - minZoom) < 0.01 then
        self.zoomDir = 1
    elseif math.abs(current - maxZoom) < 0.01 then
        self.zoomDir = -1
    end

    core:doZoomScroll(0, self.zoomDir)
end

function EffectZoomPulse:OnEnd()
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
