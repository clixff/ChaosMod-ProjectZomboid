---@class EffectSpawnCowFollower : ChaosEffectBase
EffectSpawnCowFollower = ChaosEffectBase:derive("EffectSpawnCowFollower", "spawn_cow_follower")

---@type string[]
local COW_BREEDS = { "holstein", "angus", "simmental" }

function EffectSpawnCowFollower:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 1, 6, 50, true, true, true)
    if not square then return end

    local breed = COW_BREEDS[ChaosUtils.RandArrayIndex(COW_BREEDS)]
    if not breed then return end
    print("[EffectSpawnCowFollower] Spawning cow: " .. breed)
    local animal = ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), "cow", breed)
    if animal then
        SpecialAnimal:new(animal)
    end
end
