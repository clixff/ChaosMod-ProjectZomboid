---@diagnostic disable: undefined-field
---@class EffectPigTurret : ChaosEffectBase
---@field pig IsoAnimal?
---@field specialAnimal SpecialAnimal?
---@field worldGunItem InventoryItem?
---@field worldGunObj IsoWorldInventoryObject?
---@field lastShotMs integer
---@field lastRetargetMs integer
---@field lastWanderMs integer
EffectPigTurret = ChaosEffectBase:derive("EffectPigTurret", "pig_turret")

---@type integer
local RETARGET_INTERVAL_MS = 4000
---@type integer
local WANDER_INTERVAL_MS = 1000
---@type integer
local WANDER_RADIUS = 4
---@type integer
local WANDER_MAX_TRIES = 10

---@type string[]
local PIG_BREEDS = { "landrace", "largeblack" }
---@type string
local WEAPON_ITEM_ID = "Base.AssaultRifle"
---@type number
local Z_OFFSET = 0.3
---@type integer
local X_ROT = 270
---@type integer
local Z_ROT = 0
---@type integer
local MIN_RADIUS = 4
---@type integer
local MAX_RADIUS = 8
---@type integer
local MAX_TRIES = 50
---@type integer
local MAX_ATTACK_DIST = 15
---@type integer
local SHOT_COOLDOWN_MS = 800
---@type number
local ZOMBIE_MISS_CHANCE = 0.3
---@type number
local PLAYER_MISS_CHANCE = 0.8
---@param dist number
---@return number
local function getPlayerHitChanceForDist(dist)
    if dist <= 1.0 then return 0.45 end
    if dist <= 10.0 then
        local t = (dist - 1.0) / (10.0 - 1.0)
        return 0.45 + (0.1 - 0.45) * t
    end
    if dist <= 15.0 then
        local t = (dist - 10.0) / (15.0 - 10.0)
        return 0.1 + (0.0 - 0.1) * t
    end
    return 0.0
end
---@type number[]
local FACING_DOT_DEBUG = { 0.0, 0.25, 0.5, 0.8, 1.0 }

---@param angle number
---@return number
local function normalize360(angle)
    angle = angle % 360
    if angle < 0 then
        angle = angle + 360
    end
    return angle
end

---@param movingObj IsoMovingObject
---@param square IsoGridSquare
---@return number
---@return number
local function getTileOffsetXY(movingObj, square)
    local offX = movingObj:getX() - square:getX()
    local offY = movingObj:getY() - square:getY()
    return offX, offY
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

local PigWeaponAttach = {}

---@param data EffectPigTurret
---@param square IsoGridSquare
---@return boolean
function PigWeaponAttach.ensureItem(data, square)
    if data.worldGunItem then return true end

    local item = instanceItem(WEAPON_ITEM_ID)
    if not item then return false end

    local placedItem = square:AddWorldInventoryItem(item, 0.5, 0.5, Z_OFFSET, false)
    if not placedItem then return false end

    data.worldGunItem = placedItem
    data.worldGunObj = placedItem:getWorldItem()
    return data.worldGunObj ~= nil
end

---@param pig IsoAnimal?
---@param data EffectPigTurret
function PigWeaponAttach.update(pig, data)
    if not pig then return end

    local square = pig:getCurrentSquare()
    if not square then return end

    if not PigWeaponAttach.ensureItem(data, square) then
        return
    end

    local item = data.worldGunItem
    local worldObj = data.worldGunObj
    if not item or not worldObj then
        return
    end

    local offX, offY = getTileOffsetXY(pig, square)
    local rotY = normalize360(pig:getAnimAngle())

    if worldObj:getSquare() ~= square then
        local oldSquare = worldObj:getSquare()
        if oldSquare then
            oldSquare:transmitRemoveItemFromSquare(worldObj)
        end

        local newPlacedItem = square:AddWorldInventoryItem(item, offX, offY, Z_OFFSET, false)
        if not newPlacedItem then
            data.worldGunItem = nil
            data.worldGunObj = nil
            return
        end

        data.worldGunItem = newPlacedItem
        data.worldGunObj = newPlacedItem:getWorldItem()
        item = data.worldGunItem
        worldObj = data.worldGunObj
        if not item or not worldObj then return end
    end

    item:setWorldXRotation(X_ROT)
    item:setWorldYRotation(rotY)
    item:setWorldZRotation(Z_ROT)

    worldObj:setOffX(offX)
    worldObj:setOffY(offY)
    worldObj:setOffZ(Z_OFFSET)
    worldObj:setExtendedPlacement(true)
    worldObj:syncExtendedPlacement()
end

---@param square IsoGridSquare?
local function addShotFlash(square)
    if not square then return end

    local cell = getCell()
    if not cell then return end

    local light = IsoLightSource.new(
        square:getX(),
        square:getY(),
        square:getZ(),
        0.8, 0.8, 0.6,
        18,
        6
    )
    cell:addLamppost(light)
end

---@param fromSquare IsoGridSquare?
---@param toSquare IsoGridSquare?
---@return boolean
local function canLineTraceSquare(fromSquare, toSquare)
    if not fromSquare or not toSquare then return false end

    local lineTrace = tostring(LosUtil.lineClear(
        fromSquare:getCell(),
        fromSquare:getX(), fromSquare:getY(), fromSquare:getZ(),
        toSquare:getX(), toSquare:getY(), toSquare:getZ(),
        false
    ))

    return lineTrace == "Clear"
end

---@param pig IsoAnimal?
---@param target IsoGameCharacter?
---@return boolean
local function isTargetInFrontOfPig(pig, target)
    if not pig or not target then return false end
    return pig:isFacingLocation(target:getX(), target:getY(), 0.8)
end

---@param pigSquare IsoGridSquare?
---@param target IsoGameCharacter?
---@return boolean
local function isTargetValid(pigSquare, target)
    if not pigSquare or not target then return false end
    if not target:isAlive() then return false end

    local targetSquare = target:getSquare()
    if not targetSquare then return false end
    if targetSquare:getZ() ~= pigSquare:getZ() then return false end

    local dist = ChaosUtils.distTo(pigSquare:getX(), pigSquare:getY(), target:getX(), target:getY())
    if dist > MAX_ATTACK_DIST then return false end

    return canLineTraceSquare(pigSquare, targetSquare)
end

---@param pig IsoAnimal?
---@param pigSquare IsoGridSquare?
---@return IsoPlayer?
---@return number
local function getPlayerTarget(pig, pigSquare)
    local player = getPlayer()
    if not player or not pigSquare then return nil, math.huge end
    if not isTargetValid(pigSquare, player) then return nil, math.huge end
    if not isTargetInFrontOfPig(pig, player) then return nil, math.huge end

    local dist = ChaosUtils.distTo(pigSquare:getX(), pigSquare:getY(), player:getX(), player:getY())
    return player, dist
end

---@param pig IsoAnimal?
---@param pigSquare IsoGridSquare?
---@return IsoZombie?
---@return number
local function getNearestZombieTarget(pig, pigSquare)
    if not pig or not pigSquare then return nil, math.huge end

    local zombies = ChaosZombie.GetNearestZombies(
        pigSquare:getX(),
        pigSquare:getY(),
        MAX_ATTACK_DIST,
        true,
        pigSquare:getZ()
    )

    local nearestZombie = nil
    local nearestDist = math.huge

    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if isTargetValid(pigSquare, zombie) and isTargetInFrontOfPig(pig, zombie) then
            local dist = ChaosUtils.distTo(pigSquare:getX(), pigSquare:getY(), zombie:getX(), zombie:getY())
            if dist < nearestDist then
                nearestDist = dist
                nearestZombie = zombie
            end
        end
    end

    return nearestZombie, nearestDist
end

---@param pig IsoAnimal?
---@return IsoGameCharacter?
local function findShotTarget(pig)
    if not pig then return nil end

    local pigSquare = pig:getCurrentSquare()
    if not pigSquare then return nil end

    local playerTarget, playerDist = getPlayerTarget(pig, pigSquare)
    local zombieTarget, zombieDist = getNearestZombieTarget(pig, pigSquare)

    if playerTarget and playerDist <= zombieDist then
        return playerTarget
    end

    return zombieTarget
end

---@param pigSquare IsoGridSquare?
---@param target IsoGameCharacter?
local function playShotEffects(pigSquare, target)
    if not pigSquare then return end

    local weapon = instanceItem(WEAPON_ITEM_ID)
    if not weapon then return end

    if weapon.setJammed then weapon:setJammed(false) end
    if weapon.setContainsClip then weapon:setContainsClip(true) end
    if weapon.setRoundChambered then weapon:setRoundChambered(true) end
    weapon:setCurrentAmmoCount(30)
    if target and weapon.setAttackTargetSquare then
        weapon:setAttackTargetSquare(target:getSquare())
    end

    local sound = weapon.getSwingSound and weapon:getSwingSound() or "M16Shoot"
    if isServer() then
        playServerSound(sound, pigSquare)
    else
        pigSquare:playSound(sound)
    end
    addShotFlash(pigSquare)

    local soundRadius = math.floor(weapon.getSoundRadius and weapon:getSoundRadius() or 70)
    local soundVolume = math.floor(weapon.getSoundVolume and weapon:getSoundVolume() or 100)

    getWorldSoundManager():addSound(
        nil,
        pigSquare:getX(), pigSquare:getY(), pigSquare:getZ(),
        soundRadius,
        soundVolume,
        false
    )
end

---@param pigSquare IsoGridSquare
---@param target IsoGameCharacter
---@return IsoGameCharacter
local function createFakeAttacker(pigSquare, target)
    local attacker = getFakeAttacker()
    attacker:setX(pigSquare:getX() + 0.5)
    attacker:setY(pigSquare:getY() + 0.5)
    attacker:setZ(pigSquare:getZ())
    attacker:setForwardDirection(target:getX() - attacker:getX(), target:getY() - attacker:getY())
    attacker:setAttackTargetSquare(target:getSquare())
    attacker:setCriticalHit(false)
    return attacker
end

---@param target IsoGameCharacter
---@param weapon HandWeapon
---@param attacker IsoGameCharacter
local function applyShotDamage(target, weapon, attacker)
    local minDamage = weapon.getMinDamage and weapon:getMinDamage() or 0.8
    local maxDamage = weapon.getMaxDamage and weapon:getMaxDamage() or 1.2
    local damage = ChaosUtils.RandFloat(minDamage, maxDamage)


    if instanceof(target, "IsoPlayer") then
        damage = damage * 0.5
    end

    target:Hit(weapon, attacker, damage, false, 1.0, false)

    if instanceof(target, "IsoZombie") then
        target:addBlood(BloodBodyPartType.Head, true, true, true)
    end
end

---@param self EffectPigTurret
local function firePigTurret(self)
    local pig = self.pig
    if not pig or pig:isDead() then return end

    local now = getTimestampMs()
    if now - (self.lastShotMs or 0) < SHOT_COOLDOWN_MS then return end
    self.lastShotMs = now

    if self.pig then
        self.pig:changeStress(80)
        self.pig:updateStress()
    end

    local pigSquare = pig:getCurrentSquare()
    if not pigSquare then return end

    local target = findShotTarget(pig)
    playShotEffects(pigSquare, target)

    if not target then return end

    local weapon = instanceItem(WEAPON_ITEM_ID)
    if not weapon then return end
    if weapon.setJammed then weapon:setJammed(false) end
    if weapon.setContainsClip then weapon:setContainsClip(true) end
    if weapon.setRoundChambered then weapon:setRoundChambered(true) end
    weapon:setCurrentAmmoCount(30)
    if weapon.setAttackTargetSquare then
        weapon:setAttackTargetSquare(target:getSquare())
    end

    local missChance
    if instanceof(target, "IsoPlayer") then
        local dist = ChaosUtils.distTo(pigSquare:getX(), pigSquare:getY(), target:getX(), target:getY())
        missChance = 1.0 - getPlayerHitChanceForDist(dist)
    else
        missChance = ZOMBIE_MISS_CHANCE
    end
    if ChaosUtils.RandFloat(0, 1) <= missChance then
        return
    end

    local attacker = createFakeAttacker(pigSquare, target)
    applyShotDamage(target, weapon, attacker)
end

function EffectPigTurret:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, 0, MIN_RADIUS, MAX_RADIUS, MAX_TRIES, true, true,
        true)
    if not square then return end

    local breed = PIG_BREEDS[ChaosUtils.RandArrayIndex(PIG_BREEDS)]
    if not breed then return end

    local pig = ChaosAnimals.SpawnAnimal(square:getX(), square:getY(), square:getZ(), "sow", breed)
    if not pig then return end

    self.pig = pig
    self.specialAnimal = SpecialAnimal:new(pig)
    if self.specialAnimal then
        self.specialAnimal.repathTicks = 500
        self.specialAnimal.followCharacter = nil
    end

    self.pig:changeStress(80)
    self.pig:updateStress()
    self.lastShotMs = 0
    self.lastRetargetMs = 0
    self.lastWanderMs = 0

    PigWeaponAttach.update(self.pig, self)
end

---@param pigSquare IsoGridSquare
---@return IsoZombie?
local function findRetargetZombie(pigSquare)
    local zombies = ChaosZombie.GetNearestZombies(
        pigSquare:getX(),
        pigSquare:getY(),
        MAX_ATTACK_DIST,
        true,
        pigSquare:getZ()
    )

    local nearestZombie = nil
    local nearestDist = math.huge

    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if zombie and zombie:isAlive() then
            local zSquare = zombie:getSquare()
            if zSquare and zSquare:getZ() == pigSquare:getZ() then
                local dist = ChaosUtils.distTo(pigSquare:getX(), pigSquare:getY(), zombie:getX(), zombie:getY())
                if dist < nearestDist then
                    nearestDist = dist
                    nearestZombie = zombie
                end
            end
        end
    end

    return nearestZombie
end

---@param self EffectPigTurret
local function updateRetarget(self)
    if not self.specialAnimal or not self.pig then return end

    local now = getTimestampMs()
    if now - (self.lastRetargetMs or 0) < RETARGET_INTERVAL_MS then return end
    self.lastRetargetMs = now

    local pigSquare = self.pig:getCurrentSquare()
    if not pigSquare then return end

    self.specialAnimal.followCharacter = findRetargetZombie(pigSquare)
end

---@param pig IsoAnimal
---@param pigSquare IsoGridSquare
local function pathPigToRandomNearbyLocation(pig, pigSquare)
    local cell = getCell()
    if not cell then return end

    local pigZ = pigSquare:getZ()
    local baseX = pigSquare:getX()
    local baseY = pigSquare:getY()

    for _ = 1, WANDER_MAX_TRIES do
        local dx = ChaosUtils.RandIntegerRange(-WANDER_RADIUS, WANDER_RADIUS + 1)
        local dy = ChaosUtils.RandIntegerRange(-WANDER_RADIUS, WANDER_RADIUS + 1)
        if dx ~= 0 or dy ~= 0 then
            local tx = baseX + dx
            local ty = baseY + dy
            local sq = cell:getGridSquare(tx, ty, pigZ)
            if sq and sq:getFloor() and not sq:isSolid() and not sq:isSolidTrans() then
                pig:pathToLocation(tx, ty, pigZ)
                return
            end
        end
    end
end

---@param self EffectPigTurret
local function updateWander(self)
    local pig = self.pig
    if not pig or not self.specialAnimal then return end

    local follow = self.specialAnimal.followCharacter
    if follow and follow:isAlive() then return end

    local now = getTimestampMs()
    if now - (self.lastWanderMs or 0) < WANDER_INTERVAL_MS then return end
    self.lastWanderMs = now

    local pigSquare = pig:getCurrentSquare()
    if not pigSquare then return end

    pathPigToRandomNearbyLocation(pig, pigSquare)
end

---@param deltaMs integer
function EffectPigTurret:OnTick(deltaMs)
    if not self.pig or self.pig:isDead() then return end

    updateRetarget(self)
    updateWander(self)

    -- local debugPlayer = getPlayer()
    -- if debugPlayer then
    --     local ux, uy = debugPlayer:getX(), debugPlayer:getY()
    --     local parts = {}
    --     for i = 1, #FACING_DOT_DEBUG do
    --         local dot = FACING_DOT_DEBUG[i]
    --         local facing = self.pig:isFacingLocation(ux, uy, dot)
    --         parts[i] = string.format("%.2f=%s", dot, tostring(facing))
    --     end
    --     -- print("[EffectPigTurret] pig:isFacingLocation(user): " .. table.concat(parts, ", "))
    -- end

    if self.worldGunObj then
        self.worldGunObj:setTargetAlpha(0, 1.0)
    end


    PigWeaponAttach.update(self.pig, self)
    firePigTurret(self)
end

function EffectPigTurret:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.worldGunObj then
        ChaosUtils.RemoveWorldObject(self.worldGunObj)
    end

    if self.pig then
        removeAnimalFollower(self.pig)
        killAnimal(self.pig)
    end

    self.pig = nil
    self.specialAnimal = nil
    self.worldGunItem = nil
    self.worldGunObj = nil
end
