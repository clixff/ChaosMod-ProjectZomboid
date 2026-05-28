---@class MeteorShowerFallingMeteor
---@field worldItem IsoWorldInventoryObject
---@field square IsoGridSquare
---@field currentZ number
---@field targetZ number
---@field delayMs number
---@field marker WorldMarkers.GridSquareMarker?

---@class EffectMeteorShower : ChaosEffectBase
---@field spawnCooldown ChaosManualTimer
---@field activeMeteors MeteorShowerFallingMeteor[]
---@field impactedSquares IsoGridSquare[]
---@field playerDamageCooldownMs number remaining cooldown before a meteor can damage the player again
EffectMeteorShower = ChaosEffectBase:derive("EffectMeteorShower", "meteor_shower")

local SPAWN_COOLDOWN_MS = 400
local METEORS_PER_BURST = 1
local SPAWN_DELAY_MIN_MS = 250
local SPAWN_DELAY_MAX_MS = 1300
local SPAWN_RADIUS_MIN = 0
local SPAWN_RADIUS_MAX = 10
local FALL_START_Z_OFFSET = 15.0
local SPEED_Z = 10.0
local EXPLOSION_RADIUS = 2
local METEOR_ITEM_ID = "Base.LargeMeteorite"
local MARKER_LEAD_SECONDS = 1.0
local MARKER_SCALE = 2.5
local PLAYER_DAMAGE_COOLDOWN_MS = 1500

---@param worldItem IsoWorldInventoryObject
---@param visualZ number absolute world Z (square Z + offset)
---@param sync boolean? true to sync/save the offset
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
local function pickImpactSquare(player)
    local px = player:getX()
    local py = player:getY()

    for _ = 1, 20 do
        local angle = ChaosUtils.RandFloat(0.0, math.pi * 2.0)
        local distance = ChaosUtils.RandFloat(SPAWN_RADIUS_MIN, SPAWN_RADIUS_MAX)
        local x = math.floor(px + math.cos(angle) * distance)
        local y = math.floor(py + math.sin(angle) * distance)

        local square = ChaosUtils.FindHighestZSquare(x, y, false)
        if square then
            return square
        end
    end

    return nil
end

---@param self EffectMeteorShower
local function spawnMeteor(self)
    local player = getPlayer()
    if not player then return end

    local square = pickImpactSquare(player)
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
    local startZ = math.min(targetZ + FALL_START_Z_OFFSET, 31)
    setWorldItemVisualZ(worldItem, startZ, true)



    table.insert(self.activeMeteors, {
        worldItem = worldItem,
        square = square,
        currentZ = startZ,
        targetZ = targetZ,
        delayMs = ChaosUtils.RandIntegerRange(SPAWN_DELAY_MIN_MS, SPAWN_DELAY_MAX_MS + 1),
    })
end

---@param self EffectMeteorShower
---@param meteor MeteorShowerFallingMeteor
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

    -- square:playSound("chaos_electric_sound")


    ---@type string[]
    local sounds = {
        "thump3",
        "thump4",
        "thump5",
        "thump6"
    }

    ---@type string?
    local sound = sounds[ChaosUtils.RandArrayIndex(sounds)]

    if sound then
        local soundId = getSoundManager():PlayWorldSoundWav(sound, square, 1.0, 20.0, 1.0, true)

        if soundId then
            local settingsVolume = getCore():getRealOptionSoundVolume()
            soundId:setVolume(settingsVolume)
        end
        -- local emitter = getWorld():getFreeEmitter(square:getX() + 0.5, square:getY() + 0.5, square:getZ())
        -- if emitter then
        --     emitter:playSound(sound)
        -- end
        -- square:playSound(sound)
    end


    table.insert(self.impactedSquares, square)

    -- Check whether the player is within blast radius (same Z + 2D distance) before exploding.
    local player = getPlayer()
    local playerInRadius = false
    if player and math.floor(player:getZ()) == math.floor(square:getZ()) then
        playerInRadius = ChaosUtils.isInRange(square:getX(), square:getY(), player:getX(), player:getY(),
            EXPLOSION_RADIUS)
    end

    -- While the player-damage cooldown is active, suppress explosions that would catch the player.
    if playerInRadius and self.playerDamageCooldownMs > 0 then
        return
    end

    ChaosUtils.TriggerExplosionAt(square, EXPLOSION_RADIUS, true, true)

    if playerInRadius then
        self.playerDamageCooldownMs = PLAYER_DAMAGE_COOLDOWN_MS
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

---@param self EffectMeteorShower
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

function EffectMeteorShower:OnStart()
    ChaosEffectBase:OnStart()

    self.spawnCooldown = ChaosManualTimer.new(SPAWN_COOLDOWN_MS)
    self.activeMeteors = {}
    self.impactedSquares = {}
    self.playerDamageCooldownMs = 0
end

---@param deltaMs integer
function EffectMeteorShower:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    if self.playerDamageCooldownMs > 0 then
        self.playerDamageCooldownMs = self.playerDamageCooldownMs - deltaMs
    end

    self.spawnCooldown:add(deltaMs)
    if self.spawnCooldown:isEnded() then
        self.spawnCooldown:reset()
        for _ = 1, METEORS_PER_BURST do
            spawnMeteor(self)
        end
    end

    local fallStep = SPEED_Z * (deltaMs / 1000.0)
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
                if not meteor.marker and (meteor.currentZ - meteor.targetZ) <= SPEED_Z * MARKER_LEAD_SECONDS then
                    local markers = getWorldMarkers()
                    if markers then
                        meteor.marker = markers:addGridSquareMarker(meteor.square, 1.0, 0.2, 0.2, true, MARKER_SCALE)
                    end
                end

                meteor.worldItem:setHighlighted(0, true, false)
                meteor.worldItem:setOutlineHighlightCol(0, 1.0, 0.5, 0.0, 1.0)

                setWorldItemVisualZ(meteor.worldItem, meteor.currentZ, false)
            end
        end
    end
end

function EffectMeteorShower:OnEnd()
    ChaosEffectBase:OnEnd()

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
