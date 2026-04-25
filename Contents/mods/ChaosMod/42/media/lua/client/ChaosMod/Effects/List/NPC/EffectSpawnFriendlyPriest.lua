EffectSpawnFriendlyPriest = ChaosEffectBase:derive("EffectSpawnFriendlyPriest", "spawn_friendly_priest")

function EffectSpawnFriendlyPriest:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnFriendlyPriest] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 4, 8, 50, true, true, false)
    if not randomSquare then return end

    local x = randomSquare:getX()
    local y = randomSquare:getY()
    local z = randomSquare:getZ()

    local newZombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Priest", 0)

    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()

    npc.npcGroup = ChaosNPCGroupID.COMPANIONS
end
