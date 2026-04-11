EffectSpawnFewZombies = ChaosEffectBase:derive("EffectSpawnFewZombies", "spawn_few_zombies")

function EffectSpawnFewZombies:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnFewZombies] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local zombiesToSpawn = 3
    local x1 = math.floor(player:getX())
    local y1 = math.floor(player:getY())

    for i = 1, zombiesToSpawn do
        local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 8, 12, 50, true, true, false)
        if randomSquare then
            local x = randomSquare:getX()
            local y = randomSquare:getY()
            local z = randomSquare:getZ()
            local zombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist")
            if zombies and zombies:size() > 0 then
                local zombie = zombies:getFirst()
                if zombie then
                    zombie:setTarget(player)
                    zombie:setTurnAlertedValues(x1, y1)
                end
            end
        end
    end
end
