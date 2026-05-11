---@class EffectUFOAbduction : ChaosEffectBase
---@field elapsedMs integer
---@field startZ number
---@field liftStarted boolean
---@field phase2Started boolean
---@field previousTime number?
---@field hud ChaosUFOAbductionHUD?
---@field soundId integer | nil
---@field uiEmitter FMODSoundEmitter?
---@field targetSquare IsoGridSquare?
---@field secondSoundPlayed boolean
EffectUFOAbduction = ChaosEffectBase:derive("EffectUFOAbduction", "ufo_abduction")

local PHASE_1_DELAY_MS = 500
local PHASE_2_DELAY_MS = 0
local LIFT_DURATION_MS = 7000
local TARGET_Z = 31

---@param cell IsoCell
---@param x integer
---@param y integer
---@param z integer
local function spawnRedLightAtPlayer(cell, x, y, z)
    local light = IsoLightSource.new(
        x,
        y,
        z,
        1.0, 0.1, 0.1,
        60,
        30
    )
    local result = cell:addLamppost(light)
    print("[EffectUFOAbduction] addLamppost result: " .. tostring(result))
end

---@param item InventoryItem
local function removeClothingItem(item)
    if not item then return end
    if not item:IsClothing() then return end
    if item:IsInventoryContainer() then return end
    item:Remove()
end

---@param player IsoPlayer
---@param square IsoGridSquare
local function teleportPlayerToSquare(player, square)
    ChaosPlayer.TeleportPlayer(player, square)
    player:setbClimbing(false)
    player:setbFalling(false)
    player:setFallTime(0)
    player:setLastFallSpeed(0)
    player:setLastZ(player:getZ())
    player:setCurrentSquareFromPosition()
end

---@param centerSquare IsoGridSquare
local function spawnDeadCowsAround(centerSquare)
    local cell = getCell()
    if not cell then return end

    local centerX = centerSquare:getX()
    local centerY = centerSquare:getY()
    local centerZ = centerSquare:getZ()
    local spawned = 0
    local attempts = 0
    while spawned < 3 and attempts < 40 do
        attempts = attempts + 1
        local dx = ChaosUtils.RandIntegerRange(-4, 5)
        local dy = ChaosUtils.RandIntegerRange(-4, 5)
        local sq = cell:getGridSquare(centerX + dx, centerY + dy, centerZ)
        if sq and not sq:isSolid() and sq:getFloor() then
            local cow = ChaosAnimals.SpawnAnimal(sq:getX(), sq:getY(), sq:getZ(), "cow", "holstein")
            if cow then
                cow:setHealth(0)
                spawned = spawned + 1
            end
        end
    end
end

function EffectUFOAbduction:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    ChaosVehicle.ExitVehicle(player)

    self.elapsedMs = 0
    self.liftStarted = false
    self.phase2Started = false
    self.secondSoundPlayed = false
    self.startZ = player:getZ()

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

    self.targetSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, 0, 60, 200, 80, true, false, false)
    if self.targetSquare then
        spawnDeadCowsAround(self.targetSquare)
    end
end

---@param deltaMs integer
function EffectUFOAbduction:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

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

    if not self.secondSoundPlayed and self.elapsedMs >= 5000 then
        self.secondSoundPlayed = true
        local emitter = player:getEmitter()
        self.soundId = ChaosUtils.PlayUISound("chaos_ufo_2", true)
    end

    if not self.phase2Started and self.elapsedMs >= PHASE_2_DELAY_MS then
        self.phase2Started = true
        self.hud = ChaosUFOAbductionHUD:new()
        self.hud:initialise()
        self.hud:addToUIManager()
        self.hud:setVisible(true)
    end

    local liftedZ = player:getZ()

    if self.elapsedMs >= PHASE_1_DELAY_MS then
        local liftElapsed = self.elapsedMs - PHASE_1_DELAY_MS

        if not self.liftStarted then
            self.liftStarted = true
            self.startZ = player:getZ()

            player:setbClimbing(true)
            player:setbFalling(false)
            player:setFallTime(0)
            player:setLastFallSpeed(0)
            player:setLastZ(player:getZ())

            spawnRedLightAtPlayer(player:getCell(), math.floor(player:getX()), math.floor(player:getY()),
                math.floor(player:getZ()))
        end

        if liftElapsed <= LIFT_DURATION_MS then
            local t = liftElapsed / LIFT_DURATION_MS
            if t > 1 then t = 1 end
            liftedZ = ChaosUtils.Lerp(self.startZ, TARGET_Z, t)
        else
            liftedZ = TARGET_Z
        end

        player:setZ(liftedZ)
        player:setTargetAlpha(0, 1.0)
    end

    if self.uiEmitter and self.soundId then
        self.uiEmitter:setPos(player:getX(), player:getY(), liftedZ)
        if self.uiEmitter.setVolume then
            self.uiEmitter:setVolume(self.soundId, 0.35)
        end
        if self.uiEmitter.tick then
            self.uiEmitter:tick()
        end
    end
end

function EffectUFOAbduction:OnEnd()
    ChaosEffectBase:OnEnd()

    local gameTime = GameTime:getInstance()
    if gameTime and self.previousTime then
        gameTime:setTimeOfDay(self.previousTime)
    end

    local player = getPlayer()
    if player then
        if self.targetSquare then
            teleportPlayerToSquare(player, self.targetSquare)
        end

        local inventory = player:getInventory()
        if inventory then
            ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, removeClothingItem)
            player:onWornItemsChanged()
            player:resetModelNextFrame()
            triggerEvent("OnClothingUpdated", player)
        end

        player:getBodyDamage():RestoreToFullHealth()
        ChaosPlayer.SayLineByColor(player, "Health was fully restored", ChaosPlayerChatColors.green)
    end

    if self.hud then
        self.hud:setVisible(false)
        self.hud:removeFromUIManager()
        self.hud = nil
    end

    if self.soundId and self.soundId > 0 then
        getSoundManager():stopUISound(self.soundId)
    end
    self.soundId = nil
    self.uiEmitter = nil

    local cm = ClimateManager.getInstance()
    if cm then
        local globalLight = cm:getClimateColor(ClimateManager.COLOR_GLOBAL_LIGHT)
        if globalLight then
            globalLight:setEnableOverride(false)
        end
        ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_AMBIENT, false, 0.0)
    end
end
