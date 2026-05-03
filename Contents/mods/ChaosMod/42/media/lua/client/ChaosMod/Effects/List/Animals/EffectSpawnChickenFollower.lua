---@class EffectSpawnChickenFollower : ChaosEffectBase
EffectSpawnChickenFollower = ChaosEffectBase:derive("EffectSpawnChickenFollower", "spawn_chicken_follower")

---@type string[]
local CHICKEN_BREEDS = { "leghorn", "rhodeisland" }

function EffectSpawnChickenFollower:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 1, 6, 50, true, true, true)
    if not square then return end

    ---@type string?
    local breed = CHICKEN_BREEDS[ChaosUtils.RandArrayIndex(CHICKEN_BREEDS)]
    if not breed then return end
    print("[EffectSpawnChickenFollower] Spawning chicken: " .. breed)
    local animal = ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), "hen", breed)
    if animal then
        SpecialAnimal:new(animal)
    end
end
