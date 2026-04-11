---@class EffectSpawnRandomAnimal : ChaosEffectBase
EffectSpawnRandomAnimal = ChaosEffectBase:derive("EffectSpawnRandomAnimal", "spawn_random_animal")

function EffectSpawnRandomAnimal:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 1, 6, 50, true, true, true)
    if not square then return end

    local animalType, animalBreed = ChaosAnimals.GetRandomAnimal()
    print("[EffectSpawnRandomAnimal] Spawning animal: " .. animalType .. " " .. animalBreed)
    local animal = ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), animalType, animalBreed)

    if animal then
        local displayName = getText("IGUI_AnimalType_" .. animal:getAnimalType())

        local breedName = getText("IGUI_Breed_" .. animal:getData():getBreed():getName())

        local str = string.format("Spawned %s %s", breedName, displayName)
        ChaosPlayer.SayLine(player, str, 0.05, 0.333, 1.0)
    end
end
