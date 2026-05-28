---@class EffectCinema : ChaosEffectBase
---@field hud ChaosCinemaHUD?
EffectCinema = ChaosEffectBase:derive("EffectCinema", "cinema")

function EffectCinema:OnStart()
    ChaosEffectBase:OnStart()

    self.hud = ChaosCinemaHUD:new()
    self.hud:initialise()
    self.hud:addToUIManager()
    self.hud:setVisible(true)
end

---@param deltaMs integer
function EffectCinema:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
end

function EffectCinema:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.hud then
        self.hud:setVisible(false)
        self.hud:removeFromUIManager()
        self.hud = nil
    end
end
