---@class EffectEarthquake : ChaosEffectBase
---@field phaseTimer ChaosManualTimer
---@field knockdownTimer ChaosManualTimer
---@field isUpPhase boolean
---@field affectedZombies table<IsoZombie, boolean>
EffectEarthquake = ChaosEffectBase:derive("EffectEarthquake", "earthquake")

local PHASE_MIN_MS = 250
local PHASE_MAX_MS = 500
local SHAKE_AMPLITUDE = 1
local CHAR_XY_NUDGE = 3.0
local MULT_MIN = 5.5
local MULT_MAX = 10.5
local VEHICLE_UP_IMPULSE = 100000 * 5
local VEHICLE_UP_MULTIPLIER = 1.0
local VEHICLE_DOWN_MULTIPLIER = -2
local VEHICLE_XY_IMPULSE = VEHICLE_UP_IMPULSE * 0.8
local VEHICLE_RANGE = 40
local CHARACTER_RANGE = 30
local CHAR_DOWN_MULTIPLIER = 2
local KNOCKDOWN_COOLDOWN_MS = 3200

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

---@param character IsoGameCharacter
---@param isUp boolean
---@param multiplier number
---@param dirX number
---@param dirY number
local function shakeCharacter(character, isUp, multiplier, dirX, dirY)
    if not character or not character:isAlive() then return end
    if character:getVehicle() then return end

    local zOffset = SHAKE_AMPLITUDE * multiplier
    if isUp then
        character:setZ(character:getZ() + zOffset)
    else
        local newZ = character:getZ() - zOffset * CHAR_DOWN_MULTIPLIER
        if newZ >= 0 then
            character:setZ(newZ)
        end
    end

    local nudge = CHAR_XY_NUDGE * multiplier
    character:setX(character:getX() + dirX * nudge)
    character:setY(character:getY() + dirY * nudge)
end

function EffectEarthquake:OnStart()
    ChaosEffectBase:OnStart()
    self.phaseTimer = ChaosManualTimer.new(ChaosUtils.RandIntegerRange(PHASE_MIN_MS, PHASE_MAX_MS))
    self.knockdownTimer = ChaosManualTimer.new(KNOCKDOWN_COOLDOWN_MS)
    self.isUpPhase = false
    self.affectedZombies = {}

    ChaosUtils.EFFECT_EARTHQUAKE_ENABLED = true

    ChaosVehicle.ExitVehicle(getPlayer())
end

---@param deltaMs integer
function EffectEarthquake:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    lockFallPhysics(player)

    local isPhaseTick = false

    print("[EffectEarthquake] OnTick. Phase time #1: " .. self.phaseTimer.currentMs .. " / " .. self.phaseTimer.maxMs)
    self.phaseTimer:add(deltaMs)
    print("[EffectEarthquake] OnTick. Phase time #2: " .. self.phaseTimer.currentMs .. " / " .. self.phaseTimer.maxMs)
    if self.phaseTimer:isEnded() then
        self.phaseTimer:reset()
        self.phaseTimer:setMax(ChaosUtils.RandIntegerRange(PHASE_MIN_MS, PHASE_MAX_MS))
        print("[EffectEarthquake] OnTick. Phase time #3: " .. self.phaseTimer.currentMs .. " / " .. self.phaseTimer
            .maxMs)
        self.isUpPhase = not self.isUpPhase
        isPhaseTick = true
    end


    local multiplier = ChaosUtils.RandFloat(MULT_MIN, MULT_MAX) * (deltaMs / 1000)

    local angle = ChaosUtils.RandFloat(0, math.pi * 2)
    local dirX = math.cos(angle)
    local dirY = math.sin(angle)

    local vehicles = ChaosVehicle.GetVehiclesNearby(player:getSquare(), VEHICLE_RANGE)
    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            vehicle:setPhysicsActive(true)
            local upStrength = VEHICLE_UP_IMPULSE * multiplier
            if not self.isUpPhase then
                upStrength = upStrength * VEHICLE_DOWN_MULTIPLIER
            else
                upStrength = upStrength * VEHICLE_UP_MULTIPLIER
            end
            local xyStrength = VEHICLE_XY_IMPULSE * multiplier
            local impulse = Vector3f.new(dirX * xyStrength, upStrength, dirY * xyStrength)
            local relPos = Vector3f.new(0, 0, 0)
            vehicle:addImpulse(impulse, relPos)
        end
    end

    shakeCharacter(player, self.isUpPhase, multiplier, dirX, dirY)

    self.knockdownTimer:add(deltaMs)
    if self.knockdownTimer:isEnded() and not player:getVehicle() then
        player:setKnockedDown(true)
        self.knockdownTimer:reset()
    end

    local px, py = player:getX(), player:getY()
    local isUp = self.isUpPhase
    local affectedZombies = self.affectedZombies
    ChaosZombie.ForEachZombieInRange(px, py, CHARACTER_RANGE, function(zombie)
        if affectedZombies[zombie] == nil then
            affectedZombies[zombie] = zombie:isUseless()
            zombie:setUseless(true)
        end
        shakeCharacter(zombie, isUp, multiplier, dirX, dirY)
        zombie:setKnockedDown(true)
    end, false, nil)
end

function EffectEarthquake:OnEnd()
    ChaosEffectBase:OnEnd()
    ChaosUtils.EFFECT_EARTHQUAKE_ENABLED = false

    local player = getPlayer()
    if player then
        unlockFallPhysics(player)
    end

    if self.affectedZombies then
        for zombie, wasUselessBefore in pairs(self.affectedZombies) do
            if zombie and zombie:isAlive() then
                zombie:setUseless(wasUselessBefore)
            end
        end
        self.affectedZombies = {}
    end
end
