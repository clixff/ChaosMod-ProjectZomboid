---@class EffectAddBombToPlayerInventory : ChaosEffectBase
---@field item InventoryItem | nil
EffectAddBombToPlayerInventory = ChaosEffectBase:derive("EffectAddBombToPlayerInventory", "add_bomb_to_player_inventory")

local EXPLOSION_RADIUS = 3
local ITEM_ID = "Base.PipeBombTriggered"

function EffectAddBombToPlayerInventory:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local item = inventory:AddItem(ITEM_ID)
    if not item then return end

    self.item = item

    local imgCode = ChaosUtils.GetImgCodeByItemTexture(item) or ""
    local itemName = item:getDisplayName() or ""
    local str = string.format("%s Item %s is now explosive", imgCode, itemName)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.red)
end

function EffectAddBombToPlayerInventory:OnEnd()
    ChaosEffectBase:OnEnd()

    if not self.item then return end

    local player = getPlayer()
    if not player then return end

    local item = self.item
    local playerInventory = player:getInventory()
    if not playerInventory then return end

    local inPlayerInv = playerInventory:contains(item, true)
    if inPlayerInv then
        local worn = player:getWornItems()
        if worn and worn:contains(item) then
            player:removeWornItem(item)
        end
        player:removeFromHands(item)
        item:Remove()

        local square = player:getSquare()
        if square then
            ChaosUtils.TriggerExplosionAt(square, EXPLOSION_RADIUS)
        end
        return
    end

    local outer = item:getOutermostContainer()
    if outer and outer:getParent() and outer ~= playerInventory then
        local square = outer:getSquare()
        if square then
            item:Remove()
            ChaosUtils.TriggerExplosionAt(square, EXPLOSION_RADIUS)
            return
        end
    end

    local worldItem = item:getWorldItem()
    if worldItem then
        local square = worldItem:getSquare()
        if square then
            ChaosUtils.RemoveWorldObject(worldItem, true)
            ChaosUtils.TriggerExplosionAt(square, EXPLOSION_RADIUS)
        end
    end
end
