EffectTeleportInSmallRadius = ChaosEffectBase:derive("EffectTeleportInSmallRadius", "teleport_in_small_radius")

local RADIUS = 30
local MAX_DURATION = 4000

function EffectTeleportInSmallRadius:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)

    local square = player:getSquare()
    if not square then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, 0, 50, 100, 100, true, true, false)
    if not randomSquare then return end

    player:teleportTo(randomSquare:getX(), randomSquare:getY(), randomSquare:getZ())

    ChaosZombie.PacifyZombiesAroundPlayer(RADIUS, MAX_DURATION, "teleport_in_small_radius", true)
end
