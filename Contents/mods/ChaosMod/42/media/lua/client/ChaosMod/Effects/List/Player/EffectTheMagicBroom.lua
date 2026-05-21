---@class EffectTheMagicBroom : ChaosEffectBase
---@field worldBroomItem InventoryItem?
---@field worldBroomObj IsoWorldInventoryObject?
---@field currentSpeed number
---@field heading number
EffectTheMagicBroom = ChaosEffectBase:derive("EffectTheMagicBroom", "the_magic_broom")

---@type string
local BROOM_ITEM_ID = "Base.Broom_Twig"
---@type string
local BUMP_TYPE = "ChaosPlayerSit"
---@type number
local FLIGHT_Z = 0.85
---@type number
local MAX_SPEED = 40.0
---@type number
local ACCELERATION = 15.0
---@type number
local DECELERATION = 20.0
---@type number
local TURN_RATE = 120.0
---@type number
local Z_OFFSET = 0.15
---@type number
local X_ROT = 0.0
---@type number
local Z_ROT = 0.0

---@param angle number
---@return number
local function normalize360(angle)
    angle = angle % 360
    if angle < 0 then
        angle = angle + 360
    end
    return angle
end

---@param player IsoGameCharacter
local function lockFallPhysics(player)
    player:setbClimbing(true)
    player:setbFalling(false)
    player:setFallTime(0)
    player:setLastFallSpeed(0)
    player:setLastZ(player:getZ())
end

---@param player IsoGameCharacter
local function unlockFallPhysics(player)
    player:setbClimbing(false)
    player:setbFalling(false)
    player:setFallTime(0)
    player:setLastFallSpeed(0)
    player:setLastZ(player:getZ())
    player:setCurrentSquareFromPosition()
end

---@param player IsoPlayer
---@return IsoGridSquare?
local function getFloorSquareUnderPlayer(player)
    local cell = getCell()
    if not cell then return nil end
    return cell:getGridSquare(player:getX(), player:getY(), 0)
end

---@param self EffectTheMagicBroom
local function removeBroom(self)
    if self.worldBroomObj then
        ChaosUtils.RemoveWorldObject(self.worldBroomObj)
    end
    self.worldBroomItem = nil
    self.worldBroomObj = nil
end

---@param self EffectTheMagicBroom
---@param player IsoPlayer
---@param square IsoGridSquare
---@return number
---@return number
---@return number
local function computeBroomOffsets(self, player, square)
    local offX = player:getX() - square:getX()
    local offY = player:getY() - square:getY()
    local offZ = (player:getZ() - square:getZ()) + Z_OFFSET
    return offX, offY, offZ
end

---@param self EffectTheMagicBroom
---@param player IsoPlayer
---@param square IsoGridSquare
---@param angle number
local function ensureBroom(self, player, square, angle)
    if not self.worldBroomItem or not self.worldBroomObj then
        local item = instanceItem(BROOM_ITEM_ID)
        if not item then return end

        local offX, offY, offZ = computeBroomOffsets(self, player, square)
        local placedItem = square:AddWorldInventoryItem(item, offX, offY, offZ, false)
        if not placedItem then return end

        self.worldBroomItem = placedItem
        self.worldBroomObj = placedItem:getWorldItem()
        if not self.worldBroomObj then
            self.worldBroomItem = nil
            return
        end
    end

    local item = self.worldBroomItem
    local worldObj = self.worldBroomObj
    if not item or not worldObj then return end

    local offX, offY, offZ = computeBroomOffsets(self, player, square)

    if worldObj:getSquare() ~= square then
        local oldSquare = worldObj:getSquare()
        if oldSquare then
            oldSquare:transmitRemoveItemFromSquare(worldObj)
        end

        local newPlacedItem = square:AddWorldInventoryItem(item, offX, offY, offZ, false)
        if not newPlacedItem then
            self.worldBroomItem = nil
            self.worldBroomObj = nil
            return
        end

        self.worldBroomItem = newPlacedItem
        self.worldBroomObj = newPlacedItem:getWorldItem()
        item = self.worldBroomItem
        worldObj = self.worldBroomObj
        if not item or not worldObj then return end
    end

    item:setWorldXRotation(X_ROT)
    item:setWorldYRotation(0.0)
    item:setWorldZRotation(angle)

    worldObj:setOffX(offX)
    worldObj:setOffY(offY)
    worldObj:setOffZ(offZ)
    worldObj:setExtendedPlacement(true)
    worldObj:syncExtendedPlacement()
    worldObj:setTargetAlpha(0, 1.0)
end

function EffectTheMagicBroom:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)
    lockFallPhysics(player)
    -- player:setZ(FLIGHT_Z)
    player:setCurrentSquareFromPosition(player:getX(), player:getY(), 0)

    self.currentSpeed = 20.0
    local fx = player:getForwardDirectionX() or 1
    local fy = player:getForwardDirectionY() or 0
    if fx == 0 and fy == 0 then fx = 1 end
    self.heading = normalize360(math.deg(math.atan(fy, fx)))
end

---@param deltaMs integer
function EffectTheMagicBroom:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    player:setBumpType(BUMP_TYPE)

    local delta = deltaMs / 1000.0

    if isKeyDown(Keyboard.KEY_W) then
        self.currentSpeed = math.min(MAX_SPEED, self.currentSpeed + ACCELERATION * delta)
    end
    if isKeyDown(Keyboard.KEY_S) then
        self.currentSpeed = math.max(0, self.currentSpeed - DECELERATION * delta)
    end
    if isKeyDown(Keyboard.KEY_A) then
        self.heading = normalize360(self.heading - TURN_RATE * delta)
    end
    if isKeyDown(Keyboard.KEY_D) then
        self.heading = normalize360(self.heading + TURN_RATE * delta)
    end

    local rad = math.rad(self.heading)
    local fx = math.cos(rad)
    local fy = math.sin(rad)

    if self.currentSpeed > 0 then
        local step = self.currentSpeed * delta
        player:setX(player:getX() + fx * step)
        player:setY(player:getY() + fy * step)
    end

    player:setForwardDirection(fx, fy)
    player:setZ(FLIGHT_Z)
    lockFallPhysics(player)

    local square = getFloorSquareUnderPlayer(player)
    if not square then return end

    ensureBroom(self, player, square, normalize360(self.heading + 180))
end

function EffectTheMagicBroom:OnEnd()
    ChaosEffectBase:OnEnd()

    local player = getPlayer()
    if player then
        player:setBumpType("")
        player:setBumpDone(true)
        player:setBumpStaggered(false)
        player:setBumpFall(false)
        player:postAnimationFinishing()
        local square = getFloorSquareUnderPlayer(player)
        local groundZ = square and square:getZ() or 0
        player:setZ(groundZ)
        unlockFallPhysics(player)
    end

    removeBroom(self)
end
