---@class EffectCowTheZombieKiller : ChaosEffectBase
---@field cow IsoAnimal?
---@field specialAnimal SpecialAnimal?
---@field retargetMs integer
EffectCowTheZombieKiller = ChaosEffectBase:derive("EffectCowTheZombieKiller", "cow_the_zombie_killer")

---@type string[]
local COW_BREEDS = { "holstein", "angus", "simmental" }
---@type number
local ZOMBIE_DETECT_RADIUS = 8
---@type number
local ZOMBIE_KILL_RADIUS = 1.5
---@type integer
local RETARGET_INTERVAL_MS = 400
---@type integer
local FOLLOW_PLAYER_MIN_DIST = 3
---@type integer
local MIN_SPAWN_RADIUS = 1
---@type integer
local MAX_SPAWN_RADIUS = 6
---@type integer
local MAX_SPAWN_TRIES = 50

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

---@param cow IsoAnimal
---@return IsoZombie?
local function findNearestZombieToCow(cow)
    local zombies = ChaosZombie.GetNearestZombies(cow:getX(), cow:getY(), ZOMBIE_DETECT_RADIUS, true, cow:getZ())
    local nearest = nil
    local nearestDist = math.huge
    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if zombie and zombie:isAlive() then
            local dist = ChaosUtils.distTo(cow:getX(), cow:getY(), zombie:getX(), zombie:getY())
            if dist < nearestDist then
                nearestDist = dist
                nearest = zombie
            end
        end
    end
    return nearest
end

---@param cow IsoAnimal
local function killZombiesNearCow(cow)
    ChaosZombie.ForEachZombieInRange(cow:getX(), cow:getY(), ZOMBIE_KILL_RADIUS, function(zombie)
        if zombie and zombie:isAlive() then
            zombie:setKnockedDown(true)
            zombie:setHealth(0)
        end
    end, true, cow:getZ())
end

function EffectCowTheZombieKiller:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, MIN_SPAWN_RADIUS, MAX_SPAWN_RADIUS,
        MAX_SPAWN_TRIES, true, true, true)
    if not square then return end

    local breed = COW_BREEDS[ChaosUtils.RandArrayIndex(COW_BREEDS)]
    if not breed then return end

    local cow = ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), "cow", breed)
    if not cow then return end

    self.cow = cow
    self.specialAnimal = SpecialAnimal:new(cow)
    if self.specialAnimal then
        self.specialAnimal.followCharacter = nil
    end
    self.retargetMs = 0
end

---@param deltaMs integer
function EffectCowTheZombieKiller:OnTick(deltaMs)
    local cow = self.cow
    if not cow or cow:isDead() then return end

    killZombiesNearCow(cow)

    self.retargetMs = (self.retargetMs or 0) + deltaMs
    if self.retargetMs < RETARGET_INTERVAL_MS then return end
    self.retargetMs = 0

    local zombie = findNearestZombieToCow(cow)
    if zombie then
        ---@diagnostic disable-next-line: param-type-mismatch
        cow:pathToCharacter(zombie)
        return
    end

    local player = getPlayer()
    if not player then return end

    if ChaosUtils.distTo(cow:getX(), cow:getY(), player:getX(), player:getY()) > FOLLOW_PLAYER_MIN_DIST then
        local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 1, 3, 20, true, true, true)
        if square then
            ---@diagnostic disable-next-line: param-type-mismatch
            cow:pathToLocation(square:getX(), square:getY(), square:getZ())
        end
    end
end

function EffectCowTheZombieKiller:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.cow then
        removeAnimalFollower(self.cow)
        killAnimal(self.cow)
    end

    self.cow = nil
    self.specialAnimal = nil
end
