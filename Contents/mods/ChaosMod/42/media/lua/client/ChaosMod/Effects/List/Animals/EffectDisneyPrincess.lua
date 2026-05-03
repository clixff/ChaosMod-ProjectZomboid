---@class EffectDisneyPrincess : ChaosEffectBase
EffectDisneyPrincess = ChaosEffectBase:derive("EffectDisneyPrincess", "disney_princess")

local ANIMALS_TO_SPAWN = {
    { type = "cowcalf",     breed = "holstein",    count = 1 },
    { type = "chick",       breed = "rhodeisland", count = 3 },
    { type = "fawn",        breed = "whitetailed", count = 2 },
    { type = "doe",         breed = "whitetailed", count = 1 },
    { type = "mousepups",   breed = "deer",        count = 2 },
    { type = "piglet",      breed = "landrace",    count = 1 },
    { type = "rabkitten",   breed = "appalachian", count = 2 },
    { type = "raccoonkit",  breed = "grey",        count = 1 },
    { type = "lamb",        breed = "friesian",    count = 1 },
    { type = "turkeypoult", breed = "meleagris",   count = 1 },
}

local MIN_RADIUS = 1
local MAX_RADIUS = 6
local MAX_TRIES = 50

---@param animal IsoAnimal
local function addAnimalFollower(animal)
    table.insert(ChaosMod.specialAnimalsFollowers, {
        animal = animal,
        repathTicks = 20
    })
end

---@param animal IsoAnimal
local function removeAnimalFollower(animal)
    for i = #ChaosMod.specialAnimalsFollowers, 1, -1 do
        local followState = ChaosMod.specialAnimalsFollowers[i]
        if followState and followState.animal == animal then
            table.remove(ChaosMod.specialAnimalsFollowers, i)
        end
    end
end

---@param animal IsoAnimal
local function killAnimal(animal)
    if not animal or animal:isDead() then return end

    if animal.setHealth then
        animal:setHealth(0)
    end

    if animal.DoDeath then
        ---@diagnostic disable-next-line: param-type-mismatch
        animal:DoDeath(nil, nil)
    else
        animal:removeFromWorld()
        animal:removeFromSquare()
    end
end

function EffectDisneyPrincess:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local spawned = 0
    self.animals = {}

    for _, entry in ipairs(ANIMALS_TO_SPAWN) do
        for _ = 1, entry.count do
            local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, MIN_RADIUS, MAX_RADIUS, MAX_TRIES, true,
                true, true)
            if square then
                local animal = ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), entry.type,
                    entry.breed)
                if animal then
                    table.insert(self.animals, animal)
                    addAnimalFollower(animal)
                    spawned = spawned + 1
                end
            end
        end
    end

    print("[EffectDisneyPrincess] Spawned " .. tostring(spawned) .. " animals")
end

function EffectDisneyPrincess:OnEnd()
    ChaosEffectBase:OnEnd()

    if not self.animals then return end

    for i = #self.animals, 1, -1 do
        local animal = self.animals[i]
        if animal then
            removeAnimalFollower(animal)
            killAnimal(animal)
        end
    end

    self.animals = {}
end
