---@class EffectChangeFloorPlan : ChaosEffectBase
EffectChangeFloorPlan = ChaosEffectBase:derive("EffectChangeFloorPlan", "change_floor_plan")

local RANGE = 50
local Z_RANGE = 3

function EffectChangeFloorPlan:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local cell = getCell()
    local px, py, pz = square:getX(), square:getY(), square:getZ()

    ---@type IsoObject[]
    local furniture = {}

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if sq then
            ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
                if obj and not obj:hasSpriteGrid() and ChaosProps.GetFurnitureType(obj) ~= nil then
                    table.insert(furniture, obj)
                end
            end)
        end
    end, 0, RANGE, false, false, true, pz - 1, pz + 1)

    -- Fisher-Yates shuffle so pairs are random
    for i = #furniture, 2, -1 do
        local j = ZombRand(1, i + 1)
        furniture[i], furniture[j] = furniture[j], furniture[i]
    end

    -- Swap consecutive pairs
    local swapped = 0
    local i = 1
    while i + 1 <= #furniture do
        ---@type IsoObject | nil
        local obj1 = furniture[i]
        ---@type IsoObject | nil
        local obj2 = furniture[i + 1]
        if obj1 and obj2 then
            local sq1 = obj1:getSquare()
            local sq2 = obj2:getSquare()
            if sq1 and sq2 and sq1 ~= sq2 then
                obj1:removeFromWorld()
                obj1:removeFromSquare()
                obj2:removeFromWorld()
                obj2:removeFromSquare()
                obj1:setSquare(sq2)
                sq2:AddTileObject(obj1)
                obj2:setSquare(sq1)
                sq1:AddTileObject(obj2)
                swapped = swapped + 1
            end
            i = i + 2
        end
    end

    print("[EffectChangeFloorPlan] Swapped " .. tostring(swapped) .. " furniture pairs")
end
