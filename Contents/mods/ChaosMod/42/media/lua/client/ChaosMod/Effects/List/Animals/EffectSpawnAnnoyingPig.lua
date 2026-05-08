---@class EffectSpawnAnnoyingPig : ChaosEffectBase
---@field pig IsoAnimal?
---@field specialAnimal SpecialAnimal?
EffectSpawnAnnoyingPig = ChaosEffectBase:derive("EffectSpawnAnnoyingPig", "spawn_annoying_pig")

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

function EffectSpawnAnnoyingPig:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 1, 6, 50, true, true, true)
    if not square then return end

    local breed = PIG_BREEDS[ChaosUtils.RandArrayIndex(PIG_BREEDS)]
    if not breed then return end

    self.pig = ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), "sow", breed)
    if not self.pig then return end

    self.specialAnimal = SpecialAnimal:new(self.pig)
    self.specialAnimal.repathTicks = 400
    self.specialAnimal.followPlayer = true
end

---@param deltaMs integer
function EffectSpawnAnnoyingPig:OnTick(deltaMs)
    local _ = deltaMs

    local player = getPlayer()
    local pig = self.pig
    if not player or not pig or pig:isDead() then return end

    local playerSquare = player:getSquare()
    local pigSquare = pig:getSquare()
    if not playerSquare or not pigSquare then return end

    if playerSquare == pigSquare and not ChaosPlayer.IsPlayerKnockedDown(player) then
        player:setKnockedDown(true)
    end
end

function EffectSpawnAnnoyingPig:OnEnd()
    ChaosEffectBase:OnEnd()

    removeAnimalFollower(self.pig)
    killAnimal(self.pig)

    self.specialAnimal = nil
    self.pig = nil
end
