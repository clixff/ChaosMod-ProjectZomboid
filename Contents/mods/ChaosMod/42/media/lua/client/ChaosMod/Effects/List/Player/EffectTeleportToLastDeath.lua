---@class EffectTeleportToLastDeath : ChaosEffectBase
EffectTeleportToLastDeath = ChaosEffectBase:derive("EffectTeleportToLastDeath", "teleport_to_last_death")

local RADIUS = 30
local MAX_DURATION = 8000
local DISABLE_AI_EFFECT_ID = "teleport_to_last_death"

function EffectTeleportToLastDeath:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local x, y, z = ChaosUtils.GetLatestDeathPosition()
    if not (x and y and z) then
        ChaosPlayer.SayLineByColor(player,
            ChaosLocalization.GetString("misc", "failed_to_find_last_death"),
            ChaosPlayerChatColors.red)
        return
    end

    ChaosVehicle.ExitVehicle(player)
    player:teleportTo(math.floor(x --[[@as number]]), math.floor(y --[[@as number]]), math.floor(z --[[@as number]]))

    ChaosZombie.PacifyZombiesAroundPlayer(RADIUS, MAX_DURATION, DISABLE_AI_EFFECT_ID, true)
end

function EffectTeleportToLastDeath:OnEnd()
    ChaosEffectBase:OnEnd()
end
