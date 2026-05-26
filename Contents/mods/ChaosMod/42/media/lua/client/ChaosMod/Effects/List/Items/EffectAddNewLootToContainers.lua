---@class EffectAddNewLootToContainers : ChaosEffectBase
EffectAddNewLootToContainers = ChaosEffectBase:derive("EffectAddNewLootToContainers", "add_new_loot_to_containers")

local SEARCH_RADIUS = 60
local MIN_ITEMS_PER_CONTAINER = 3
local MAX_ITEMS_PER_CONTAINER = 5

---@param container ItemContainer
---@return integer
local function addRandomItemsToContainer(container)
    if not container then return 0 end

    local count = ChaosUtils.RandIntegerRange(MIN_ITEMS_PER_CONTAINER, MAX_ITEMS_PER_CONTAINER + 1)
    local added = 0

    for _ = 1, count do
        local itemId = ChaosItems.GetRandomItemId()
        if itemId and itemId ~= "" then
            local item = container:AddItem(itemId)
            if item then
                added = added + 1
            end
        end
    end

    return added
end

function EffectAddNewLootToContainers:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()

    local totalAdded = 0

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if not sq then return end
        ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
            ChaosUtils.ForAllContainersInObject(obj, function(c)
                totalAdded = totalAdded + addRandomItemsToContainer(c)
            end)
        end)
    end, 0, SEARCH_RADIUS, false, false, true, z - 1, z + 3)

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, SEARCH_RADIUS)
    if vehicles then
        for i = 0, vehicles:size() - 1 do
            local vehicle = vehicles:get(i)
            if vehicle then
                for partIndex = 0, vehicle:getPartCount() - 1 do
                    local part = vehicle:getPartByIndex(partIndex)
                    if part then
                        local container = part:getItemContainer()
                        if container then
                            totalAdded = totalAdded + addRandomItemsToContainer(container)
                            if isServer() then
                                sendItemsInContainer(vehicle, container)
                            end
                        end
                    end
                end
            end
        end
    end

    ChaosPlayer.SayLineByColor(player,
        string.format("Added %d items to containers", totalAdded),
        ChaosPlayerChatColors.green)
end

function EffectAddNewLootToContainers:OnEnd()
    ChaosEffectBase:OnEnd()
end
