---@class EffectSpawnManyExplosiveChickens : ChaosEffectBase
---@field chickens IsoAnimal[]
EffectSpawnManyExplosiveChickens = ChaosEffectBase:derive("EffectSpawnManyExplosiveChickens",
    "spawn_many_explosive_chickens")

local CHICKEN_COUNT = 5
local MIN_RADIUS = 1
local MAX_RADIUS = 3
local MAX_TRIES = 50

function EffectSpawnManyExplosiveChickens:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    self.chickens = {}
    local spawned = 0

    for _ = 1, CHICKEN_COUNT do
        local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, MIN_RADIUS, MAX_RADIUS, MAX_TRIES, true, true,
            true)
        if square then
            local chicken = ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), "hen", "rhodeisland")
            if chicken then
                local sa = SpecialAnimal:new(chicken)
                sa.followPlayer = false
                table.insert(self.chickens, chicken)
                chicken:changeStress(80)
                chicken:updateStress()
                spawned = spawned + 1
            end
        end
    end

    print("[EffectSpawnManyExplosiveChickens] Spawned " .. tostring(spawned) .. " chickens")
end

function EffectSpawnManyExplosiveChickens:OnEnd()
    ChaosEffectBase:OnEnd()

    if not self.chickens then return end

    for _, chicken in ipairs(self.chickens) do
        if chicken and chicken:isAlive() then
            local square = chicken:getSquare()
            if square then
                ChaosUtils.TriggerExplosionAt(square, 5)
            end
        end
    end

    print("[EffectSpawnManyExplosiveChickens] Chickens exploded")
    self.chickens = {}
end
