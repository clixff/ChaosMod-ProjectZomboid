---@class EffectSpawnFireChickensEntry
---@field animal IsoAnimal
---@field wanderTimer ChaosManualTimer

---@class EffectSpawnFireChickens : ChaosEffectBase
---@field chickens EffectSpawnFireChickensEntry[]
EffectSpawnFireChickens = ChaosEffectBase:derive("EffectSpawnFireChickens", "spawn_fire_chickens")

---@type string[]
local CHICKEN_BREEDS = { "leghorn", "rhodeisland" }
local CHICKEN_COUNT = 2
local MIN_SPAWN_DIST = 2
local MAX_SPAWN_DIST = 6
local MAX_SPAWN_TRIES = 50

local WANDER_MIN_RADIUS = 3
local WANDER_MAX_RADIUS = 10
local WANDER_MAX_TRIES = 30
local WANDER_COOLDOWN_MIN_MS = 2500
local WANDER_COOLDOWN_MAX_MS = 5000

---@return integer
local function randomWanderCooldownMs()
    return ChaosUtils.RandIntegerRange(WANDER_COOLDOWN_MIN_MS, WANDER_COOLDOWN_MAX_MS + 1)
end

---@param entry EffectSpawnFireChickensEntry
local function repathChickenNearPlayer(entry)
    local animal = entry.animal
    if not animal or animal:isDead() then return end

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, WANDER_MIN_RADIUS, WANDER_MAX_RADIUS,
        WANDER_MAX_TRIES, true, true, false)
    if not square then return end

    ---@diagnostic disable-next-line: param-type-mismatch
    animal:pathToLocation(square:getX(), square:getY(), square:getZ())
end

---@param animal IsoAnimal
local function killChicken(animal)
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

---@param animal IsoAnimal
local function keepChickenFireproof(animal)
    animal:setFireKillRate(0)
    if animal:isOnFire() then
        animal:StopBurning()
    end
    if animal:getHealth() < 1.0 then
        animal:setHealth(1.0)
    end
end

function EffectSpawnFireChickens:OnStart()
    ChaosEffectBase:OnStart()
    self.chickens = {}

    local player = getPlayer()
    if not player then return end

    for _ = 1, CHICKEN_COUNT do
        local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, MIN_SPAWN_DIST, MAX_SPAWN_DIST,
            MAX_SPAWN_TRIES, true, true, false)
        if square then
            local breed = CHICKEN_BREEDS[ChaosUtils.RandArrayIndex(CHICKEN_BREEDS)]
            if breed then
                local animal = ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), "hen", breed)
                if animal then
                    table.insert(self.chickens, {
                        animal = animal,
                        wanderTimer = ChaosManualTimer.new(randomWanderCooldownMs()),
                    })
                end
            end
        end
    end
end

---@param deltaMs integer
function EffectSpawnFireChickens:OnTick(deltaMs)
    if not self.chickens then return end
    local cell = getCell()
    if not cell then return end

    for _, entry in ipairs(self.chickens) do
        local animal = entry.animal
        if animal and not animal:isDead() then
            animal:setVariable("animalRunning", true)
            keepChickenFireproof(animal)

            local currentSquare = animal:getSquare()
            if currentSquare then
                IsoFireManager.StartFire(cell, currentSquare, true, 100, 3000)
            end

            entry.wanderTimer:add(deltaMs)
            if entry.wanderTimer:isEnded() then
                entry.wanderTimer:reset()
                entry.wanderTimer:setMax(randomWanderCooldownMs())
                repathChickenNearPlayer(entry)
            end
        end
    end
end

function EffectSpawnFireChickens:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.chickens then
        for _, entry in ipairs(self.chickens) do
            killChicken(entry.animal)
        end
        self.chickens = {}
    end
end
