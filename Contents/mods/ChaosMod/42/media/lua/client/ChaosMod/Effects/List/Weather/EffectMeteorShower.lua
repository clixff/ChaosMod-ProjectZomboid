---@class MeteorShowerFallingMeteor
---@field worldItem IsoWorldInventoryObject
---@field square IsoGridSquare
---@field currentZ number
---@field targetZ number

---@class EffectMeteorShower : ChaosEffectBase
---@field spawnCooldown ChaosManualTimer
---@field activeMeteors MeteorShowerFallingMeteor[]
EffectMeteorShower = ChaosEffectBase:derive("EffectMeteorShower", "meteor_shower")

local SPAWN_COOLDOWN_MS = 1500
local METEORS_PER_BURST = 2
local SPAWN_RADIUS_MIN = 4
local SPAWN_RADIUS_MAX = 22
local FALL_START_Z_OFFSET = 12.0
local SPEED_Z = 0.020
local EXPLOSION_RADIUS = 2
local METEOR_ITEM_ID = "Base.LargeMeteorite"

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
    local startZ = targetZ + FALL_START_Z_OFFSET
    setWorldItemVisualZ(worldItem, startZ, true)

    table.insert(self.activeMeteors, {
        worldItem = worldItem,
        square = square,
        currentZ = startZ,
        targetZ = targetZ,
    })
end

---@param meteor MeteorShowerFallingMeteor
local function impactMeteor(meteor)
    local worldItem = meteor.worldItem
    local square = meteor.square
    if not worldItem or not square then return end

    pcall(function()
        square:transmitRemoveItemFromSquare(worldItem)
        worldItem:removeFromSquare()
        worldItem:removeFromWorld()
    end)

    ChaosUtils.TriggerExplosionAt(square, EXPLOSION_RADIUS)
end

---@param self EffectMeteorShower
local function clearAllMeteors(self)
    for _, meteor in ipairs(self.activeMeteors) do
        local worldItem = meteor.worldItem
        local square = meteor.square
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
end

---@param deltaMs integer
function EffectMeteorShower:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    self.spawnCooldown:add(deltaMs)
    if self.spawnCooldown:isEnded() then
        self.spawnCooldown:reset()
        for _ = 1, METEORS_PER_BURST do
            spawnMeteor(self)
        end
    end

    local fallStep = SPEED_Z * deltaMs
    for i = #self.activeMeteors, 1, -1 do
        local meteor = self.activeMeteors[i]
        meteor.currentZ = meteor.currentZ - fallStep
        if meteor.currentZ <= meteor.targetZ then
            impactMeteor(meteor)
            table.remove(self.activeMeteors, i)
        else
            setWorldItemVisualZ(meteor.worldItem, meteor.currentZ, false)
        end
    end
end

function EffectMeteorShower:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.activeMeteors then
        clearAllMeteors(self)
    end
end
