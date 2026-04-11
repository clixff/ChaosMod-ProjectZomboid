ChaosAnimals = ChaosAnimals or {}

---@alias ChaosAnimalBreedList string[]
---@alias ChaosAnimalStageMap table<string, ChaosAnimalBreedList>
---@alias ChaosAnimalsByType table<string, ChaosAnimalStageMap>

---@type ChaosAnimalsByType
ChaosAnimals.ANIMALS_LIST = {
    Chicken = {
        chick = {
            "leghorn",
            "rhodeisland",
        },
        hen = {
            "leghorn",
            "rhodeisland",
        },
        cockerel = {
            "leghorn",
            "rhodeisland",
        },
    },

    Cow = {
        cowcalf = {
            "angus",
            "holstein",
            "simmental",
        },
        cow = {
            "angus",
            "holstein",
            "simmental",
        },
        bull = {
            "angus",
            "holstein",
            "simmental",
        },
    },

    Deer = {
        fawn = {
            "whitetailed",
        },
        doe = {
            "whitetailed",
        },
        buck = {
            "whitetailed",
        },
    },

    Mouse = {
        mousepups = {
            "deer",
            "golden",
            "white",
        },
        mousefemale = {
            "deer",
            "golden",
            "white",
        },
        mouse = {
            "deer",
            "golden",
            "white",
        },
    },

    Pig = {
        piglet = {
            "landrace",
            "largeblack",
        },
        sow = {
            "landrace",
            "largeblack",
        },
        boar = {
            "landrace",
            "largeblack",
        },
    },

    Rabbit = {
        rabkitten = {
            "appalachian",
            "cottontail",
            "swamp",
        },
        rabdoe = {
            "appalachian",
            "cottontail",
            "swamp",
        },
        rabbuck = {
            "appalachian",
            "cottontail",
            "swamp",
        },
    },

    Raccoon = {
        raccoonkit = {
            "grey",
        },
        raccoonsow = {
            "grey",
        },
        raccoonboar = {
            "grey",
        },
    },

    Rat = {
        ratbaby = {
            "grey",
            "white",
        },
        ratfemale = {
            "grey",
            "white",
        },
        rat = {
            "grey",
            "white",
        },
    },

    Sheep = {
        lamb = {
            "friesian",
            "rambouillet",
            "suffolk",
        },
        ewe = {
            "friesian",
            "rambouillet",
            "suffolk",
        },
        ram = {
            "friesian",
            "rambouillet",
            "suffolk",
        },
    },

    Turkey = {
        turkeypoult = {
            "meleagris",
        },
        turkeyhen = {
            "meleagris",
        },
        gobblers = {
            "meleagris",
        },
    },
}

---Returns a random animal type and breed from ANIMALS_LIST.
---Picks a random main type (e.g. "Chicken"), then a random stage (e.g. "hen"),
---then a random breed (e.g. "leghorn"). Returns the stage as the type string
---because that is what AnimalDefinitions expects.
---@return string type, string breed
function ChaosAnimals.GetRandomAnimal()
    ---@type string[]
    local mainTypes = {}
    for k in pairs(ChaosAnimals.ANIMALS_LIST) do
        table.insert(mainTypes, k)
    end
    local mainType = mainTypes[math.floor(ZombRand(1, #mainTypes + 1))]
    ---@type ChaosAnimalStageMap
    local stageMap = ChaosAnimals.ANIMALS_LIST[mainType]

    ---@type string[]
    local stages = {}
    for k in pairs(stageMap) do
        table.insert(stages, k)
    end
    local stage = stages[math.floor(ZombRand(1, #stages + 1))]
    ---@type ChaosAnimalBreedList
    local breeds = stageMap[stage]

    local breed = breeds[math.floor(ZombRand(1, #breeds + 1))]
    return stage or "", breed or ""
end

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
