---@class EffectInsanity : ChaosEffectBase
---@field soundId integer | nil
---@field spawnedZombies ArrayList<IsoZombie>
---@field uiEmitter FMODSoundEmitter?
EffectInsanity = ChaosEffectBase:derive("EffectInsanity", "effect_insanity")

local MAX_SPAWNED_ZOMBIES = 30
local MIN_SPAWN_DISTANCE = 15
local MAX_SPAWN_DISTANCE = 30
local MIN_DIST_TELEPORT = 4
local MAX_DIST_TELEPORT = 35

function EffectInsanity:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    -- self.soundId = player:playSound("insane2")
    self.soundId = ChaosUtils.PlayUISound("insane1", true)
    ---@type SoundManager
    local soundManager = getSoundManager()

    if soundManager.getUIEmitter then
        self.uiEmitter = soundManager:getUIEmitter()
        if self.uiEmitter and self.soundId then
            self.uiEmitter:setVolume(self.soundId, 0.15)
            print("[EffectInsanity] UI emitter changed volume ")
        end
    else
        print("[EffectInsanity] Failed to get UI emitter")
    end


    self.spawnedZombies = ArrayList.new()

    for i = 1, MAX_SPAWNED_ZOMBIES + 1 do
        local x, y, z = EffectInsanity.GetRandomLocationForZombie(player)
        if x ~= nil and y ~= nil and z ~= nil then
            local newZombies = ChaosZombie.SpawnZombieAt(x, y, z, 1, "Tourist")
            local zombie = newZombies:getFirst()
            if zombie then
                self.spawnedZombies:add(zombie)
                local md = zombie:getModData()
                if md then
                    md["EFFECT_INSANITY"] = true
                end
            end
        end
    end
end

function EffectInsanity:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    local cm = ClimateManager.getInstance()
    if not cm then return end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_DESATURATION, true, 1.0)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_DAYLIGHT_STRENGTH, true, 1.0)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_FOG_INTENSITY, true, 1.0)
    -- Rain
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 0.0)

    local allZombies = getCell():getZombieList()
    local x1, y1, z1 = player:getX(), player:getY(), player:getZ()
    if self.uiEmitter and self.soundId then
        self.uiEmitter:setPos(x1, y1, z1)
        if self.uiEmitter.setVolume then
            self.uiEmitter:setVolume(self.soundId, 0.1)
            self.uiEmitter:tick()
        end
    end

    for i = 0, allZombies:size() - 1 do
        local zombie = allZombies:get(i)
        if zombie and zombie:isAlive() and zombie:isSceneCulled() == false then
            local x2 = zombie:getX()
            local y2 = zombie:getY()
            local dist = ChaosUtils.distTo(x1, y1, x2, y2)

            local md = zombie:getModData()
            local isFakeZombie = md and md["EFFECT_INSANITY"] and true or false
            if isFakeZombie then
                EffectInsanity.FakeZombieTick(zombie, player)
                if dist < MIN_DIST_TELEPORT or dist > MAX_DIST_TELEPORT then
                    local x, y, z = EffectInsanity.GetRandomLocationForZombie(player)
                    if x ~= nil and y ~= nil and z ~= nil then
                        zombie:setX(x)
                        zombie:setY(y)
                        zombie:setZ(z)
                    end
                end
            else
                -- Hide distance zombies
                if dist > 10.0 then
                    zombie:setAlpha(0.0)
                end
            end
        end
    end
end

function EffectInsanity:OnEnd()
    ChaosEffectBase:OnEnd()
    local cm = ClimateManager.getInstance()
    if not cm then return end
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_DESATURATION, false, 0.0)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_DAYLIGHT_STRENGTH, false, 0.0)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_FOG_INTENSITY, false, 0.0)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, false, 0.0)

    if self.soundId and self.soundId > 0 then
        getSoundManager():stopUISound(self.soundId)
    end

    for i = 0, self.spawnedZombies:size() - 1 do
        local zombie = self.spawnedZombies:get(i)
        if zombie then
            zombie:removeFromWorld()
        end
    end
    self.spawnedZombies:clear()
end

---@param player IsoPlayer
function EffectInsanity.GetRandomLocationForZombie(player)
    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, 0, MIN_SPAWN_DISTANCE, MAX_SPAWN_DISTANCE, 50,
        true, true, false)

    if not randomSquare then return end

    local x = randomSquare:getX()
    local y = randomSquare:getY()
    local z = randomSquare:getZ()

    return x, y, z
end

---@param zombie IsoZombie
---@param player IsoPlayer
function EffectInsanity.FakeZombieTick(zombie, player)
    if not zombie then return end
    if not player then return end

    zombie:faceThisObject(player)
    -- zombie:setBumpType("ZombieTPose")
    zombie:setUseless(true)
    zombie:setNoTeeth(true)
    zombie:clearAggroList()
    ---@diagnostic disable-next-line: param-type-mismatch
    zombie:setTarget(nil)
    zombie:pathToLocationF(player:getX(), player:getY(), player:getZ())
end
