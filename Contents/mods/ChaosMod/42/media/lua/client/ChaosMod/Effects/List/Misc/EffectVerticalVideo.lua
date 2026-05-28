---@class EffectVerticalVideo : ChaosEffectBase
---@field hud ChaosVerticalVideoHUD?
EffectVerticalVideo = ChaosEffectBase:derive("EffectVerticalVideo", "vertical_video")

function EffectVerticalVideo:OnStart()
    ChaosEffectBase:OnStart()

    self.hud = ChaosVerticalVideoHUD:new()
    self.hud:initialise()
    self.hud:addToUIManager()
    self.hud:setVisible(true)
end

---@param deltaMs integer
function EffectVerticalVideo:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
end

function EffectVerticalVideo:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.hud then
        self.hud:setVisible(false)
        self.hud:removeFromUIManager()
        self.hud = nil
    end
end
