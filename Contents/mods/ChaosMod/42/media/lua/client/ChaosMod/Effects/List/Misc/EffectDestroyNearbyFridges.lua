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


    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if sq then
            ---@type table<integer, IsoObject>
            local fridges = {}
            ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
                if isFridge(obj) then
                    table.insert(fridges, obj)
                end
            end)
            for _, fridge in ipairs(fridges) do
                fridge:removeFromWorld()
                fridge:removeFromSquare()
                count = count + 1
            end
        end
    end, 0, RANGE, false, false, true, pz - 1, pz + 2)

    print("[EffectDestroyNearbyFridges] Destroyed " .. tostring(count) .. " fridges")
    ChaosPlayer.SayLineByColor(player, string.format(ChaosLocalization.GetString("misc", "fridges_destroyed"), count),
        ChaosPlayerChatColors.removedItem)
end
