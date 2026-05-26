---@class EffectPoisonNearbyFood : ChaosEffectBase
EffectPoisonNearbyFood = ChaosEffectBase:derive("EffectPoisonNearbyFood", "poison_nearby_food")

local RADIUS = 35
local POISON_POWER = 20
local POISON_DETECTION_LEVEL = 10

---@param item InventoryItem?
---@return boolean
local function poisonFoodItem(item)
    if not item or not item:isFood() then return false end
    ---@cast item Food
    item:setPoisonPower(POISON_POWER)
    item:setPoisonDetectionLevel(POISON_DETECTION_LEVEL)
    return true
end

---@param container ItemContainer
---@return integer
local function poisonFoodInContainer(container)
    local items = container:getItems()
    if not items or items:size() == 0 then return 0 end

    local count = 0
    for i = 0, items:size() - 1 do
        if poisonFoodItem(items:get(i)) then
            count = count + 1
        end
    end
    return count
end

---@param vehicle BaseVehicle
---@return integer
local function poisonFoodInVehicle(vehicle)
    if not vehicle then return 0 end

    local count = 0
    for i = 0, vehicle:getPartCount() - 1 do
        local part = vehicle:getPartByIndex(i)
        if part then
            local container = part:getItemContainer()
            if container then
                count = count + poisonFoodInContainer(container)
            end
        end
    end
    return count
end

function EffectPoisonNearbyFood:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local totalPoisoned = 0

    local inventory = player:getInventory()
    if inventory then
        ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
            if poisonFoodItem(item) then
                totalPoisoned = totalPoisoned + 1
            end
        end)
    end

    local x, y, z = square:getX(), square:getY(), square:getZ()

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if not sq then return end
        ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
            ChaosUtils.ForAllContainersInObject(obj, function(container)
                totalPoisoned = totalPoisoned + poisonFoodInContainer(container)
            end)
        end)
        ChaosUtils.ForAllWorldObjectsOnSquare(sq, function(worldObj)
            if worldObj and poisonFoodItem(worldObj:getItem()) then
                totalPoisoned = totalPoisoned + 1
            end
        end)
    end, 0, RADIUS, false, false, true, z - 1, z + 2)

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, RADIUS)
    if vehicles then
        for i = 0, vehicles:size() - 1 do
            local vehicle = vehicles:get(i)
            if vehicle then
                totalPoisoned = totalPoisoned + poisonFoodInVehicle(vehicle)
            end
        end
    end

    local imgCode = ChaosUtils.GetImgCodeByItemTextureByString("Base.Bread")
    local msg = string.format(ChaosLocalization.GetString("misc", "food_poisoned"), imgCode, totalPoisoned)
    ChaosPlayer.SayLineByColor(player, msg, ChaosPlayerChatColors.red)
end

function EffectPoisonNearbyFood:OnEnd()
    ChaosEffectBase:OnEnd()
end
