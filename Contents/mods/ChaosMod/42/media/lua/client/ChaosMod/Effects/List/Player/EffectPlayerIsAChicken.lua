---@class EffectPlayerIsAChicken : ChaosEffectBase
---@field chicken IsoAnimal?
---@field specialAnimal SpecialAnimal?
---@field previousBannedAttacking boolean
---@field affectedZombies table<IsoZombie, boolean>
EffectPlayerIsAChicken = ChaosEffectBase:derive("EffectPlayerIsAChicken", "player_is_a_chicken")

---@type number
local ZOMBIE_SIGHT_RADIUS = 30

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
local function disableChickenCollision(animal)
    if animal.setSolid then
        animal:setSolid(false)
    end
    if animal.setCollidable then
        animal:setCollidable(false)
    end
    if animal.setWidth then
        animal:setWidth(0.0)
    end
end

function EffectPlayerIsAChicken:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)

    ChaosNPCUtils.AddNPCIgnorePlayerEffect("player_is_a_chicken")

    if player.isBannedAttacking then
        self.previousBannedAttacking = player:isBannedAttacking()
    else
        self.previousBannedAttacking = false
    end
    if player.setBannedAttacking then
        player:setBannedAttacking(true)
    end

    self.affectedZombies = {}

    getCore():setDisplayPlayerModel(false)

    local px, py, pz = player:getX(), player:getY(), player:getZ()
    local chicken = ChaosAnimals.SpawnAnimal(px, py, pz, "hen", "rhodeisland")
    if not chicken then return end

    disableChickenCollision(chicken)

    self.chicken = chicken
    self.specialAnimal = SpecialAnimal:new(chicken)
    if self.specialAnimal then
        self.specialAnimal.followCharacter = nil
        self.specialAnimal.renderNickname = false
    end
end

---@param deltaMs integer
function EffectPlayerIsAChicken:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    if player.setBannedAttacking then
        player:setBannedAttacking(true)
    end

    local px, py, pz = player:getX(), player:getY(), player:getZ()

    ChaosZombie.ForEachZombieInRange(px, py, ZOMBIE_SIGHT_RADIUS, function(zombie)
        if zombie and zombie:getTarget() == player then
            ---@diagnostic disable-next-line: param-type-mismatch
            zombie:setTarget(nil)
            zombie:setTargetSeenTime(0)
        end
        if zombie and not self.affectedZombies[zombie] then
            zombie:setUseless(true)
            self.affectedZombies[zombie] = true
        end
    end, true, pz)

    local chicken = self.chicken
    if not chicken or chicken:isDead() then return end

    disableChickenCollision(chicken)

    chicken:setX(px)
    chicken:setY(py)
    chicken:setZ(pz)
    chicken:setCurrentSquareFromPosition(px, py, pz)

    local fx = player:getForwardDirectionX()
    local fy = player:getForwardDirectionY()
    if fx ~= 0 or fy ~= 0 then
        chicken:setForwardDirection(fx, fy)
    end

    if chicken.stopAllMovementNow then
        chicken:stopAllMovementNow()
    end

    if chicken.addLineChatElement then
        chicken:addLineChatElement("")
    end
end

function EffectPlayerIsAChicken:OnEnd()
    ChaosEffectBase:OnEnd()

    getCore():setDisplayPlayerModel(true)

    ChaosNPCUtils.RemoveNPCIgnorePlayerEffect("player_is_a_chicken")

    local player = getPlayer()
    if player then
        if player.setBannedAttacking then
            player:setBannedAttacking(self.previousBannedAttacking == true)
        end
    end

    if self.affectedZombies then
        for zombie, _ in pairs(self.affectedZombies) do
            if zombie then
                zombie:setUseless(false)
            end
        end
        self.affectedZombies = nil
    end

    if self.chicken then
        removeAnimalFollower(self.chicken)
        if not self.chicken:isDead() then
            self.chicken:removeFromWorld()
        end
    end

    self.chicken = nil
    self.specialAnimal = nil
end
