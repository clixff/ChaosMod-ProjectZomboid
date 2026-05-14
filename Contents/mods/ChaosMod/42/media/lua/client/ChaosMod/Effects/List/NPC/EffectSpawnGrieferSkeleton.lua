EffectSpawnGrieferSkeleton = ChaosEffectBase:derive("EffectSpawnGrieferSkeleton", "spawn_griefer_skeleton")

function EffectSpawnGrieferSkeleton:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnGrieferSkeleton] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, 0, 6, 15, 50, true, true, false)

    if not randomSquare then return end

    local x2 = randomSquare:getX()
    local y2 = randomSquare:getY()
    local z2 = randomSquare:getZ()

    local newZombies = ChaosZombie.SpawnZombieAt(x2, y2, z2, 1, "Naked", 0)

    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()

    npc.npcGroup = ChaosNPCGroupID.RAIDERS
    ChaosZombie.MakeZombieSkeleton(zombie)

    npc:SetWeapon("Base.Cudgel_Spike")
end
