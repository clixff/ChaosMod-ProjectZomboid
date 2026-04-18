EffectSpawnSprinterZombie = ChaosEffectBase:derive("EffectSpawnSprinterZombie", "spawn_sprinter_zombie_random_radius")

function EffectSpawnSprinterZombie:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnSprinterZombie] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 20, 50, 50, true, true, false)
    if not randomSquare then return end

    local x = randomSquare:getX()
    local y = randomSquare:getY()
    local z = randomSquare:getZ()
    local newZombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist")
    local zombie = newZombies:getFirst()
    if not zombie then
        return
    end
end
