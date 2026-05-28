---@class EffectReplaceFoodWithCatFood : ChaosEffectBase
EffectReplaceFoodWithCatFood = ChaosEffectBase:derive("EffectReplaceFoodWithCatFood", "replace_food_with_cat_food")

local RADIUS = 90
local REPLACEMENT_ITEM = "Base.CatTreats"

---@param container ItemContainer
---@param replacementItem string
---@return integer
local function replaceFoodInContainer(container, replacementItem)
    local items = container:getItems()
    if not items or items:size() == 0 then return 0 end

    local count = 0
    for i = items:size() - 1, 0, -1 do
        local item = items:get(i)
        if item and item:isFood() then
            container:Remove(item)
            count = count + 1
        end
    end

    for _ = 1, count do
        container:AddItem(replacementItem)
    end

    return count
end

---@param vehicle BaseVehicle
---@param replacementItem string
---@return integer
local function replaceFoodInVehicle(vehicle, replacementItem)
    if not vehicle then return 0 end

    local count = 0
    for i = 0, vehicle:getPartCount() - 1 do
        local part = vehicle:getPartByIndex(i)
        if part then
            local container = part:getItemContainer()
            if container then
                count = count + replaceFoodInContainer(container, replacementItem)
                if isServer() then
                    sendItemsInContainer(vehicle, container)
                end
            end
        end
    end
    return count
end

function EffectReplaceFoodWithCatFood:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local totalReplaced = 0

    local inventory = player:getInventory()
    if inventory then
        local playerRemoved = 0
        ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
            if item and item:isFood() then
                item:Remove()
                playerRemoved = playerRemoved + 1
            end
        end)
        for _ = 1, playerRemoved do
            inventory:AddItem(REPLACEMENT_ITEM)
        end
        totalReplaced = totalReplaced + playerRemoved
    end

    local x, y, z = square:getX(), square:getY(), square:getZ()

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if not sq then return end
        ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
            ChaosUtils.ForAllContainersInObject(obj, function(container)
                totalReplaced = totalReplaced + replaceFoodInContainer(container, REPLACEMENT_ITEM)
            end)
        end)
    end, 0, RADIUS, false, false, true, z - 1, z + 3)

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, RADIUS)
    if vehicles then
        for i = 0, vehicles:size() - 1 do
            local vehicle = vehicles:get(i)
            if vehicle then
                totalReplaced = totalReplaced + replaceFoodInVehicle(vehicle, REPLACEMENT_ITEM)
            end
        end
    end

    local imgCode = ChaosUtils.GetImgCodeByItemTextureByString(REPLACEMENT_ITEM)
    local msg = string.format(ChaosLocalization.GetString("misc", "food_replaced_with_cat_food"), imgCode, totalReplaced)
    ChaosPlayer.SayLineByColor(player, msg, ChaosPlayerChatColors.red)
end
