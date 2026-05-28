---@class EffectTeleportMalfunction : ChaosEffectBase
---@field teleportTimer ChaosManualTimer
EffectTeleportMalfunction = ChaosEffectBase:derive("EffectTeleportMalfunction", "teleport_malfunction")

local TELEPORT_INTERVAL_MS = 3000
local MIN_RADIUS = 15
local MAX_RADIUS = 60
local MAX_TRIES = 100

local function teleportPlayer()
    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, 0, MIN_RADIUS, MAX_RADIUS, MAX_TRIES, true, true,
        false)
    if not randomSquare then return end

    player:teleportTo(randomSquare:getX(), randomSquare:getY(), randomSquare:getZ())
end

function EffectTeleportMalfunction:OnStart()
    ChaosEffectBase:OnStart()
    self.teleportTimer = ChaosManualTimer.new(TELEPORT_INTERVAL_MS)
    teleportPlayer()
end

---@param deltaMs integer
function EffectTeleportMalfunction:OnTick(deltaMs)
    if not self.teleportTimer then return end
    self.teleportTimer:add(deltaMs)
    if self.teleportTimer:isEnded() then
        self.teleportTimer:reset()
        teleportPlayer()
    end
end

function EffectTeleportMalfunction:OnEnd()
    ChaosEffectBase:OnEnd()
end
