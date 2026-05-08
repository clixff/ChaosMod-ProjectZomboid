---@class EffectTeleportToPreviousLocation : ChaosEffectBase
EffectTeleportToPreviousLocation = ChaosEffectBase:derive("EffectTeleportToPreviousLocation",
    "teleport_to_previous_location")

function EffectTeleportToPreviousLocation:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local points = ChaosUtils.playerPreviousPositions
    if not points or #points == 0 then return end

    local loc = points[1]
    if not loc then return end

    ChaosVehicle.ExitVehicle(player)
    player:teleportTo(math.floor(loc.x), math.floor(loc.y), math.floor(loc.z))

    print(string.format("[EffectTeleportToPreviousLocation] Teleported to %.1f, %.1f, %.1f", loc.x, loc.y, loc.z))
end
