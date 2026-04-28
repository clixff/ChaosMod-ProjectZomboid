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

    for dz = -1, 2 do
        for dx = -radius, radius do
            for dy = -radius, radius do
                local sq = cell:getGridSquare(x + dx, y + dy, z + dz)
                if sq then
                    local objects = sq:getObjects()
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if obj and obj:getContainerCount() > 0 then
                            for ci = 0, obj:getContainerCount() - 1 do
                                local container = obj:getContainerByIndex(ci)
                                if container then
                                    local items = container:getItems()
                                    if items and items:size() > 0 then
                                        ---@type table<integer, InventoryItem>
                                        local itemList = {}
                                        for ii = 0, items:size() - 1 do
                                            local item = items:get(ii)
                                            if item and item:isFood() then
                                                table.insert(itemList, item)
                                            end
                                        end
                                        for _, item in ipairs(itemList) do
                                            container:Remove(item)
                                            totalRemoved = totalRemoved + 1
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    print("[EffectRemoveFoodNearby] Removed " .. tostring(totalRemoved) .. " food items")
end
