---@class EffectSpawnChicken : ChaosEffectBase
EffectSpawnChicken = ChaosEffectBase:derive("EffectSpawnChicken", "spawn_chicken")

local breeds = { "leghorn", "rhodeisland" }

function EffectSpawnChicken:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 1, 6, 50, true, true, true)
    if not square then return end

    local breed = breeds[ZombRand(#breeds) + 1]
    print("[EffectSpawnChicken] Spawning chicken: " .. breed)
    ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), "hen", breed)
end
