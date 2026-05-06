---@class EffectPlayerCantStopCoughing : ChaosEffectBase
---@field timerMs integer
EffectPlayerCantStopCoughing = ChaosEffectBase:derive("EffectPlayerCantStopCoughing", "player_cant_stop_coughing")

local INTERVAL_MS = 4000

function EffectPlayerCantStopCoughing:OnStart()
    ChaosEffectBase:OnStart()
    self.timerMs = 0
end

function EffectPlayerCantStopCoughing:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    self.timerMs = self.timerMs + deltaMs
    if self.timerMs >= INTERVAL_MS then
        local player = getPlayer()
        if player then
            local bd = player:getBodyDamage()
            bd:TriggerSneezeCough()
        end
        self.timerMs = 0
    end
end
