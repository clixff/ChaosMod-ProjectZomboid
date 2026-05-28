---@class ItemRainFallingItem
---@field worldItem IsoWorldInventoryObject
---@field square IsoGridSquare
---@field currentZ number
---@field targetZ number
---@field delayMs number

---@class EffectItemRain : ChaosEffectBase
---@field spawnCooldown ChaosManualTimer
---@field activeItems ItemRainFallingItem[]
EffectItemRain = ChaosEffectBase:derive("EffectItemRain", "item_rain")

local SPAWN_COOLDOWN_MS = 400
local ITEMS_PER_BURST = 1
local SPAWN_DELAY_MIN_MS = 250
local SPAWN_DELAY_MAX_MS = 1300
local SPAWN_RADIUS_MIN = 0
local SPAWN_RADIUS_MAX = 10
local FALL_START_Z_OFFSET = 15.0
local SPEED_Z = 10.0

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
    local pz = math.floor(player:getZ())
    local cell = getCell()
    if not cell then return nil end

    for _ = 1, 20 do
        local angle = ChaosUtils.RandFloat(0.0, math.pi * 2.0)
        local distance = ChaosUtils.RandFloat(SPAWN_RADIUS_MIN, SPAWN_RADIUS_MAX)
        local x = math.floor(px + math.cos(angle) * distance)
        local y = math.floor(py + math.sin(angle) * distance)

        local square = cell:getGridSquare(x, y, pz)
        if square then
            return square
        end
    end

    return nil
end

---@param self EffectItemRain
local function spawnFallingItem(self)
    local player = getPlayer()
    if not player then return end

    local square = pickImpactSquare(player)
    if not square then return end

    local itemId = ChaosItems.GetRandomItemId()
    if not itemId then return end

    ---@type InventoryItem
    ---@diagnostic disable-next-line: assign-type-mismatch
    local item = instanceItem(itemId)
    if not item then return end

    ---@diagnostic disable-next-line: param-type-mismatch
    local added = square:AddWorldInventoryItem(item, 0.5, 0.5, 0.0)
    if not added then return end

    local worldItem = item:getWorldItem()
    if not worldItem then return end

    local targetZ = square:getZ()
    local startZ = math.min(targetZ + FALL_START_Z_OFFSET, 31.0)
    setWorldItemVisualZ(worldItem, startZ, true)

    worldItem:setHighlighted(0, true, false)
    worldItem:setOutlineHighlightCol(0, 0.0, 1.0, 0.0, 1.0)

    table.insert(self.activeItems, {
        worldItem = worldItem,
        square = square,
        currentZ = startZ,
        targetZ = targetZ,
        delayMs = ChaosUtils.RandIntegerRange(SPAWN_DELAY_MIN_MS, SPAWN_DELAY_MAX_MS + 1),
    })
end

---@param fallingItem ItemRainFallingItem
local function landItem(fallingItem)
    local worldItem = fallingItem.worldItem
    if not worldItem then return end

    setWorldItemVisualZ(worldItem, fallingItem.targetZ, true)

    pcall(function()
        worldItem:setHighlighted(0, false, false)
        worldItem:setOutlineHighlight(0, false)
    end)
end

function EffectItemRain:OnStart()
    ChaosEffectBase:OnStart()

    self.spawnCooldown = ChaosManualTimer.new(SPAWN_COOLDOWN_MS)
    self.activeItems = {}
end

---@param deltaMs integer
function EffectItemRain:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    self.spawnCooldown:add(deltaMs)
    if self.spawnCooldown:isEnded() then
        self.spawnCooldown:reset()
        for _ = 1, ITEMS_PER_BURST do
            spawnFallingItem(self)
        end
    end

    local fallStep = SPEED_Z * (deltaMs / 1000.0)
    for i = #self.activeItems, 1, -1 do
        local fallingItem = self.activeItems[i]

        if fallingItem.delayMs > 0 then
            fallingItem.delayMs = fallingItem.delayMs - deltaMs
        else
            fallingItem.currentZ = fallingItem.currentZ - fallStep
            if fallingItem.currentZ <= fallingItem.targetZ then
                landItem(fallingItem)
                table.remove(self.activeItems, i)
            else
                setWorldItemVisualZ(fallingItem.worldItem, fallingItem.currentZ, false)
            end
        end
    end
end

function EffectItemRain:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.activeItems then
        for _, fallingItem in ipairs(self.activeItems) do
            landItem(fallingItem)
        end
        self.activeItems = {}
    end
end
