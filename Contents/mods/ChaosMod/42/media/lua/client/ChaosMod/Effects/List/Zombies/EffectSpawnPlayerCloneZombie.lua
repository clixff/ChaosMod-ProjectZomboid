EffectSpawnPlayerCloneZombie = ChaosEffectBase:derive("EffectSpawnPlayerCloneZombie", "spawn_player_clone_zombie")

function EffectSpawnPlayerCloneZombie:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnPlayerCloneZombie] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end
    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 5, 10, 50, true, true, false)
    if not randomSquare then return end
    local x = randomSquare:getX()
    local y = randomSquare:getY()
    local z = randomSquare:getZ()

    local zm = VirtualZombieManager.instance


    if not zm then
        print("[EffectSpawnPlayerCloneZombie] Failed to get VirtualZombieManager instance")
        return
    end

    local femaleChance = player:isFemale() and 100 or 0
    local zombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist", femaleChance)
    if not zombies or zombies:size() == 0 then
        print("[EffectSpawnPlayerCloneZombie] Failed to spawn zombie")
        return
    end
    local zombie = zombies:getFirst()
    if not zombie then
        print("[EffectSpawnPlayerCloneZombie] Failed to get zombie")
        return
    end

    ChaosZombie.CopyCharacterVisualsAndClothes(player, zombie)

    zombie:setTarget(player)
end
