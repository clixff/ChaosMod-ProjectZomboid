---@class EffectBlackHole : ChaosEffectBase
---@field centerX integer
---@field centerY integer
---@field centerZ integer
---@field marker WorldMarkers.GridSquareMarker?
---@field elapsedMs integer
EffectBlackHole         = ChaosEffectBase:derive("EffectBlackHole", "black_hole")

local SEARCH_MIN_RADIUS = 50
local SEARCH_MAX_RADIUS = 80
local SEARCH_MAX_TRIES  = 80

local ZOMBIE_RADIUS     = 80.0
local VEHICLE_RADIUS    = 80.0

local ZOMBIE_PULL_SPEED = 15.0
local PLAYER_PULL_SPEED = 2.0
local VEHICLE_STRENGTH  = 40000

local BASE_MARKER_SIZE  = 10.0 * math.sqrt(2.0)
local PULSE_AMPLITUDE   = 0.05
local PULSE_PERIOD_MS   = 3000

---@param c IsoGameCharacter
local function lockFallPhysics(c)
    c:setbClimbing(true)
    c:setbFalling(false)
    c:setFallTime(0)
    c:setLastFallSpeed(0)
    c:setLastZ(c:getZ())
end

---@param c IsoGameCharacter
local function unlockFallPhysics(c)
    c:setbClimbing(false)
    c:setbFalling(false)
    c:setFallTime(0)
    c:setLastFallSpeed(0)
    c:setLastZ(c:getZ())
    c:setCurrentSquareFromPosition()
end

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
local function moveCharacterByStep(character, stepX, stepY)
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

---@param character IsoGameCharacter
---@param targetX number
---@param targetY number
---@param speed number
---@param deltaMs integer
local function pullCharacterTowards(character, targetX, targetY, speed, deltaMs)
    if not character then return end

    local cx = character:getX()
    local cy = character:getY()

    local dx = targetX - cx
    local dy = targetY - cy
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 0.0001 then return end

    local moveStep = speed * (deltaMs / 1000.0)
    local stepX, stepY
    if moveStep >= dist then
        stepX = dx
        stepY = dy
    else
        stepX = (dx / dist) * moveStep
        stepY = (dy / dist) * moveStep
    end

    moveCharacterByStep(character, stepX, stepY)
end

function EffectBlackHole:OnStart()
    ChaosEffectBase:OnStart()

    self.elapsedMs = 0

    local player = getPlayer()
    if not player then return end

    local centerSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, 0,
        SEARCH_MIN_RADIUS, SEARCH_MAX_RADIUS, SEARCH_MAX_TRIES, false, true, false)

    if not centerSquare then return end

    self.centerX = centerSquare:getX()
    self.centerY = centerSquare:getY()
    self.centerZ = centerSquare:getZ()

    ChaosUtils.EFFECT_BLACK_HOLE_ENABLED = true

    ChaosVehicle.ExitVehicle(player)
    lockFallPhysics(player)

    local markers = getWorldMarkers()
    if markers then
        self.marker = markers:addGridSquareMarker(
            centerSquare,
            0.0, 0.0, 0.0,
            false,
            1.0
        )
        if self.marker then
            self.marker:setScaleCircleTexture(false)
            self.marker:setSize(BASE_MARKER_SIZE)
        end
    end
end

---@param deltaMs integer
function EffectBlackHole:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    if not self.centerX then return end

    self.elapsedMs = self.elapsedMs + deltaMs

    if self.marker then
        local phase = (self.elapsedMs % PULSE_PERIOD_MS) / PULSE_PERIOD_MS
        local pulse = 1.0 + PULSE_AMPLITUDE * math.sin(phase * math.pi * 2.0)
        self.marker:setSize(BASE_MARKER_SIZE * pulse)
    end

    local cx = self.centerX + 0.5
    local cy = self.centerY + 0.5

    local player = getPlayer()
    if player then
        lockFallPhysics(player)
        if not player:getVehicle() then
            pullCharacterTowards(player, cx, cy, PLAYER_PULL_SPEED, deltaMs)
        end
    end

    ChaosZombie.ForEachZombieInRange(self.centerX, self.centerY, ZOMBIE_RADIUS, function(zombie)
        pullCharacterTowards(zombie, cx, cy, ZOMBIE_PULL_SPEED, deltaMs)
    end, true, nil)

    local cell = getCell()
    local centerSquare = cell and cell:getGridSquare(self.centerX, self.centerY, self.centerZ) or nil
    if centerSquare then
        local vehicles = ChaosVehicle.GetVehiclesNearby(centerSquare, VEHICLE_RADIUS)
        for i = 0, vehicles:size() - 1 do
            local vehicle = vehicles:get(i)
            if vehicle then
                local vx = vehicle:getX()
                local vy = vehicle:getY()
                local dx = cx - vx
                local dy = cy - vy
                local dist = math.sqrt(dx * dx + dy * dy)
                if dist > 0.0001 then
                    local nx = dx / dist
                    local ny = dy / dist
                    vehicle:setPhysicsActive(true)
                    local impulse = Vector3f.new(nx * VEHICLE_STRENGTH, 0, ny * VEHICLE_STRENGTH)
                    local relPos = Vector3f.new(0, 0, 0)
                    vehicle:addImpulse(impulse, relPos)
                end
            end
        end
    end
end

function EffectBlackHole:OnEnd()
    ChaosEffectBase:OnEnd()

    ChaosUtils.EFFECT_BLACK_HOLE_ENABLED = false

    local player = getPlayer()
    if player then
        unlockFallPhysics(player)
    end

    if self.marker then
        self.marker:remove()
        self.marker = nil
    end
end
