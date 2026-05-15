---@class EffectUFOAbductsZombies : ChaosEffectBase
---@field abductedZombies table<IsoZombie, number>
---@field elapsedMs integer
---@field previousTime number?
---@field soundId integer | nil
---@field uiEmitter FMODSoundEmitter?
EffectUFOAbductsZombies = ChaosEffectBase:derive("EffectUFOAbductsZombies", "ufo_abducts_zombies")

local RANGE = 80
local TARGET_Z = 16
local LIFT_DURATION_MS = 7000

---@param cell IsoCell
---@param x integer
---@param y integer
---@param z integer
local function spawnRedLight(cell, x, y, z)
    local light = IsoLightSource.new(
        x,
        y,
        z,
        1.0, 0.1, 0.1,
        3,
        160
    )
    cell:addLamppost(light)
end

function EffectUFOAbductsZombies:OnStart()
    ChaosEffectBase:OnStart()
    self.abductedZombies = {}
    self.elapsedMs = 0

    local player = getPlayer()
    if not player then return end

    local cell = getCell()
    if not cell then return end

    local px, py = player:getX(), player:getY()

    ChaosZombie.ForEachZombieInRange(px, py, RANGE, function(zombie)
        if not zombie or not zombie:isAlive() then return end
        local zx = math.floor(zombie:getX())
        local zy = math.floor(zombie:getY())
        local zz = math.floor(zombie:getZ())

        spawnRedLight(cell, zx, zy, zz)

        zombie:setbClimbing(true)
        zombie:setbFalling(false)
        zombie:setFallTime(0)
        zombie:setLastFallSpeed(0)
        zombie:setLastZ(zombie:getZ())

        self.abductedZombies[zombie] = zombie:getZ()
    end, true)

    self.soundId = ChaosUtils.PlayUISound("chaos_ufo_1", true)
    ---@type SoundManager
    local soundManager = getSoundManager()
    if soundManager.getUIEmitter then
        self.uiEmitter = soundManager:getUIEmitter()
    end

    local gameTime = GameTime:getInstance()
    if gameTime then
        self.previousTime = gameTime:getTimeOfDay()
        gameTime:setTimeOfDay(22.0)
    end
end

---@param deltaMs integer
function EffectUFOAbductsZombies:OnTick(deltaMs)
    local cm = ClimateManager.getInstance()
    if cm then
        local globalLight = cm:getClimateColor(ClimateManager.COLOR_GLOBAL_LIGHT)
        if globalLight then
            globalLight:setEnableOverride(true)
            local colorInfo = ClimateColorInfo.new()
            colorInfo:setExterior(0.2, 0, 0.2, 1.0)
            colorInfo:setInterior(0.2, 0, 0.2, 1.0)
            globalLight:setOverride(colorInfo, 1.0)
        end
        ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_AMBIENT, true, 1.0)
    end

    self.elapsedMs = self.elapsedMs + deltaMs
    local t = self.elapsedMs / LIFT_DURATION_MS
    if t > 1 then t = 1 end

    for zombie, startZ in pairs(self.abductedZombies) do
        if zombie and zombie:isAlive() then
            local liftedZ = ChaosUtils.Lerp(startZ, TARGET_Z, t)
            zombie:setbFalling(false)
            zombie:setFallTime(0)
            zombie:setLastFallSpeed(0)
            zombie:setZ(liftedZ)
            zombie:setLastZ(liftedZ)
        end
    end

    local player = getPlayer()
    if player and self.uiEmitter and self.soundId then
        self.uiEmitter:setPos(player:getX(), player:getY(), player:getZ())
        if self.uiEmitter.setVolume then
            self.uiEmitter:setVolume(self.soundId, 0.5)
        end
        if self.uiEmitter.tick then
            self.uiEmitter:tick()
        end
    end
end

function EffectUFOAbductsZombies:OnEnd()
    ChaosEffectBase:OnEnd()

    for zombie, _ in pairs(self.abductedZombies) do
        if zombie then
            pcall(function()
                zombie:removeFromWorld()
                zombie:removeFromSquare()
            end)
        end
    end
    self.abductedZombies = {}

    if self.soundId and self.soundId > 0 then
        getSoundManager():stopUISound(self.soundId)
    end
    self.soundId = nil
    self.uiEmitter = nil

    local gameTime = GameTime:getInstance()
    if gameTime and self.previousTime then
        gameTime:setTimeOfDay(self.previousTime)
    end

    local cm = ClimateManager.getInstance()
    if cm then
        local globalLight = cm:getClimateColor(ClimateManager.COLOR_GLOBAL_LIGHT)
        if globalLight then
            globalLight:setEnableOverride(false)
        end
        ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_AMBIENT, false, 0.0)
    end
end
