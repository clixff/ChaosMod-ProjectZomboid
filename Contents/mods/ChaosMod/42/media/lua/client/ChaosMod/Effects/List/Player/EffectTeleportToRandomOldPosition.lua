---@class EffectTeleportToRandomOldPosition : ChaosEffectBase
EffectTeleportToRandomOldPosition = ChaosEffectBase:derive("EffectTeleportToRandomOldPosition",
    "teleport_to_random_old_position")

local RADIUS = 30
local MAX_DURATION = 8000

function EffectTeleportToRandomOldPosition:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local points = ChaosUtils.playerPreviousPositions
    if not points or #points == 0 then return end

    local n = #points
    local startIdx = 5
    local endIdx = 10

    if n < startIdx then
        startIdx = 1
        endIdx = n
    elseif n < endIdx then
        endIdx = n
    end

    local idx = ChaosUtils.RandIntegerRange(startIdx, endIdx + 1)
    local loc = points[idx]
    if not loc then return end

    ChaosVehicle.ExitVehicle(player)
    player:teleportTo(math.floor(loc.x), math.floor(loc.y), math.floor(loc.z))

    print(string.format("[EffectTeleportToRandomOldPosition] Teleported to %.1f, %.1f, %.1f (index %d of %d)",
        loc.x, loc.y, loc.z, idx, n))

    ChaosZombie.PacifyZombiesAroundPlayer(RADIUS, MAX_DURATION, "teleport_to_random_old_position", true)
end

function EffectTeleportToRandomOldPosition:OnEnd()
    ChaosEffectBase:OnEnd()
end
