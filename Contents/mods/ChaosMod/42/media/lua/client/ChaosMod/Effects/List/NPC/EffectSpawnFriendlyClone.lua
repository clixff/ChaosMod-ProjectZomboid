EffectSpawnFriendlyClone = ChaosEffectBase:derive("EffectSpawnFriendlyClone", "effect_spawn_friendly_clone")

function EffectSpawnFriendlyClone:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnFriendlyClone] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 6, 15, 50, true, true, false)
    if not randomSquare then return end

    local x = randomSquare:getX()
    local y = randomSquare:getY()
    local z = randomSquare:getZ()

    local femaleChance = player:isFemale() and 100 or 0
    local newZombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist", femaleChance)

    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()

    ChaosZombie.CopyCharacterVisualsAndClothes(player, zombie)

    npc.npcGroup = ChaosNPCGroupID.COMPANIONS
end
