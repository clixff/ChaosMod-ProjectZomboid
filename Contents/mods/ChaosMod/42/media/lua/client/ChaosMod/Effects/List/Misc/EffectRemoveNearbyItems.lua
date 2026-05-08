---@class EffectRemoveNearbyItems : ChaosEffectBase
---@field removedItemCount integer
EffectRemoveNearbyItems = ChaosEffectBase:derive("EffectRemoveNearbyItems", "remove_nearby_items")

local RANGE = 25

---@param item InventoryItem?
---@return boolean
local function removeItem(item)
    if not item then return false end
    InventoryItem.RemoveFromContainer(item)
    pcall(function() item:Remove() end)
    return true
end

function EffectRemoveNearbyItems:OnStart()
    ChaosEffectBase:OnStart()

    self.removedItemCount = 0

    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local px, py, pz = square:getX(), square:getY(), square:getZ()

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return end

        ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
            ChaosUtils.ForAllContainersInObject(obj, function(container)
                local items = container:getItems()
                if items and items:size() > 0 then
                    for i = items:size() - 1, 0, -1 do
                        local item = items:get(i)
                        if removeItem(item) then
                            self.removedItemCount = self.removedItemCount + 1
                        end
                    end
                end
            end)
        end)

        ChaosUtils.ForAllWorldObjectsOnSquare(sq, function(worldObj)
            if not worldObj then return end
            local item = worldObj:getItem()
            if removeItem(item) then
                self.removedItemCount = self.removedItemCount + 1
            end
        end)
    end, 0, RANGE, false, false, true, pz - 1, pz + 2)

    print("[EffectRemoveNearbyItems] Removed " .. tostring(self.removedItemCount) .. " nearby items")
end

function EffectRemoveNearbyItems:OnEnd()
    ChaosEffectBase:OnEnd()

    local player = getPlayer()
    if not player then return end

    ChaosPlayer.SayLineByColor(player,
        string.format("Removed %d nearby items", self.removedItemCount or 0),
        ChaosPlayerChatColors.removedItem)
end
