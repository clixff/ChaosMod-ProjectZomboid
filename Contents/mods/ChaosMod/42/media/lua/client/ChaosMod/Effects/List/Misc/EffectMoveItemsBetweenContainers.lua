EffectMoveItemsBetweenContainers = ChaosEffectBase:derive("EffectMoveItemsBetweenContainers",
    "move_items_between_containers")

---@param obj IsoObject
---@return table<integer, ItemContainer>
local function getObjectContainers(obj)
    ---@type table<integer, ItemContainer>
    local result = {}
    if not obj then return result end
    for i = 0, obj:getContainerCount() - 1 do
        local c = obj:getContainerByIndex(i)
        if c then
            table.insert(result, c)
        end
    end
    return result
end

---@param player IsoPlayer
---@param item InventoryItem
---@param src ItemContainer
---@param dst ItemContainer
---@return boolean
local function moveItemBetweenContainers(player, item, src, dst)
    if not item or not src or not dst then return false end
    if not src:contains(item) then return false end
    if not dst:hasRoomFor(player, item) then return false end
    src:Remove(item)
    dst:AddItem(item)
    return true
end

function EffectMoveItemsBetweenContainers:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local radius = 40
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local cell = getCell()

    ---@type table<integer, ItemContainer>
    local allContainers = {}

    local Z = square:getZ()

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
                ChaosUtils.ForAllContainersInObject(obj, function(c)
                    table.insert(allContainers, c)
                end)
            end)
        end
    end, 0, radius, false, false, true, Z - 1, Z + 3)

    local containerCount = #allContainers
    if containerCount < 2 then return end

    local totalMoved = 0

    for _, src in ipairs(allContainers) do
        local items = src:getItems()
        if items and items:size() > 0 then
            ---@type table<integer, InventoryItem>
            local itemList = {}
            for i = 0, items:size() - 1 do
                table.insert(itemList, items:get(i))
            end

            for _, item in ipairs(itemList) do
                local dstIndex = math.floor(ZombRand(1, containerCount + 1))
                local dst = allContainers[dstIndex]
                if moveItemBetweenContainers(player, item, src, dst) then
                    totalMoved = totalMoved + 1
                end
            end
        end
    end

    print("[EffectMoveItemsBetweenContainers] Moved " .. tostring(totalMoved) .. " items")
end
