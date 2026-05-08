---@class EffectPickUpNearbyItems : ChaosEffectBase
---@field takenItemCount integer
EffectPickUpNearbyItems = ChaosEffectBase:derive("EffectPickUpNearbyItems", "pick_up_nearby_items")

local RANGE = 10

---@param playerInv ItemContainer
---@param container ItemContainer
---@param item InventoryItem?
---@return boolean
local function takeItemFromContainer(playerInv, container, item)
    if not playerInv or not container or not item then return false end
    container:Remove(item)
    playerInv:AddItem(item)
    return true
end

---@param playerInv ItemContainer
---@param worldObj IsoWorldInventoryObject?
---@return boolean
local function takeWorldItem(playerInv, worldObj)
    if not playerInv or not worldObj then return false end

    local item = worldObj:getItem()
    if not item then return false end

    local sq = worldObj:getSquare()

    if sq then
        sq:transmitRemoveItemFromSquare(worldObj)
    else
        worldObj:removeFromWorld()
        worldObj:removeFromSquare()
    end

    ---@diagnostic disable-next-line:param-type-mismatch
    item:setWorldItem(nil)
    playerInv:AddItem(item)
    return true
end

function EffectPickUpNearbyItems:OnStart()
    ChaosEffectBase:OnStart()

    self.takenItemCount = 0

    local player = getPlayer()
    if not player then return end

    local playerInv = player:getInventory()
    local square = player:getSquare()
    if not playerInv or not square then return end

    local px, py, pz = square:getX(), square:getY(), square:getZ()

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return end

        ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
            ChaosUtils.ForAllContainersInObject(obj, function(container)
                local items = container:getItems()
                if items and items:size() > 0 then
                    for i = items:size() - 1, 0, -1 do
                        local item = items:get(i)
                        if takeItemFromContainer(playerInv, container, item) then
                            self.takenItemCount = self.takenItemCount + 1
                        end
                    end
                end
            end)
        end)

        ChaosUtils.ForAllWorldObjectsOnSquare(sq, function(worldObj)
            if takeWorldItem(playerInv, worldObj) then
                self.takenItemCount = self.takenItemCount + 1
            end
        end)
    end, 0, RANGE, false, false, true, pz, pz)

    ChaosPlayer.SayLineByColor(player, string.format("%d items taken", self.takenItemCount), ChaosPlayerChatColors.green)
    print("[EffectPickUpNearbyItems] Took " .. tostring(self.takenItemCount) .. " nearby items")
end
