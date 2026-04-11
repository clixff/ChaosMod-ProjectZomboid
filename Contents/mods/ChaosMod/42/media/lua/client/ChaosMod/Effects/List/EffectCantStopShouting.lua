---@class EffectCantStopShouting : ChaosEffectBase
---@field timerMs integer
EffectCantStopShouting = ChaosEffectBase:derive("EffectCantStopShouting", "cant_stop_shouting")

local MAX_TIMEOUT_MS = 1500

function EffectCantStopShouting:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    if not self.timerMs then
        self.timerMs = 0
    end
    self.timerMs = self.timerMs + deltaMs
    if self.timerMs >= MAX_TIMEOUT_MS then
        local player = getPlayer()
        if player then
            player:Callout(true)
        end

        self.timerMs = 0
    end
end
