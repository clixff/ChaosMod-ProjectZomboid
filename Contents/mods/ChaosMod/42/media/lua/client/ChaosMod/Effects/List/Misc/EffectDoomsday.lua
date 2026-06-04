---@class DoomsdayFallingMeteor
---@field worldItem IsoWorldInventoryObject
---@field square IsoGridSquare
---@field currentZ number
---@field targetZ number
---@field delayMs number
---@field marker WorldMarkers.GridSquareMarker?

---@class EffectDoomsday : ChaosEffectBase
---@field previousPrecipitationIsSnow boolean
---@field flyingCarsTimer ChaosManualTimer
---@field flyingCarsBackward boolean
---@field thunderCooldown ChaosManualTimer
---@field thunderSoundTimer ChaosManualTimer
---@field thunderSoundAllowed boolean
---@field zombieBurnTimer ChaosManualTimer
---@field meteorSpawnTimer ChaosManualTimer
---@field activeMeteors DoomsdayFallingMeteor[]
---@field impactedSquares IsoGridSquare[]
---@field globalCooldownMs number suppresses new meteors and lightning after fire lands near player or a meteor damages the player
---@field alarmTimer ChaosManualTimer
---@field carAlarmTimer ChaosManualTimer
EffectDoomsday = ChaosEffectBase:derive("EffectDoomsday", "doomsday")

-- Flying-cars physics
local FLYING_CARS_TIMEOUT_MS = 5000
local FLYING_CARS_RANGE = 40
local FLYING_CARS_STRENGTH = 200000.0 * 5

-- Lightning strikes
local STRIKE_RADIUS_MIN = 3.0
local STRIKE_RADIUS = 5
local THUNDER_COOLDOWN_MS = 3500
local THUNDER_SOUND_INTERVAL_MS = 4000

-- Zombie ignite
local ZOMBIE_BURN_INTERVAL_MS = 5000
local ZOMBIE_BURN_RADIUS = 30

-- Meteors
local METEOR_SPAWN_COOLDOWN_MS = 1000
local METEORS_PER_BURST = 1
local METEOR_SPAWN_DELAY_MIN_MS = 250
local METEOR_SPAWN_DELAY_MAX_MS = 1300
local METEOR_SPAWN_RADIUS_MIN = 3.0
local METEOR_SPAWN_RADIUS_MAX = 10
local METEOR_FALL_START_Z_OFFSET = 15.0
local METEOR_SPEED_Z = 8.0
local METEOR_EXPLOSION_RADIUS = 2
local METEOR_ITEM_ID = "Base.LargeMeteorite"
local METEOR_MARKER_LEAD_SECONDS = 1.0
local METEOR_MARKER_SCALE = 2 * math.sqrt(2)

-- Global cooldown shared by meteors and lightning strikes
local GLOBAL_COOLDOWN_MS = 15000
local LIGHTNING_NEAR_PLAYER_DIST = 2

-- Alarms
local ALARM_INTERVAL_MS = 5000
local ALARM_MAX_RADIUS = 80
local CAR_ALARM_INTERVAL_MS = 8000
local CAR_ALARM_RADIUS = 60

-- Lights
local LIGHTS_RADIUS = 90

---@param x number
---@param y number
---@return IsoGridSquare | nil
local function pickStrikeTile(x, y)
    local angle = ChaosUtils.RandFloat(0.0, math.pi * 2.0)
    local distance = ChaosUtils.RandFloat(STRIKE_RADIUS_MIN, STRIKE_RADIUS)
    local tx = math.floor(x + math.cos(angle) * distance)
    local ty = math.floor(y + math.sin(angle) * distance)
    return ChaosUtils.FindHighestZSquare(tx, ty, false)
end

---@param worldItem IsoWorldInventoryObject
---@param visualZ number
---@param sync boolean?
local function setWorldItemVisualZ(worldItem, visualZ, sync)
    if not worldItem then return end
    local square = worldItem:getSquare()
    if not square then return end
    local zoff = visualZ - square:getZ()
    if sync then
        worldItem:setOffset(worldItem:getOffX(), worldItem:getOffY(), zoff)
    else
        worldItem:setOffZ(zoff)
        worldItem:invalidateRenderChunkLevel(256)
    end
end

---@param player IsoPlayer
---@return IsoGridSquare | nil
local function pickMeteorImpactSquare(player)
    local px = player:getX()
    local py = player:getY()
    for _ = 1, 20 do
        local angle = ChaosUtils.RandFloat(0.0, math.pi * 2.0)
        local distance = ChaosUtils.RandFloat(METEOR_SPAWN_RADIUS_MIN, METEOR_SPAWN_RADIUS_MAX)
        local x = math.floor(px + math.cos(angle) * distance)
        local y = math.floor(py + math.sin(angle) * distance)
        local square = ChaosUtils.FindHighestZSquare(x, y, false)
        if square then
            return square
        end
    end
    return nil
end

---@param self EffectDoomsday
local function spawnMeteor(self)
    local player = getPlayer()
    if not player then return end
    local square = pickMeteorImpactSquare(player)
    if not square then return end

    ---@type InventoryItem
    ---@diagnostic disable-next-line: assign-type-mismatch
    local item = instanceItem(METEOR_ITEM_ID)
    if not item then return end

    ---@diagnostic disable-next-line: param-type-mismatch
    local added = square:AddWorldInventoryItem(item, 0.5, 0.5, 0.0)
    if not added then return end

    local worldItem = item:getWorldItem()
    if not worldItem then return end

    local targetZ = square:getZ()
    local startZ = math.min(targetZ + METEOR_FALL_START_Z_OFFSET, 31)
    setWorldItemVisualZ(worldItem, startZ, true)

    table.insert(self.activeMeteors, {
        worldItem = worldItem,
        square = square,
        currentZ = startZ,
        targetZ = targetZ,
        delayMs = ChaosUtils.RandIntegerRange(METEOR_SPAWN_DELAY_MIN_MS, METEOR_SPAWN_DELAY_MAX_MS + 1),
    })
end

---@param self EffectDoomsday
---@param meteor DoomsdayFallingMeteor
local function impactMeteor(self, meteor)
    local worldItem = meteor.worldItem
    local square = meteor.square
    if not worldItem or not square then return end

    if meteor.marker then
        meteor.marker:remove()
        meteor.marker = nil
    end

    square:addAshes()

    pcall(function()
        worldItem:setHighlighted(0, false, false)
        worldItem:setOutlineHighlight(0, false)
        square:transmitRemoveItemFromSquare(worldItem)
        worldItem:removeFromSquare()
        worldItem:removeFromWorld()
    end)

    ---@type string[]
    local sounds = { "thump3", "thump4", "thump5", "thump6" }
    local sound = sounds[ChaosUtils.RandArrayIndex(sounds)]
    if sound then
        local soundId = getSoundManager():PlayWorldSoundWav(sound, square, 1.0, 20.0, 1.0, true)
        if soundId then
            local settingsVolume = getCore():getRealOptionSoundVolume()
            soundId:setVolume(settingsVolume)
        end
    end

    table.insert(self.impactedSquares, square)

    local player = getPlayer()
    local playerInRadius = false
    if player and math.floor(player:getZ()) == math.floor(square:getZ()) then
        playerInRadius = ChaosUtils.isInRange(square:getX(), square:getY(), player:getX(), player:getY(),
            METEOR_EXPLOSION_RADIUS)
    end

    if playerInRadius and self.globalCooldownMs > 0 then
        return
    end

    ChaosUtils.TriggerExplosionAt(square, METEOR_EXPLOSION_RADIUS, true, true)

    if playerInRadius then
        self.globalCooldownMs = GLOBAL_COOLDOWN_MS
    end
end

---@param square IsoGridSquare
---@return boolean
local function removeAddedAshes(square)
    if not square then return false end
    local objs = square:getObjects()
    for i = objs:size() - 1, 0, -1 do
        local obj = objs:get(i)
        local spriteName = obj:getSpriteName()
        if not spriteName and obj:getSprite() then
            spriteName = obj:getSprite():getName()
        end
        if spriteName == "floors_burnt_01_1" or spriteName == "floors_burnt_01_2" then
            square:transmitRemoveItemFromSquare(obj)
            return true
        end
    end
    return false
end

---@param self EffectDoomsday
local function clearAllMeteors(self)
    for _, meteor in ipairs(self.activeMeteors) do
        local worldItem = meteor.worldItem
        local square = meteor.square
        if meteor.marker then
            meteor.marker:remove()
            meteor.marker = nil
        end
        if worldItem and square then
            pcall(function()
                square:transmitRemoveItemFromSquare(worldItem)
                worldItem:removeFromSquare()
                worldItem:removeFromWorld()
            end)
        end
    end
    self.activeMeteors = {}
end

---@param square IsoGridSquare
---@return IsoLightSwitch | nil
local function getLightSwitchOnSquare(square)
    if not square then return nil end
    ---@type IsoLightSwitch | nil
    local lightSwitch = nil
    ChaosUtils.ForAllObjectsInSquare(square, function(obj)
        if instanceof(obj, "IsoLightSwitch") then
            lightSwitch = obj
            return true
        end
    end)
    return lightSwitch
end

---@param player IsoPlayer
local function disableLightsNearby(player)
    local sq = player:getSquare()
    if not sq then return end
    local px, py, pz = sq:getX(), sq:getY(), sq:getZ()
    ChaosUtils.SquareRingSearchTile_2D(px, py, function(s)
        if s then
            local lightSwitch = getLightSwitchOnSquare(s)
            if lightSwitch and lightSwitch:isActivated() then
                lightSwitch:setActive(false)
            end
        end
    end, 0, LIGHTS_RADIUS, false, false, true, pz - 1, pz + 2)
end

---@param player IsoPlayer
local function triggerAlarmNearby(player)
    local playerSq = player:getSquare()
    if not playerSq then return end
    local px = playerSq:getX()
    local py = playerSq:getY()

    local roomDef = nil
    local building = nil

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if sq then
            local rd = sq:getRoomDef()
            if rd then
                local b = rd:getBuilding()
                if b then
                    roomDef = rd
                    building = b
                    return true
                end
            end
        end
    end, 0, ALARM_MAX_RADIUS, false, false, true, 0, 0)

    if not roomDef or not building then return end

    building:setAlarmed(true)
    getAmbientStreamManager():doAlarm(roomDef)
end

---@param player IsoPlayer
local function triggerCarAlarmsNearby(player)
    local sq = player:getSquare()
    if not sq then return end
    local vehicles = ChaosVehicle.GetVehiclesNearby(sq, CAR_ALARM_RADIUS)
    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            vehicle:setAlarmed(true)
            vehicle:triggerAlarm()
        end
    end
end

---@param self EffectDoomsday
---@param player IsoPlayer
local function tickFlyingCars(self, player, deltaMs)
    self.flyingCarsTimer:add(deltaMs)
    local activate = false
    if self.flyingCarsTimer:isEnded() then
        self.flyingCarsTimer:reset()
        activate = true
        self.flyingCarsBackward = not self.flyingCarsBackward
    end

    if activate then
        local veh = ChaosVehicle.spawnVehicleNearPlayer(ChaosVehicle.GetRandomVehicleName(), 10, 50, false, false)
        if veh then
            ChaosVehicle.SetRandomVehicleColors(veh)
        end
    end

    local playerVehicle = player:getVehicle()
    local vehicles = ChaosVehicle.GetVehiclesNearby(player:getSquare(), FLYING_CARS_RANGE)
    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            vehicle:setPhysicsActive(true)
            local forward = Vector3f.new(0, 0, 0)
            vehicle:getForwardVector(forward)

            local strength = FLYING_CARS_STRENGTH
            if self.flyingCarsBackward then
                strength = strength * -1
            end
            if vehicle == playerVehicle then
                strength = strength * 0.5
            end

            local impulse = Vector3f.new(forward:x() * strength, forward:y() * strength, forward:z() * strength)
            local relPos = Vector3f.new(0, 0, 0)
            vehicle:addImpulse(impulse, relPos)
        end
    end
end

---@param self EffectDoomsday
---@param player IsoPlayer
---@param deltaMs integer
local function tickLightning(self, player, deltaMs)
    self.thunderSoundTimer:add(deltaMs)
    if self.thunderSoundTimer:isEnded() then
        self.thunderSoundTimer:reset()
        self.thunderSoundAllowed = true
    end

    self.thunderCooldown:add(deltaMs)
    if not self.thunderCooldown:isEnded() then return end
    self.thunderCooldown:reset()

    if self.globalCooldownMs > 0 then return end

    local sq = pickStrikeTile(player:getX(), player:getY())
    if not sq then return end

    ChaosUtils.SpawnLightningStrikeAt(sq:getX(), sq:getY(), sq:getZ(),
        self.thunderSoundAllowed, true, true, false, true)

    if self.thunderSoundAllowed then
        self.thunderSoundAllowed = false
    end

    if ChaosUtils.isInRange(sq:getX(), sq:getY(), player:getX(), player:getY(), LIGHTNING_NEAR_PLAYER_DIST) then
        self.globalCooldownMs = GLOBAL_COOLDOWN_MS
    end
end

---@param self EffectDoomsday
---@param player IsoPlayer
---@param deltaMs integer
local function tickZombieBurn(self, player, deltaMs)
    self.zombieBurnTimer:add(deltaMs)
    if not self.zombieBurnTimer:isEnded() then return end
    self.zombieBurnTimer:reset()

    local px, py = player:getX(), player:getY()
    ChaosZombie.ForEachZombieInRange(px, py, ZOMBIE_BURN_RADIUS, function(zombie)
        if zombie and zombie:isAlive() then
            zombie:setOnFire(true)
        end
    end, false, nil)
end

---@param self EffectDoomsday
---@param deltaMs integer
local function tickMeteors(self, deltaMs)
    self.meteorSpawnTimer:add(deltaMs)
    if self.meteorSpawnTimer:isEnded() then
        self.meteorSpawnTimer:reset()
        if self.globalCooldownMs <= 0 then
            for _ = 1, METEORS_PER_BURST do
                spawnMeteor(self)
            end
        end
    end

    local fallStep = METEOR_SPEED_Z * (deltaMs / 1000.0)
    for i = #self.activeMeteors, 1, -1 do
        local meteor = self.activeMeteors[i]
        if meteor.delayMs > 0 then
            meteor.delayMs = meteor.delayMs - deltaMs
        else
            meteor.currentZ = meteor.currentZ - fallStep
            if meteor.currentZ <= meteor.targetZ then
                impactMeteor(self, meteor)
                table.remove(self.activeMeteors, i)
            else
                if not meteor.marker
                    and (meteor.currentZ - meteor.targetZ) <= METEOR_SPEED_Z * METEOR_MARKER_LEAD_SECONDS then
                    local markers = getWorldMarkers()
                    if markers then
                        meteor.marker = markers:addGridSquareMarker(meteor.square, 1.0, 0.2, 0.2, true,
                            METEOR_MARKER_SCALE)
                    end
                end
                meteor.worldItem:setHighlighted(0, true, false)
                meteor.worldItem:setOutlineHighlightCol(0, 1.0, 0.5, 0.0, 1.0)
                setWorldItemVisualZ(meteor.worldItem, meteor.currentZ, false)
            end
        end
    end
end

function EffectDoomsday:OnStart()
    ChaosEffectBase:OnStart()

    ChaosUtils.EFFECT_DOOMSDAY_ENABLED = true

    ChaosUtils.SetWorldTime(23, 0)

    local cm = ClimateManager.getInstance()
    if cm then
        self.previousPrecipitationIsSnow = cm:getPrecipitationIsSnow()
        cm:setPrecipitationIsSnow(false)
        ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 1.0)
    end

    local player = getPlayer()
    if player then
        ChaosVehicle.ExitVehicle(player)
        disableLightsNearby(player)
    end

    self.flyingCarsTimer = ChaosManualTimer.new(FLYING_CARS_TIMEOUT_MS)
    self.flyingCarsBackward = false

    self.thunderCooldown = ChaosManualTimer.new(THUNDER_COOLDOWN_MS)
    self.thunderSoundTimer = ChaosManualTimer.new(THUNDER_SOUND_INTERVAL_MS)
    self.thunderSoundTimer.currentMs = self.thunderSoundTimer.maxMs
    self.thunderSoundAllowed = false

    self.zombieBurnTimer = ChaosManualTimer.new(ZOMBIE_BURN_INTERVAL_MS)

    self.meteorSpawnTimer = ChaosManualTimer.new(METEOR_SPAWN_COOLDOWN_MS)
    self.activeMeteors = {}
    self.impactedSquares = {}
    self.globalCooldownMs = 0

    self.alarmTimer = ChaosManualTimer.new(ALARM_INTERVAL_MS)
    self.carAlarmTimer = ChaosManualTimer.new(CAR_ALARM_INTERVAL_MS)
end

---@param deltaMs integer
function EffectDoomsday:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local cm = ClimateManager.getInstance()
    if cm then
        ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, true, 1.0)
    end

    local player = getPlayer()
    if not player then return end

    if self.globalCooldownMs > 0 then
        self.globalCooldownMs = math.max(0, self.globalCooldownMs - deltaMs)
        local bar = UIManager.getProgressBar(0)
        if bar then
            local progress = 1.0 - (self.globalCooldownMs / GLOBAL_COOLDOWN_MS)
            bar:setValue(progress)
        end
    end

    tickFlyingCars(self, player, deltaMs)
    tickLightning(self, player, deltaMs)
    tickZombieBurn(self, player, deltaMs)
    tickMeteors(self, deltaMs)

    self.alarmTimer:add(deltaMs)
    if self.alarmTimer:isEnded() then
        self.alarmTimer:reset()
        triggerAlarmNearby(player)
    end

    self.carAlarmTimer:add(deltaMs)
    if self.carAlarmTimer:isEnded() then
        self.carAlarmTimer:reset()
        triggerCarAlarmsNearby(player)
    end
end

function EffectDoomsday:OnEnd()
    ChaosEffectBase:OnEnd()

    ChaosUtils.EFFECT_DOOMSDAY_ENABLED = false

    local bar = UIManager.getProgressBar(0)
    if bar then
        bar:setValue(0)
    end

    local cm = ClimateManager.getInstance()
    if cm then
        cm:setPrecipitationIsSnow(self.previousPrecipitationIsSnow or false)
        ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_PRECIPITATION_INTENSITY, false, 0.0)
        cm:stopWeatherAndThunder()
    end

    if self.activeMeteors then
        clearAllMeteors(self)
    end

    if self.impactedSquares then
        for _, square in ipairs(self.impactedSquares) do
            removeAddedAshes(square)
        end
        self.impactedSquares = {}
    end
end
