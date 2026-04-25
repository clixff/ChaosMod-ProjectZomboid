---@class EffectPlayerFalls : ChaosEffectBase
---@field fallIntervalMs integer
EffectPlayerFalls = ChaosEffectBase:derive("EffectPlayerFalls", "player_falls")

local FALL_INTERVAL_MS = 10000

local function triggerFall(player)
    ChaosVehicle.ExitVehicle(player)
    player:clearVariable("BumpFallType")
    player:setBumpStaggered(true)
    player:setBumpType("stagger")
    player:setBumpFall(true)
    player:setBumpFallType("pushedBehind")
end

function EffectPlayerFalls:OnStart()
    ChaosEffectBase:OnStart()
    self.fallIntervalMs = FALL_INTERVAL_MS
    local player = getPlayer()
    if not player then return end
    triggerFall(player)
end

---@param deltaMs integer
function EffectPlayerFalls:OnTick(deltaMs)
    self.fallIntervalMs = self.fallIntervalMs + deltaMs
    if self.fallIntervalMs < FALL_INTERVAL_MS then return end
    self.fallIntervalMs = self.fallIntervalMs - FALL_INTERVAL_MS

    local player = getPlayer()
    if not player then return end
    triggerFall(player)
end

function EffectPlayerFalls:OnEnd()
    ChaosEffectBase:OnEnd()
end
