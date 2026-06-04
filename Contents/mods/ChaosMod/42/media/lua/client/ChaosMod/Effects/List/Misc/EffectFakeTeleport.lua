---@class EffectFakeTeleport : ChaosEffectBase
---@field originalX number
---@field originalY number
---@field originalZ number
EffectFakeTeleport = ChaosEffectBase:derive("EffectFakeTeleport", "fake_teleport")

local TELEPORT_TIME_BACK_MS = 15000
local RADIUS = 2
local DISABLE_NPC_AI_ID = "fake_teleport"

function EffectFakeTeleport:OnStart()
    ChaosEffectBase:OnStart()

    self.fakeEffectNameId = "teleport_to_last_used_bed"

    local player = getPlayer()
    if not player then return end

    local loc = ChaosUtils.sleepWorldLocation or ChaosUtils.playerSpawnPoint
    if not loc then
        player:Say(ChaosLocalization.GetString("misc", "no_sleep_location"))
        return
    end

    self.originalX = player:getX()
    self.originalY = player:getY()
    self.originalZ = player:getZ()

    ChaosVehicle.ExitVehicle(player)

    local x = math.floor(loc.x)
    local y = math.floor(loc.y)
    local z = math.floor(loc.z)

    player:teleportTo(x, y, z)

    print(string.format("[EffectFakeTeleport] Teleported to %.1f, %.1f, %.1f", loc.x, loc.y, loc.z))

    local originalXYZ = { x = self.originalX, y = self.originalY, z = self.originalZ }

    ChaosZombie.PacifyZombiesAroundPlayer(RADIUS, TELEPORT_TIME_BACK_MS, DISABLE_NPC_AI_ID, false, function()
        local p = getPlayer()
        if not p then return end

        p:teleportTo(originalXYZ.x, originalXYZ.y, math.floor(originalXYZ.z))

        ChaosPlayer.SayLineByColor(p, ChaosLocalization.GetString("effects", "fake_teleport"),
            ChaosPlayerChatColors.green)
    end)
end

function EffectFakeTeleport:OnEnd()
    ChaosEffectBase:OnEnd()
end
