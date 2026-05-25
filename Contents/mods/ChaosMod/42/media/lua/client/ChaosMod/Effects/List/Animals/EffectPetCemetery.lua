---@class EffectPetCemetery : ChaosEffectBase
---@field animals IsoAnimal[]
---@field specialAnimals SpecialAnimal[]
EffectPetCemetery = ChaosEffectBase:derive("EffectPetCemetery", "pet_cemetery")

---@type string[]
local COW_BREEDS = { "holstein", "angus", "simmental" }
---@type string[]
local PIG_BREEDS = { "landrace", "largeblack" }

---@param animal IsoAnimal?
local function removeAnimalFollower(animal)
    if not animal then return end

    for i = #ChaosMod.specialAnimalsFollowers, 1, -1 do
        local followState = ChaosMod.specialAnimalsFollowers[i]
        if followState and followState.animal == animal then
            table.remove(ChaosMod.specialAnimalsFollowers, i)
        end
    end
end

---@param animal IsoAnimal?
local function despawnAnimal(animal)
    if not animal then return end

    animal:removeFromWorld()
    animal:removeFromSquare()
end

---@param type string
---@param breed string
---@return IsoAnimal?, SpecialAnimal?
local function spawnSkeletonAnimal(type, breed)
    local player = getPlayer()
    if not player then return nil, nil end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 1, 6, 50, true, true, true)
    if not square then return nil, nil end

    local animal = ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), type, breed, true)
    if not animal then return nil, nil end

    local specialAnimal = SpecialAnimal:new(animal)
    if specialAnimal then
        specialAnimal.maxRepathTicks = 20
    end

    return animal, specialAnimal
end

function EffectPetCemetery:OnStart()
    ChaosEffectBase:OnStart()

    self.animals = {}
    self.specialAnimals = {}

    local cowBreed = COW_BREEDS[ChaosUtils.RandArrayIndex(COW_BREEDS)]
    if cowBreed then
        local cow, cowSpecial = spawnSkeletonAnimal("cow", cowBreed)
        if cow then
            table.insert(self.animals, cow)
            if cowSpecial then
                table.insert(self.specialAnimals, cowSpecial)
            end
        end
    end

    local pigBreed = PIG_BREEDS[ChaosUtils.RandArrayIndex(PIG_BREEDS)]
    if pigBreed then
        local pig, pigSpecial = spawnSkeletonAnimal("sow", pigBreed)
        if pig then
            table.insert(self.animals, pig)
            if pigSpecial then
                table.insert(self.specialAnimals, pigSpecial)
            end
        end
    end
end

---@param deltaMs integer
function EffectPetCemetery:OnTick(deltaMs)
    local _ = deltaMs

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    if ChaosPlayer.IsPlayerKnockedDown(player) then return end

    for i = 1, #self.animals do
        local animal = self.animals[i]
        if animal and not animal:isDead() then
            local animalSquare = animal:getSquare()
            if animalSquare == playerSquare then
                player:setKnockedDown(true)
                return
            end
        end
    end
end

function EffectPetCemetery:OnEnd()
    ChaosEffectBase:OnEnd()

    for i = 1, #self.animals do
        local animal = self.animals[i]
        removeAnimalFollower(animal)
        despawnAnimal(animal)
    end

    self.animals = {}
    self.specialAnimals = {}
end
