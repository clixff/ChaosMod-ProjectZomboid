---@class EffectFindChestWithLoot : ChaosEffectBase
---@field lootboxWorldItem IsoWorldInventoryObject?
---@field lootboxSquareX integer?
---@field lootboxSquareY integer?
---@field lootboxSquareZ integer?
EffectFindChestWithLoot = ChaosEffectBase:derive("EffectFindChestWithLoot", "find_chest_with_loot")


local MIN_RADIUS = 8
local MAX_RADIUS = 20
local ITEM_COUNT = 3
local GIFTBOX_ITEM_ID = "Base.Present_ExtraLarge"


---@param x integer
---@param y integer
---@param z integer
---@return IsoGridSquare?
local function findRandomTargetSquare(x, y, z)
    ---@type table<integer, IsoGridSquare>
    local candidates = {}

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        candidates[#candidates + 1] = sq
    end, MIN_RADIUS, MAX_RADIUS, true, true, true, z, z)

    if #candidates == 0 then return nil end
    return candidates[ChaosUtils.RandArrayIndex(candidates)]
end

---@param baseZ integer
---@return table<integer, integer>
local function buildSearchZOrder(baseZ)
    local order = { baseZ, baseZ + 1, baseZ - 1, baseZ + 2, baseZ - 2, baseZ + 3 }
    local result = {}
    local seen = {}

    for i = 1, #order do
        local z = order[i]
        if z >= 0 and not seen[z] then
            seen[z] = true
            result[#result + 1] = z
        end
    end

    return result
end

---@param worldObj IsoWorldInventoryObject?
local function removeWorldItem(worldObj)
    if not worldObj then return end

    ChaosUtils.RemoveWorldObject(worldObj)
end

function EffectFindChestWithLoot:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectFindChestWithLoot] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local px = playerSquare:getX()
    local py = playerSquare:getY()
    local pz = playerSquare:getZ()

    local targetSquare = nil
    local zOrder = buildSearchZOrder(pz)
    for i = 1, #zOrder do
        targetSquare = findRandomTargetSquare(px, py, zOrder[i])
        if targetSquare then
            break
        end
    end

    if not targetSquare then
        print("[EffectFindChestWithLoot] Failed to find target square")
        return
    end

    ---@type IsoWorldInventoryObject
    local worldItem = targetSquare:AddWorldInventoryItem(GIFTBOX_ITEM_ID, 0.5, 0.5, 0.0)
    if not worldItem then
        print("[EffectFindChestWithLoot] Failed to spawn lootbox")
        return
    end

    ---@diagnostic disable-next-line:undefined-field
    local container = worldItem:getInventory()
    if not container then
        print("[EffectFindChestWithLoot] Failed to get container from lootbox")
        removeWorldItem(worldItem)
        return
    end

    for _ = 1, ITEM_COUNT do
        local itemId = GetRandomLootboxItem()
        if itemId then
            container:AddItem(itemId)
        end
    end

    self.lootboxWorldItem = worldItem
    self.lootboxSquareX = targetSquare:getX()
    self.lootboxSquareY = targetSquare:getY()
    self.lootboxSquareZ = targetSquare:getZ()

    print("[EffectFindChestWithLoot] Spawned lootbox at "
        .. tostring(self.lootboxSquareX) .. ","
        .. tostring(self.lootboxSquareY) .. ","
        .. tostring(self.lootboxSquareZ))
end

function EffectFindChestWithLoot:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.lootboxWorldItem then
        removeWorldItem(self.lootboxWorldItem)
        self.lootboxWorldItem = nil
        return
    end

    local x = self.lootboxSquareX
    local y = self.lootboxSquareY
    local z = self.lootboxSquareZ
    if x == nil or y == nil or z == nil then return end

    local square = getCell() and getCell():getGridSquare(x, y, z) or nil
    if not square then return end

    ChaosUtils.ForAllWorldObjectsOnSquare(square, function(worldObj)
        local item = worldObj:getItem()
        if item and item:getFullType() == GIFTBOX_ITEM_ID then
            removeWorldItem(worldObj)
            return true
        end
    end)
end
