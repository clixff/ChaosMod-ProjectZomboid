EffectFillAreaWithZombies = ChaosEffectBase:derive("EffectFillAreaWithZombies", "fill_area_with_zombies")

local ZOMBIES_TO_SPAWN = 50
local MIN_RADIUS = 20
local MAX_RADIUS = 150
local MAX_TRIES_PER_ZOMBIE = 25

function EffectFillAreaWithZombies:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectFillAreaWithZombies] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local usedSquares = {}
    local spawnedCount = 0

    for i = 1, ZOMBIES_TO_SPAWN do
        local randomSquare = nil

        for _ = 1, MAX_TRIES_PER_ZOMBIE do
            local candidateSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, 0, MIN_RADIUS, MAX_RADIUS, 50, true,
                true, false)
            if candidateSquare then
                local key = tostring(candidateSquare:getX()) .. ":" .. tostring(candidateSquare:getY()) .. ":" ..
                    tostring(candidateSquare:getZ())
                if not usedSquares[key] then
                    usedSquares[key] = true
                    randomSquare = candidateSquare
                    break
                end
            end
        end

        if randomSquare then
            local zombies = ChaosZombie.SpawnZombieAt(randomSquare:getX(), randomSquare:getY(), randomSquare:getZ(), 1,
                "Tourist", 50)
            if zombies and zombies:size() > 0 then
                local zombie = zombies:getFirst()
                if zombie then
                    zombie:dressInRandomOutfit()
                    spawnedCount = spawnedCount + 1
                end
            end
        end
    end

    print("[EffectFillAreaWithZombies] Spawned zombies: " .. tostring(spawnedCount))
end
