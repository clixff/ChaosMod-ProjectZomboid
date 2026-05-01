---@class EffectBloodTrail : ChaosEffectBase
---@field intervalMs integer
EffectBloodTrail = ChaosEffectBase:derive("EffectBloodTrail", "blood_trail")

local SPLAT_INTERVAL_MS = 250

function EffectBloodTrail:OnStart()
    ChaosEffectBase:OnStart()
    self.intervalMs = 0
end

---@param deltaMs integer
function EffectBloodTrail:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    self.intervalMs = self.intervalMs + deltaMs
    if self.intervalMs < SPLAT_INTERVAL_MS then return end

    self.intervalMs = self.intervalMs - SPLAT_INTERVAL_MS
    local square = player:getSquare()
    if not square then return end
    addBloodSplat(square, 10)
    print("[EffectBloodTrail] Splat blood floor")
end

function EffectBloodTrail:OnEnd()
    ChaosEffectBase:OnEnd()
end
