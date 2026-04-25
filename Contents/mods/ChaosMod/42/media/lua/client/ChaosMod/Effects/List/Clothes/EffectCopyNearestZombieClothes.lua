EffectCopyNearestZombieClothes = ChaosEffectBase:derive("EffectCopyNearestZombieClothes", "copy_nearest_zombie_clothes")

---@param visual ItemVisual
---@return InventoryItem?
local function copyItemFromVisual(visual)
    if not visual then return nil end
    local itemType = visual:getItemType()
    if not itemType then return nil end
    local item = instanceItem(itemType)
    if not item then return nil end
    if item:getVisual() then
        item:getVisual():copyFrom(visual)
        item:synchWithVisual()
    end
    return item
end

---@param item InventoryItem
---@return ItemBodyLocation?
local function getBodyLocationForItem(item)
    if item:getBodyLocation() then
        return item:getBodyLocation()
    end
    local equip = item:canBeEquipped()
    return equip
end

function EffectCopyNearestZombieClothes:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectCopyNearestZombieClothes] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local zed = ChaosZombie.GetNearestZombie(player:getX(), player:getY())
    if not zed then return end

    local inventory = player:getInventory()
    local itemsList = inventory:getItems()

    for i = itemsList:size() - 1, 0, -1 do
        local item = itemsList:get(i)
        if item and item:IsClothing() and not item:IsInventoryContainer() then
            local isWorn = player:getWornItems():contains(item)
            if isWorn then
                item:Remove()
            end
        end
    end

    player:getWornItems():clear()

    local visuals = zed:getItemVisuals()
    for i = 0, visuals:size() - 1 do
        local visual = visuals:get(i)
        local dst = copyItemFromVisual(visual)
        local loc = dst and getBodyLocationForItem(dst)
        if dst and loc then
            inventory:AddItem(dst)
            player:setWornItem(loc, dst)
        end
    end

    player:onWornItemsChanged()
    player:resetModelNextFrame()
    triggerEvent("OnClothingUpdated", player)
end
