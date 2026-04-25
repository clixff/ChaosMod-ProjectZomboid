EffectSpoilFoodNearby = ChaosEffectBase:derive("EffectSpoilFoodNearby", "spoil_food_nearby")

local RADIUS = 35

---@param container ItemContainer
---@return integer
local function spoilFoodInContainer(container)
    local items = container:getItems()
    if not items then return 0 end

    local count = 0
    ---@type table<integer, InventoryItem>
    local itemList = {}
    for i = 0, items:size() - 1 do
        table.insert(itemList, items:get(i))
    end

    for _, item in ipairs(itemList) do
        if item:isFood() and item:getOffAgeMax() < 1000000000 then
            item:setAge(item:getOffAgeMax() + 1)
            item:updateAge()
            count = count + 1
        end
    end
    return count
end

function EffectSpoilFoodNearby:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local totalSpoiled = 0

    -- Spoil player inventory food
    local inventory = player:getInventory()
    if inventory then
        ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
            if item and item:isFood() and item:getOffAgeMax() < 1000000000 then
                item:setAge(item:getOffAgeMax() + 1)
                item:updateAge()
                totalSpoiled = totalSpoiled + 1
            end
        end)
    end

    -- Spoil food in nearby world containers
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local cell = getCell()

    for dz = -1, 2 do
        for dx = -RADIUS, RADIUS do
            for dy = -RADIUS, RADIUS do
                local sq = cell:getGridSquare(x + dx, y + dy, z + dz)
                if sq then
                    local objects = sq:getObjects()
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if obj and obj:getContainerCount() > 0 then
                            for j = 0, obj:getContainerCount() - 1 do
                                local container = obj:getContainerByIndex(j)
                                if container then
                                    totalSpoiled = totalSpoiled + spoilFoodInContainer(container)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    print("[EffectSpoilFoodNearby] Spoiled " .. tostring(totalSpoiled) .. " food items")

    local imgCode = ChaosUtils.GetImgCodeByItemTextureByString("Base.Bread")
    local msg = string.format(ChaosLocalization.GetString("misc", "food_spoiled"), imgCode, totalSpoiled)
    ChaosPlayer.SayLineByColor(player, msg, ChaosPlayerChatColors.removedItem)
end
