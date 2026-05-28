---@class EffectRemoveFurnitureNearby : ChaosEffectBase
EffectRemoveFurnitureNearby = ChaosEffectBase:derive("EffectRemoveFurnitureNearby", "remove_furniture_nearby")

local RANGE = 45

function EffectRemoveFurnitureNearby:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemoveFurnitureNearby] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local px, py, pz = square:getX(), square:getY(), square:getZ()

    ---@type table<integer, IsoObject>
    local furniture = {}

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if sq then
            ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
                if obj and not obj:hasSpriteGrid() and ChaosProps.GetFurnitureType(obj) ~= nil then
                    table.insert(furniture, obj)
                end
            end)
        end
    end, 0, RANGE, false, false, true, pz - 1, pz + 2)

    local removed = 0
    for _, obj in ipairs(furniture) do
        obj:removeFromWorld()
        obj:removeFromSquare()
        removed = removed + 1
    end

    print("[EffectRemoveFurnitureNearby] Removed " .. tostring(removed) .. " furniture objects")
end

function EffectRemoveFurnitureNearby:OnEnd()
    ChaosEffectBase:OnEnd()
end
