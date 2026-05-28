---@class EffectWrathOfTheGods : ChaosEffectBase
---@field previousPrecipitationIsSnow boolean
---@field thunderCooldown ChaosManualTimer
---@field thunderSoundTimer ChaosManualTimer
---@field soundAllowed boolean
EffectWrathOfTheGods = ChaosEffectBase:derive("EffectWrathOfTheGods", "wrath_of_the_gods")

local STRIKE_RADIUS = 5
local THUNDER_COOLDOWN_MS = 2000
local ZOMBIE_DAMAGE = 0.6
local MAX_Z_LEVEL = 7

---@param x integer
---@param y integer
---@return IsoGridSquare | nil
local function getTopSquareAt(x, y)
    local cell = getCell()
    if not cell then return nil end
    local top = nil
    for z = 0, MAX_Z_LEVEL do
        local sq = cell:getGridSquare(x, y, z)
        if sq then
            top = sq
        end
    end
    return top
end

---@param x integer
---@param y integer
---@param doSound boolean
local function handleThunderStrike(x, y, doSound)
    local sq = ChaosUtils.FindHighestZSquare(x, y, false)
    if not sq then return end

    local sqZ = sq:getZ()

    ChaosUtils.SpawnLightningStrikeAt(x, y, sqZ, doSound, true, true, true, true)
end

function EffectWrathOfTheGods:OnStart()
    ChaosEffectBase:OnStart()

    local cm = ClimateManager.getInstance()
    if cm then
        self.previousPrecipitationIsSnow = cm:getPrecipitationIsSnow()
        cm:setPrecipitationIsSnow(false)
        ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 1.0)
    end

    self.thunderCooldown = ChaosManualTimer.new(THUNDER_COOLDOWN_MS)
    self.thunderSoundTimer = ChaosManualTimer.new(4000)
    self.thunderSoundTimer.currentMs = self.thunderSoundTimer.maxMs
end

---@param deltaMs integer
function EffectWrathOfTheGods:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local cm = ClimateManager.getInstance()
    if cm then
        ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 1.0)
    end

    self.thunderSoundTimer:add(deltaMs)
    if self.thunderSoundTimer:isEnded() then
        self.thunderSoundTimer:reset()
        self.soundAllowed = true
    end

    self.thunderCooldown:add(deltaMs)
    if not self.thunderCooldown:isEnded() then return end
    self.thunderCooldown:reset()

    local player = getPlayer()
    if not player then return end

    local px = player:getX()
    local py = player:getY()

    local angle = ChaosUtils.RandFloat(0.0, math.pi * 2.0)
    local distance = math.sqrt(ChaosUtils.RandFloat(0.0, 1.0)) * STRIKE_RADIUS
    local tx = math.floor(px + math.cos(angle) * distance)
    local ty = math.floor(py + math.sin(angle) * distance)

    if cm then
        handleThunderStrike(tx, ty, self.soundAllowed)
        if self.soundAllowed then
            self.soundAllowed = false
        end
    end
end

function EffectWrathOfTheGods:OnEnd()
    ChaosEffectBase:OnEnd()

    local cm = ClimateManager.getInstance()
    if cm then
        cm:setPrecipitationIsSnow(self.previousPrecipitationIsSnow or false)
        ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, false, 0.0)
        cm:stopWeatherAndThunder()
    end
end
