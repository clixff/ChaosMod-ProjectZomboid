---@class EffectPlayerCantStopCoughing : ChaosEffectBase
---@field timerMs integer
---@field clearCoughMs integer
EffectPlayerCantStopCoughing = ChaosEffectBase:derive("EffectPlayerCantStopCoughing", "player_cant_stop_coughing")

local INTERVAL_MS = 4000
local COUGH_DURATION_MS = 1500

function EffectPlayerCantStopCoughing:OnStart()
    ChaosEffectBase:OnStart()
    self.timerMs = 0
    self.clearCoughMs = 0
end

function EffectPlayerCantStopCoughing:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local bd = player:getBodyDamage()

    self.timerMs = self.timerMs + deltaMs
    if self.timerMs >= INTERVAL_MS then
        bd:TriggerSneezeCough()
        self.clearCoughMs = COUGH_DURATION_MS
        self.timerMs = 0
    end

    if self.clearCoughMs > 0 then
        self.clearCoughMs = self.clearCoughMs - deltaMs
        if self.clearCoughMs <= 0 then
            bd:setSneezeCoughActive(0)
            bd:setSneezeCoughTime(0)
        end
    end
end

function EffectPlayerCantStopCoughing:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end

    local bd = player:getBodyDamage()
    bd:setSneezeCoughActive(0)
    bd:setSneezeCoughTime(0)
end
