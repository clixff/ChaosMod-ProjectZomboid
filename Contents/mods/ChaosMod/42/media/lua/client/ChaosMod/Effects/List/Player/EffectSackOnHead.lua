---@class EffectSackOnHead : ChaosEffectBase
---@field sackItem InventoryItem?
---@field hud ChaosHeadsackHUD?
EffectSackOnHead = ChaosEffectBase:derive("EffectSackOnHead", "sack_on_head")

local SACK_ITEM_ID = "Base.Hat_HeadSack_Burlap"

local orig_dropItem = nil
local orig_onPlaceItemOnGround = nil
local blockedItem = nil

---@param item InventoryItem?
---@return boolean
local function isBlockedItem(item)
    if not item or not blockedItem then return false end
    if item == blockedItem then return true end
    if type(item.getFullType) == "function" and item:getFullType() == SACK_ITEM_ID then
        return true
    end
    return false
end

---@param items table?
---@return boolean
local function containsBlockedItem(items)
    if not items then return false end
    for i = 1, #items do
        local entry = items[i]
        if entry then
            if entry.items and type(entry.items) == "table" then
                for j = 1, #entry.items do
                    if isBlockedItem(entry.items[j]) then
                        return true
                    end
                end
            elseif isBlockedItem(entry) then
                return true
            end
        end
    end
    return false
end

---@param player IsoPlayer
---@return InventoryItem?
local function findSackInInventory(player)
    local inventory = player:getInventory()
    if not inventory then return nil end
    return inventory:FindAndReturn(SACK_ITEM_ID)
end

---@param player IsoPlayer
local function removeExistingHat(player)
    local wornItems = player:getWornItems()
    if not wornItems then return end

    local locations = { ItemBodyLocation.HAT, ItemBodyLocation.FULLHAT }
    for _, loc in ipairs(locations) do
        local item = wornItems:getItem(loc)
        if item then
            player:removeWornItem(item)
            local inventory = player:getInventory()
            if inventory then
                inventory:Remove(item)
            end
            local sq = player:getSquare()
            if sq then sq:AddWorldInventoryItem(item, 0.5, 0.5, 0) end
        end
    end
end

function EffectSackOnHead:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    removeExistingHat(player)

    local item = inventory:AddItem(SACK_ITEM_ID)
    if not item then return end

    self.sackItem = item
    blockedItem = item

    ChaosPlayer.EquipClothes(player, item)
    player:onWornItemsChanged()
    player:resetModelNextFrame()

    orig_dropItem = ISInventoryPaneContextMenu.dropItem
    ISInventoryPaneContextMenu.dropItem = function(droppedItem, playerArg)
        if isBlockedItem(droppedItem) then
            return
        end
        return orig_dropItem(droppedItem, playerArg)
    end

    orig_onPlaceItemOnGround = ISInventoryPaneContextMenu.onPlaceItemOnGround
    ISInventoryPaneContextMenu.onPlaceItemOnGround = function(items, playerObj)
        if containsBlockedItem(items) then
            return
        end
        return orig_onPlaceItemOnGround(items, playerObj)
    end

    self.hud = ChaosHeadsackHUD:new()
    self.hud:initialise()
    self.hud:addToUIManager()
    self.hud:setVisible(true)
end

---@param deltaMs integer
function EffectSackOnHead:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local item = self.sackItem
    if not item or not inventory:contains(item) then
        item = findSackInInventory(player)
        if not item then
            item = inventory:AddItem(SACK_ITEM_ID)
        end
        self.sackItem = item
        blockedItem = item
    end

    if not item then return end

    local wornItems = player:getWornItems()
    if wornItems and not wornItems:contains(item) then
        ChaosPlayer.EquipClothes(player, item)
        player:onWornItemsChanged()
        player:resetModelNextFrame()
    end
end

function EffectSackOnHead:OnEnd()
    ChaosEffectBase:OnEnd()

    if orig_dropItem then
        ISInventoryPaneContextMenu.dropItem = orig_dropItem
        orig_dropItem = nil
    end
    if orig_onPlaceItemOnGround then
        ISInventoryPaneContextMenu.onPlaceItemOnGround = orig_onPlaceItemOnGround
        orig_onPlaceItemOnGround = nil
    end

    local player = getPlayer()
    if player then
        local item = self.sackItem or findSackInInventory(player)
        if item then
            local wornItems = player:getWornItems()
            if wornItems and wornItems:contains(item) then
                player:removeWornItem(item)
            end
            local inventory = player:getInventory()
            if inventory then
                inventory:Remove(item)
            end
            player:onWornItemsChanged()
            player:resetModelNextFrame()
            triggerEvent("OnClothingUpdated", player)
        end
    end

    self.sackItem = nil
    blockedItem = nil

    if self.hud then
        self.hud:setVisible(false)
        self.hud:removeFromUIManager()
        self.hud = nil
    end
end
