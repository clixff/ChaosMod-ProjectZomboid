---@class EffectSpawnAnimal : ChaosEffectBase
---@field animals table<integer, IsoAnimal>
---@field timerMs integer
EffectSpawnAnimal = ChaosEffectBase:derive("EffectSpawnAnimal", "spawn_animal")

local MAX_TIMER_MS = 5000

function EffectSpawnAnimal:OnStart()
    ChaosEffectBase:OnStart()
    self.animals = {}
    print("[EffectSpawnAnimal] OnStart" .. tostring(self.effectId))
    local player = getPlayer()

    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, square:getZ(), 1, 6, 50, true, true, true)
    if not randomSquare then return end

    local cell = randomSquare:getCell()

    local x = randomSquare:getX()
    local y = randomSquare:getY()
    local z = randomSquare:getZ()

    -- local animalType = "hen"
    -- local animalBreed = "rhodeisland"

    local animalType = "gobblers"
    local animalBreed = "meleagris"

    local animalDef = AnimalDefinitions.getDef(animalType)

    local breed = animalDef:getBreedByName(animalBreed)
    if not breed then
        print("[EffectSpawnAnimal] Failed to get breed")
        return
    end

    local animal = addAnimal(cell, x, y, z, animalType, breed)
    if not animal then
        print("[EffectSpawnAnimal] Failed to spawn animal")
        return
    end

    -- animal:setWild(true)

    animal:addToWorld()
    animal:setAnimalAttackingOnClient(true)
    animal:getBehavior():goAttack(player)
    animal:changeStress(80)
    animal:updateStress()

    local animalModData = animal:getModData()

    if animalModData then
        local size = animalModData['animalSize']
        print("[EffectSpawnAnimal] Animal size: " .. tostring(size))
    end

    self.timerMs = MAX_TIMER_MS

    table.insert(self.animals, animal)
end

---@param deltaMs integer
function EffectSpawnAnimal:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local shouldAttack = false

    self.timerMs = self.timerMs + deltaMs
    if self.timerMs >= MAX_TIMER_MS then
        shouldAttack = true
        self.timerMs = 0
        print("[EffectSpawnAnimal] Timer reached MAX_TIMER_MS")
    end

    for _, animal in ipairs(self.animals) do
        if animal and animal:isAlive() then
            local behavior = animal:getBehavior()
            local isAttacking = animal:isAttacking() and "1" or "0"
            local blockMovement = animal:isBlockMovement() and "1" or "0"
            local canPath = animal:isCanPath() and "1" or "0"
            local isPathing = animal:isPathing() and "1" or "0"

            local debugString = string.format("[attacking] %s [block] %s [path] %s [pathing] %s", isAttacking,
                blockMovement, canPath,
                isPathing)
            print(debugString)
            if shouldAttack then
                animal:changeStress(80)
                if behavior then
                    behavior:goAttack(player)
                end
            end
        end
    end
end
