EffectRemoveFoodNearby = ChaosEffectBase:derive("EffectRemoveFoodNearby", "remove_food_nearby")

function EffectRemoveFoodNearby:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local radius = 40
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local cell = getCell()

    local totalRemoved = 0

    local Z = square:getZ()

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
                ChaosUtils.ForAllContainersInObject(obj, function(container)
                    local items = container:getItems()
                    --- backward loop to avoid index out of bounds
                    if items and items:size() > 0 then
                        for i = items:size() - 1, 0, -1 do
                            local item = items:get(i)
                            if item and item:isFood() then
                                container:Remove(item)
                                totalRemoved = totalRemoved + 1
                            end
                        end
                    end
                end)
            end)
        end
    end, 0, radius, false, false, true, Z - 1, Z + 3)

    print("[EffectRemoveFoodNearby] Removed " .. tostring(totalRemoved) .. " food items")
end
