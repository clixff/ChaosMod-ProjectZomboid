EffectSpawnSprinterZombie = ChaosEffectBase:derive("EffectSpawnSprinterZombie", "spawn_sprinter_zombie")

function EffectSpawnSprinterZombie:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnSprinterZombie] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 6, 10, 50, true, true, false)
    if not randomSquare then return end

    local x = randomSquare:getX()
    local y = randomSquare:getY()
    local z = randomSquare:getZ()
    local newZombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist")
    local zombie = newZombies:getFirst()
    if not zombie then
        return
    end

    -- zombie:setSpeedMod(2.0)
    -- zombie:setWalkType("ZombieWalk2")
    zombie:doZombieSpeed(1)
    zombie:setSpeedMod(0.1)
end
