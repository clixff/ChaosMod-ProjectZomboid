---@class EffectRagdollPlayer : ChaosEffectBase
EffectRagdollPlayer = ChaosEffectBase:derive("EffectRagdollPlayer", "ragdoll_player")

function EffectRagdollPlayer:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)


    player:clearVariable("BumpFallType")
    player:setBumpStaggered(true)
    player:setBumpType("stagger")
    player:setBumpFall(true)
    player:setBumpFallType("pushedBehind")
end

function EffectRagdollPlayer:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if not player then return end
end
