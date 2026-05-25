---@class EffectPlayerIsARat : ChaosEffectBase
---@field rat IsoAnimal?
---@field specialAnimal SpecialAnimal?
---@field previousBannedAttacking boolean
---@field affectedZombies table<IsoZombie, boolean>
EffectPlayerIsARat = ChaosEffectBase:derive("EffectPlayerIsARat", "player_is_a_rat")

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
local function disableRatCollision(animal)
    -- IsoAnimal extends IsoPlayer/IsoMovingObject.  If it stays solid, the player's
    -- separate() collision code treats sprinting/running into it as a bump and can
    -- set BumpFall=true.  Keep the visual rat, but remove it from separation.
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

function EffectPlayerIsARat:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)

    ChaosNPCUtils.AddNPCIgnorePlayerEffect("player_is_a_rat")

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
    local rat = ChaosAnimals.SpawnAnimal(px, py, pz, "rat", "grey")
    if not rat then return end

    disableRatCollision(rat)

    self.rat = rat
    self.specialAnimal = SpecialAnimal:new(rat)
    if self.specialAnimal then
        self.specialAnimal.followCharacter = nil
        self.specialAnimal.renderNickname = false
    end
end

---@param deltaMs integer
function EffectPlayerIsARat:OnTick(deltaMs)
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

    local rat = self.rat
    if not rat or rat:isDead() then return end

    disableRatCollision(rat)

    rat:setX(px)
    rat:setY(py)
    rat:setZ(pz)
    rat:setCurrentSquareFromPosition(px, py, pz)

    local fx = player:getForwardDirectionX()
    local fy = player:getForwardDirectionY()
    if fx ~= 0 or fy ~= 0 then
        rat:setForwardDirection(fx, fy)
    end

    if rat.stopAllMovementNow then
        rat:stopAllMovementNow()
    end

    if rat.addLineChatElement then
        rat:addLineChatElement("")
    end
end

function EffectPlayerIsARat:OnEnd()
    ChaosEffectBase:OnEnd()

    getCore():setDisplayPlayerModel(true)

    ChaosNPCUtils.RemoveNPCIgnorePlayerEffect("player_is_a_rat")

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

    if self.rat then
        removeAnimalFollower(self.rat)
        if not self.rat:isDead() then
            self.rat:removeFromWorld()
        end
    end

    self.rat = nil
    self.specialAnimal = nil
end
