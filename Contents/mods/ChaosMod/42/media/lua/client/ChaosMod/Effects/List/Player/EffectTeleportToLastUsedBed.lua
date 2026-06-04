---@class EffectTeleportToLastUsedBed : ChaosEffectBase
EffectTeleportToLastUsedBed = ChaosEffectBase:derive("EffectTeleportToLastUsedBed", "teleport_to_last_used_bed")

local RADIUS = 30
local MAX_DURATION = 8000

function EffectTeleportToLastUsedBed:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectTeleportToLastUsedBed] OnStart")

    local player = getPlayer()
    if not player then return end

    local loc = ChaosUtils.sleepWorldLocation or ChaosUtils.playerSpawnPoint
    if not loc then
        player:Say(ChaosLocalization.GetString("misc", "no_sleep_location"))
        return
    end


    ChaosVehicle.ExitVehicle(player)

    local x = math.floor(loc.x)
    local y = math.floor(loc.y)
    local z = math.floor(loc.z)

    player:teleportTo(x, y, z)

    print(string.format("[EffectTeleportToLastUsedBed] Teleported to %.1f, %.1f, %.1f", loc.x, loc.y, loc.z))

    ChaosZombie.PacifyZombiesAroundPlayer(RADIUS, MAX_DURATION, "teleport_to_last_used_bed", true)
end
