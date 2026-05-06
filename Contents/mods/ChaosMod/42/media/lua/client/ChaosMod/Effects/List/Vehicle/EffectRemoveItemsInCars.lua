---@class EffectRemoveItemsInCars : ChaosEffectBase
---@field removedItemCount integer
EffectRemoveItemsInCars = ChaosEffectBase:derive("EffectRemoveItemsInCars", "remove_items_in_cars")

local VEHICLE_RADIUS = 50

---@param vehicle BaseVehicle?
---@return integer
local function clearVehicleContainers(vehicle)
    if not vehicle then return 0 end

    local removedCount = 0

    for i = 0, vehicle:getPartCount() - 1 do
        local part = vehicle:getPartByIndex(i)
        if part then
            local container = part:getItemContainer()
            if container then
                local items = container:getItems()
                if items then
                    removedCount = removedCount + items:size()
                end

                container:clear()

                if isServer() then
                    sendItemsInContainer(vehicle, container)
                end
            end
        end
    end

    return removedCount
end

function EffectRemoveItemsInCars:OnStart()
    ChaosEffectBase:OnStart()

    self.removedItemCount = 0

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, VEHICLE_RADIUS)
    if not vehicles then return end

    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            self.removedItemCount = self.removedItemCount + clearVehicleContainers(vehicle)
        end
    end

    ChaosPlayer.SayLineByColor(player,
        string.format("Removed %d items in cars", self.removedItemCount),
        ChaosPlayerChatColors.red)
end
