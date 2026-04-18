---@class EffectSpawnAdoringFan : ChaosEffectBase
EffectSpawnAdoringFan = ChaosEffectBase:derive("EffectSpawnAdoringFan", "spawn_adoring_fan")

function EffectSpawnAdoringFan:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 4, 50, true, true, false)
    if not randomSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(randomSquare:getX(), randomSquare:getY(), randomSquare:getZ(), 1, "Tourist", 50)
    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.FOLLOWERS
    npc:AddTag("adoring_fan")
end
