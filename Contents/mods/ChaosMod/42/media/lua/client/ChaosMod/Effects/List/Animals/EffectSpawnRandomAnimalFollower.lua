---@class EffectSpawnRandomAnimalFollower : ChaosEffectBase
EffectSpawnRandomAnimalFollower = ChaosEffectBase:derive("EffectSpawnRandomAnimalFollower", "spawn_random_animal_follower")

function EffectSpawnRandomAnimalFollower:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 1, 6, 50, true, true, true)
    if not square then return end

    local animalType, animalBreed = ChaosAnimals.GetRandomAnimal()
    print("[EffectSpawnRandomAnimalFollower] Spawning animal: " .. animalType .. " " .. animalBreed)
    local animal = ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), animalType, animalBreed)

    if animal then
        local displayName = getText("IGUI_AnimalType_" .. animal:getAnimalType())
        local breedName = getText("IGUI_Breed_" .. animal:getData():getBreed():getName())
        local str = string.format(ChaosLocalization.GetString("misc", "spawned_animal"), breedName, displayName)
        ChaosPlayer.SayLine(player, str, 162 / 255, 223 / 255, 208 / 255)
        SpecialAnimal:new(animal)
    end
end
