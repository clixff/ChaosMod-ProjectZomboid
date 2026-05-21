---@class EffectHurricane : ChaosEffectBase
---@field dirX number
---@field dirY number
---@field previousPrecipitationIsSnow boolean
EffectHurricane = ChaosEffectBase:derive("EffectHurricane", "hurricane")

local CHARACTER_SPEED  = 15.0
local VEHICLE_STRENGTH = 50000
local SEARCH_RADIUS    = 40

---@param sq1 IsoGridSquare
---@param sq2 IsoGridSquare
---@return boolean
local function hasWallOrFenceBetween(sq1, sq2)
    if not sq1 or not sq2 or sq1 == sq2 then
        return false
    end

    if sq1:isWallTo(sq2) then
        return true
    end

    if sq1:isHoppableTo(sq2) then
        return true
    end

    if sq1:getHoppableThumpableTo(sq2) ~= nil then
        return true
    end

    return false
end

---@param character IsoGameCharacter
---@param stepX number
---@param stepY number
local function moveCharacterWithWind(character, stepX, stepY)
    if not character then return end

    local cx = character:getX()
    local cy = character:getY()
    local cz = character:getZ()

    local nx = cx + stepX
    local ny = cy + stepY

    local cell = getCell()
    if not cell then return end

    local fromSquare = character:getCurrentSquare()
    if not fromSquare then
        fromSquare = cell:getGridSquare(math.floor(cx), math.floor(cy), math.floor(cz))
    end
    if not fromSquare then return end

    local toFloorX = math.floor(nx)
    local toFloorY = math.floor(ny)
    local toFloorZ = math.floor(cz)

    if toFloorX ~= fromSquare:getX() or toFloorY ~= fromSquare:getY() then
        local toSquare = cell:getGridSquare(toFloorX, toFloorY, toFloorZ)
        if not toSquare then return end
        if hasWallOrFenceBetween(fromSquare, toSquare) then
            return
        end
    end

    character:setX(nx)
    character:setY(ny)
end

function EffectHurricane:OnStart()
    ChaosEffectBase:OnStart()

    local angle = ChaosUtils.RandFloat(0.0, math.pi * 2.0)
    self.dirX = math.cos(angle)
    self.dirY = math.sin(angle)

    local cm = ClimateManager.getInstance()
    if cm then
        self.previousPrecipitationIsSnow = cm:getPrecipitationIsSnow()
        cm:setPrecipitationIsSnow(false)
        ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 1.0)
    end

    ChaosVehicle.ExitVehicle(getPlayer())
end

---@param deltaMs integer
function EffectHurricane:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local cm = ClimateManager.getInstance()
    if cm then
        ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 1.0)
    end

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local dx = self.dirX
    local dy = self.dirY
    local moveStep = CHARACTER_SPEED * (deltaMs / 1000.0)
    local stepX = dx * moveStep
    local stepY = dy * moveStep

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, SEARCH_RADIUS)
    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            vehicle:setPhysicsActive(true)
            local impulse = Vector3f.new(dx * VEHICLE_STRENGTH, 0, dy * VEHICLE_STRENGTH)
            local relPos = Vector3f.new(0, 0, 0)
            vehicle:addImpulse(impulse, relPos)
        end
    end

    if not player:getVehicle() then
        moveCharacterWithWind(player, stepX, stepY)
    end

    local px = player:getX()
    local py = player:getY()
    ChaosZombie.ForEachZombieInRange(px, py, SEARCH_RADIUS, function(zombie)
        moveCharacterWithWind(zombie, stepX, stepY)
    end, true, nil)
end

function EffectHurricane:OnEnd()
    ChaosEffectBase:OnEnd()

    local cm = ClimateManager.getInstance()
    if not cm then return end

    cm:setPrecipitationIsSnow(self.previousPrecipitationIsSnow or false)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, false, 0.0)
end
