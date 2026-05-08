---@class EffectZombiesTurret : ChaosEffectBase
---@field worldGunItem InventoryItem?
---@field worldGunObj IsoWorldInventoryObject?
---@field target IsoZombie?
---@field currentYRotation number
---@field lastShotMs integer
---@field killCount integer
EffectZombiesTurret = ChaosEffectBase:derive("EffectZombiesTurret", "zombies_turret")

---@type string
local WEAPON_ITEM_ID = "Base.AssaultRifle"
---@type integer
local MAX_ATTACK_DIST = 15
---@type integer
local SHOT_COOLDOWN_MS = 250
---@type number
local ROTATION_EPSILON = 10
---@type number
local ROTATION_SPEED_DEG_PER_SEC = 90
---@type number
local MISS_CHANCE = 0.3
---@type table<string, number>
local KILL_COUNTER_COLOR = { r = 1.0, g = 0.84, b = 0.0 }
---@type boolean
local DEBUG_ROTATION_LOGS = true

---@param angle number
---@return number
local function normalizeAngle(angle)
    angle = angle % 360
    if angle < 0 then
        angle = angle + 360
    end
    return angle
end

---@param fromAngle number
---@param toAngle number
---@return number
local function getShortestAngleDelta(fromAngle, toAngle)
    local delta = (toAngle - fromAngle + 180) % 360 - 180
    return delta
end

---@param currentAngle number
---@param targetAngle number
---@param maxStep number
---@return number
local function rotateTowards(currentAngle, targetAngle, maxStep)
    local delta = getShortestAngleDelta(currentAngle, targetAngle)
    if math.abs(delta) <= maxStep then
        return normalizeAngle(targetAngle)
    end

    if delta > 0 then
        return normalizeAngle(currentAngle + maxStep)
    end

    return normalizeAngle(currentAngle - maxStep)
end

---@param fromSquare IsoGridSquare
---@param toSquare IsoGridSquare
---@return number
---@return number
---@return number
local function getAngleToSquare(fromSquare, toSquare)
    -- Rotation mapping used by world item placement:
    -- Y 0   -> [X + 1, Y + 0]
    -- Y 90  -> [X + 0, Y + 1]
    -- Y 180 -> [X - 1, Y + 0]
    -- Y 270 -> [X + 0, Y - 1]
    ---@type number
    local dx = (toSquare:getX() + 0.5) - (fromSquare:getX() + 0.5)
    ---@type number
    local dy = (toSquare:getY() + 0.5) - (fromSquare:getY() + 0.5)

    if dx == 0 and dy == 0 then
        return 0, dx, dy
    end

    ---@type number
    local radians = math.atan(dy, dx)
    ---@type number
    local angle = normalizeAngle(math.deg(radians))
    return angle, dx, dy
end

---@param square IsoGridSquare?
local function addShotFlash(square)
    if not square then return end

    ---@type IsoCell?
    local cell = getCell()
    if not cell then return end

    ---@type IsoLightSource
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

---@param self EffectZombiesTurret
---@param rotationY number
local function applyTurretRotation(self, rotationY)
    if not self.worldGunItem then return end

    self.currentYRotation = normalizeAngle(rotationY)
    self.worldGunItem:setWorldYRotation(self.currentYRotation)

    ---@type IsoWorldInventoryObject?
    local worldObj = self.worldGunItem:getWorldItem()
    if worldObj then
        worldObj:setOffX(0.5)
        worldObj:setOffY(0.5)
        worldObj:setOffZ(0.5)
        worldObj:setExtendedPlacement(true)
        worldObj:syncExtendedPlacement()
        self.worldGunObj = worldObj
    end
end

---@param fromSquare IsoGridSquare?
---@param zombie IsoZombie?
---@return boolean
local function canLineTraceZombie(fromSquare, zombie)
    if not fromSquare or not zombie then return false end

    local zombieSquare = zombie:getSquare()
    if not zombieSquare then return false end

    ---@type string
    local lineTrace = tostring(LosUtil.lineClear(
        fromSquare:getCell(),
        fromSquare:getX(), fromSquare:getY(), fromSquare:getZ(),
        zombieSquare:getX(), zombieSquare:getY(), zombieSquare:getZ(),
        false
    ))

    return lineTrace == "Clear"
end

---@param worldGunSquare IsoGridSquare?
---@param zombie IsoZombie?
---@return boolean
local function isTargetValid(worldGunSquare, zombie)
    if not worldGunSquare or not zombie then return false end
    if not zombie:isAlive() then return false end

    local zombieSquare = zombie:getSquare()
    if not zombieSquare then return false end
    if zombieSquare:getZ() ~= worldGunSquare:getZ() then return false end

    ---@type number
    local dist = ChaosUtils.distTo(worldGunSquare:getX(), worldGunSquare:getY(), zombie:getX(), zombie:getY())
    if dist > MAX_ATTACK_DIST then return false end

    return canLineTraceZombie(worldGunSquare, zombie)
end

---@param player IsoPlayer?
---@param worldGunSquare IsoGridSquare?
---@return IsoZombie?
local function findNearestZombieTarget(player, worldGunSquare)
    if not player or not worldGunSquare then return nil end


    ---@type ArrayList<IsoZombie>
    local zombies = ChaosZombie.GetNearestZombies(
        worldGunSquare:getX(),
        worldGunSquare:getY(),
        MAX_ATTACK_DIST,
        true,
        worldGunSquare:getZ()
    )

    ---@type IsoZombie?
    local nearestZombie = nil
    ---@type number
    local nearestDist = math.huge

    for i = 0, zombies:size() - 1 do
        ---@type IsoZombie
        local zombie = zombies:get(i)
        if isTargetValid(worldGunSquare, zombie) then
            ---@type number
            local dist = ChaosUtils.distTo(worldGunSquare:getX(), worldGunSquare:getY(), zombie:getX(), zombie:getY())
            if dist < nearestDist then
                nearestDist = dist
                nearestZombie = zombie
            end
        end
    end

    return nearestZombie
end

---@param self EffectZombiesTurret
local function spawnTurret(self)
    ---@type IsoPlayer?
    local player = getPlayer()
    if not player then return end

    ---@type IsoGridSquare?
    local targetSquare = player:getSquare()
    if not targetSquare then return end

    ---@type InventoryItem?
    local item = instanceItem(WEAPON_ITEM_ID)
    if not item then return end

    ---@type InventoryItem?
    local placedItem = targetSquare:AddWorldInventoryItem(item, 0.5, 0.5, 0.5, false)
    if not placedItem then return end

    placedItem:setWorldXRotation(270)
    placedItem:setWorldYRotation(0)
    placedItem:setWorldZRotation(0)

    ---@type IsoWorldInventoryObject?
    local worldObj = placedItem:getWorldItem()
    if worldObj then
        worldObj:setOffX(0.5)
        worldObj:setOffY(0.5)
        worldObj:setOffZ(0.5)
        worldObj:setExtendedPlacement(true)
        worldObj:syncExtendedPlacement()
    end

    self.worldGunItem = placedItem
    self.worldGunObj = worldObj
    self.currentYRotation = 0
    self.lastShotMs = 0
    self.killCount = 0

    applyTurretRotation(self, 0)
end

---@param self EffectZombiesTurret
---@param target IsoZombie?
local function fakeM16Shot(self, target)
    if not self.worldGunObj or not target then return end
    if not instanceof(target, "IsoZombie") then return end

    ---@type integer
    local now = getTimestampMs()
    if now - self.lastShotMs < SHOT_COOLDOWN_MS then return end
    self.lastShotMs = now

    ---@type IsoGridSquare?
    local sq = self.worldGunObj:getSquare()
    if not sq then return end

    ---@type HandWeapon?
    local weapon = self.worldGunObj:getItem()
    if not weapon then
        weapon = instanceItem(WEAPON_ITEM_ID)
    end
    if not weapon then return end

    if weapon.setJammed then weapon:setJammed(false) end
    if weapon.setContainsClip then weapon:setContainsClip(true) end
    if weapon.setRoundChambered then weapon:setRoundChambered(true) end
    weapon:setCurrentAmmoCount(30)
    if weapon.setAttackTargetSquare then weapon:setAttackTargetSquare(target:getSquare()) end

    ---@type IsoGameCharacter
    local attacker = getFakeAttacker()
    attacker:setX(sq:getX() + 0.5)
    attacker:setY(sq:getY() + 0.5)
    attacker:setZ(sq:getZ())
    attacker:setForwardDirection(target:getX() - attacker:getX(), target:getY() - attacker:getY())
    attacker:setAttackTargetSquare(target:getSquare())
    attacker:setCriticalHit(false)

    ---@type string
    local sound = weapon.getSwingSound and weapon:getSwingSound() or "M16Shoot"
    if isServer() then
        playServerSound(sound, sq)
    else
        sq:playSound(sound)
    end
    addShotFlash(sq)

    ---@type integer
    local soundRadius = math.floor(weapon.getSoundRadius and weapon:getSoundRadius() or 70)
    ---@type integer
    local soundVolume = math.floor(weapon.getSoundVolume and weapon:getSoundVolume() or 100)

    getWorldSoundManager():addSound(
        nil,
        sq:getX(), sq:getY(), sq:getZ(),
        soundRadius,
        soundVolume,
        false
    )

    if ChaosUtils.RandFloat(0, 1) <= MISS_CHANCE then
        return
    end

    ---@type number
    local minDamage = weapon.getMinDamage and weapon:getMinDamage() or 0.8
    ---@type number
    local maxDamage = weapon.getMaxDamage and weapon:getMaxDamage() or 1.2
    ---@type number
    local damage = ChaosUtils.RandFloat(minDamage, maxDamage)
    target:Hit(weapon, attacker, damage, false, 1.0, false)
    target:addBlood(BloodBodyPartType.Head, true, true, true)

    if target:isDead() then
        self.killCount = (self.killCount or 0) + 1

        ---@type IsoPlayer?
        local player = getPlayer()
        if player then
            ChaosPlayer.SayLineByColor(player, string.format("Killed %d", self.killCount), KILL_COUNTER_COLOR)
        end
        return
    end

    if not target:isOnFloor() then
        target:setStaggerBack(true)
        target:changeState(StaggerBackState.instance())
    end
end

function EffectZombiesTurret:OnStart()
    ChaosEffectBase:OnStart()
    spawnTurret(self)
end

---@param deltaMs integer
function EffectZombiesTurret:OnTick(deltaMs)
    if not self.worldGunItem or not self.worldGunObj then return end

    ---@type IsoGridSquare?
    local worldGunSquare = self.worldGunObj:getSquare()
    if not worldGunSquare then return end

    ---@type IsoPlayer?
    local player = getPlayer()
    if not player then return end

    if not isTargetValid(worldGunSquare, self.target) then
        self.target = findNearestZombieTarget(player, worldGunSquare)
    end

    if not self.target then return end

    ---@type IsoGridSquare?
    local targetSquare = self.target:getSquare()
    if not targetSquare then
        self.target = nil
        return
    end

    ---@type number
    local desiredYRotation
    ---@type number
    local dx
    ---@type number
    local dy
    desiredYRotation, dx, dy = getAngleToSquare(worldGunSquare, targetSquare)

    ---@type number
    local maxStep = ROTATION_SPEED_DEG_PER_SEC * (deltaMs / 1000)
    ---@type number
    local previousRotation = self.currentYRotation or 0
    ---@type number
    local nextRotation = rotateTowards(previousRotation, desiredYRotation, maxStep)
    applyTurretRotation(self, nextRotation)

    if DEBUG_ROTATION_LOGS then
        print(string.format(
            "[EffectZombiesTurret] diff=(%.2f, %.2f) desired=%.2f previous=%.2f next=%.2f target=(%d,%d,%d) turret=(%d,%d,%d)",
            dx,
            dy,
            desiredYRotation,
            previousRotation,
            nextRotation,
            targetSquare:getX(), targetSquare:getY(), targetSquare:getZ(),
            worldGunSquare:getX(), worldGunSquare:getY(), worldGunSquare:getZ()
        ))
    end

    ---@type number
    local angleDelta = math.abs(getShortestAngleDelta(self.currentYRotation, desiredYRotation))
    if angleDelta > ROTATION_EPSILON then return end

    fakeM16Shot(self, self.target)
end

function EffectZombiesTurret:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.worldGunObj then
        ChaosUtils.RemoveWorldObject(self.worldGunObj)
    end

    self.worldGunItem = nil
    self.worldGunObj = nil
    self.target = nil
end
