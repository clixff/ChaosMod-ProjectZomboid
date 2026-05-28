---@class EffectRandomZombiesAreSprinters : ChaosEffectBase
---@field startTimer ChaosManualTimer
---@field affectedZombies table<IsoZombie, integer>
---@field hasApplied boolean
EffectRandomZombiesAreSprinters = ChaosEffectBase:derive("EffectRandomZombiesAreSprinters",
    "random_zombies_are_sprinters")

local RADIUS = 80
local START_DELAY_MS = 5000
local SPRINTER_CHANCE_PERCENT = 10.0

local SPEED_SPRINTER = 1
local SPEED_FAST_SHAMBLER = 2
local SPEED_SHAMBLER = 3

---@param zombie IsoZombie
---@return integer
local function getZombieSpeedLevelFromWalkType(zombie)
    local walkType = zombie:getWalkType()

    if walkType and string.sub(walkType, 1, 6) == "sprint" then
        return SPEED_SPRINTER
    end

    if walkType and string.sub(walkType, 1, 4) == "slow" then
        return SPEED_SHAMBLER
    end

    return SPEED_FAST_SHAMBLER
end

function EffectRandomZombiesAreSprinters:OnStart()
    ChaosEffectBase:OnStart()
    self.startTimer = ChaosManualTimer.new(START_DELAY_MS)
    self.affectedZombies = {}
    self.hasApplied = false
end

function EffectRandomZombiesAreSprinters:ApplySprinters()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()

    ChaosZombie.ForEachZombieInRange(px, py, RADIUS, function(zombie)
        if not zombie or zombie:isDead() then return end
        if self.affectedZombies[zombie] ~= nil then return end

        if ChaosUtils.RandFloat(0, 100) <= SPRINTER_CHANCE_PERCENT then
            self.affectedZombies[zombie] = getZombieSpeedLevelFromWalkType(zombie)
            zombie:doZombieSpeed(SPEED_SPRINTER)
        end
    end, true, nil)
end

---@param deltaMs integer
function EffectRandomZombiesAreSprinters:OnTick(deltaMs)
    if self.hasApplied then return end

    self.startTimer:add(deltaMs)
    if self.startTimer:isEnded() then
        self.hasApplied = true
        self:ApplySprinters()
    end
end

function EffectRandomZombiesAreSprinters:OnEnd()
    ChaosEffectBase:OnEnd()

    for zombie, previousSpeed in pairs(self.affectedZombies) do
        if zombie and zombie:isAlive() then
            zombie:doZombieSpeed(previousSpeed)
        end
    end
    self.affectedZombies = {}
end
