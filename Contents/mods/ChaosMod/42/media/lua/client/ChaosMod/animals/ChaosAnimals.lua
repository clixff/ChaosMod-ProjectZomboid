ChaosAnimals = ChaosAnimals or {}

---@param x number
---@param y number
---@param z number
---@param type string
---@param breed string
---@return IsoAnimal?
function ChaosAnimals.SpawnAnimal(x, y, z, type, breed)
    x = math.floor(x)
    y = math.floor(y)
    z = math.floor(z)
    local animalDef = AnimalDefinitions.getDef(type)
    if not animalDef then
        print("[ChaosAnimals.SpawnAnimal] Failed to get animal definition")
        return nil
    end

    local breed = animalDef:getBreedByName(breed)
    if not breed then
        print("[ChaosAnimals.SpawnAnimal] Failed to get breed")
        return nil
    end

    local animal = addAnimal(getCell(), x, y, z, type, breed)
    if not animal then
        print("[ChaosAnimals.SpawnAnimal] Failed to spawn animal")
        return nil
    end

    animal:addToWorld()
    return animal
end
