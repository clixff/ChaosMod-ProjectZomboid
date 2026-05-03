---@class EffectSpawnPigFollower : ChaosEffectBase
EffectSpawnPigFollower = ChaosEffectBase:derive("EffectSpawnPigFollower", "spawn_pig_follower")

---@type string[]
local PIG_BREEDS = { "landrace", "largeblack" }

function EffectSpawnPigFollower:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 1, 6, 50, true, true, true)
    if not square then return end

    ---@type string?
    local breed = PIG_BREEDS[ChaosUtils.RandArrayIndex(PIG_BREEDS)]
    if not breed then return end
    local animal = ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), "sow", breed)
    if not animal then return end

    table.insert(ChaosMod.specialAnimalsFollowers, {
        animal = animal,
        repathTicks = 20
    })
end
