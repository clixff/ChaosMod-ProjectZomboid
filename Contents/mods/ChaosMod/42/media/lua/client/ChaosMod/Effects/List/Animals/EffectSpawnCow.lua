---@class EffectSpawnCow : ChaosEffectBase
EffectSpawnCow = ChaosEffectBase:derive("EffectSpawnCow", "spawn_cow")

---@type string[]
local COW_BREEDS = { "holstein", "angus", "simmental" }

function EffectSpawnCow:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 1, 6, 50, true, true, true)
    if not square then return end

    local breed = COW_BREEDS[ChaosUtils.RandArrayIndex(COW_BREEDS)]
    if not breed then return end
    print("[EffectSpawnCow] Spawning cow: " .. breed)
    ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), "cow", breed)
end
