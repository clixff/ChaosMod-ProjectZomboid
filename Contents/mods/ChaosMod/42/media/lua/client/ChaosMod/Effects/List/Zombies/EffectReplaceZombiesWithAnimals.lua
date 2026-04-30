EffectReplaceZombiesWithAnimals = ChaosEffectBase:derive("EffectReplaceZombiesWithAnimals",
    "replace_zombies_with_animals")

function EffectReplaceZombiesWithAnimals:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x1 = square:getX()
    local y1 = square:getY()

    ChaosZombie.ForEachZombieInRange(x1, y1, 40, function(zombie)
        if zombie and zombie:isAlive() then
            local x2 = math.floor(zombie:getX())
            local y2 = math.floor(zombie:getY())
            local z2 = math.floor(zombie:getZ())

            zombie:removeFromWorld()
            zombie:removeFromSquare()

            local animalType, animalBreed = ChaosAnimals.GetRandomAnimal()
            local animal = ChaosAnimals.SpawnAnimal(x2, y2, z2, animalType, animalBreed)
        end
    end, true, nil)
end
