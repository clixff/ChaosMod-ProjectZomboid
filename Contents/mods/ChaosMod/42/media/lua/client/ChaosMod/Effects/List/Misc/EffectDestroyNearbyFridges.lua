EffectDestroyNearbyFridges = ChaosEffectBase:derive("EffectDestroyNearbyFridges", "destroy_nearby_fridges")

local RANGE = 40
local Z_RANGE = 3

---@param obj IsoObject
---@return boolean
local function isFridge(obj)
    local props = obj:getProperties()
    if props and props:has(IsoPropertyType.IS_FRIDGE) then
        return true
    end

    for c = 0, obj:getContainerCount() - 1 do
        local container = obj:getContainerByIndex(c)
        if container then
            local ctype = container:getType()
            if ctype == "fridge" or ctype == "freezer" then
                return true
            end
        end
    end

    return false
end

---@param fridge IsoObject
---@param sq IsoGridSquare
local function dumpItemsToFloor(fridge, sq)
    for c = 0, fridge:getContainerCount() - 1 do
        local container = fridge:getContainerByIndex(c)
        if container then
            local items = container:getItems()
            local snapshot = {}
            for i = 0, items:size() - 1 do
                table.insert(snapshot, items:get(i))
            end
            for _, item in ipairs(snapshot) do
                local ox = ZombRand(0.15, 0.85)
                local oy = ZombRand(0.15, 0.85)
                sq:AddWorldInventoryItem(item, ox, oy, 0.0)
            end
        end
    end
end

function EffectDestroyNearbyFridges:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectDestroyNearbyFridges] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local cell = getCell()
    local px, py, pz = square:getX(), square:getY(), square:getZ()
    local count = 0

    for dx = -RANGE, RANGE do
        for dy = -RANGE, RANGE do
            for dz = -Z_RANGE, Z_RANGE do
                local sq = cell:getGridSquare(px + dx, py + dy, pz + dz)
                if sq then
                    local objects = sq:getObjects()
                    ---@type table<integer, IsoObject>
                    local fridges = {}
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if isFridge(obj) then
                            table.insert(fridges, obj)
                        end
                    end
                    for _, fridge in ipairs(fridges) do
                        dumpItemsToFloor(fridge, sq)
                        fridge:removeFromWorld()
                        fridge:removeFromSquare()
                        count = count + 1
                    end
                end
            end
        end
    end

    print("[EffectDestroyNearbyFridges] Destroyed " .. tostring(count) .. " fridges")
    player:Say("Destroyed " .. tostring(count) .. " fridges")
end
