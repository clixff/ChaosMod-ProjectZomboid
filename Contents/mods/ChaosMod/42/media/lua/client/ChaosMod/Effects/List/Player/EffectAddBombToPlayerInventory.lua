---@class EffectAddBombToPlayerInventory : ChaosEffectBase
EffectAddBombToPlayerInventory = ChaosEffectBase:derive("EffectAddBombToPlayerInventory", "add_bomb_to_player_inventory")

local EXPLOSION_RADIUS = 3
local ITEM_ID = "Base.PipeBombTriggered"
local MAX_DURATION = 8000


---@param data { item: InventoryItem }
local function ExplodeBomb(data)
    if not data.item then return end

    local player = getPlayer()
    if not player then return end

    local item = data.item
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

---@param deltaMs integer
---@param data { item: InventoryItem, elapsedMs: integer }
local function AddBombToPlayerInventoryTick(deltaMs, data)
    if not data.item then return end

    local player = getPlayer()
    local bar = UIManager.getProgressBar(0)
    data.elapsedMs = data.elapsedMs + deltaMs
    local progress = data.elapsedMs / MAX_DURATION
    bar:setValue(progress)
    print(string.format("Progress: %d", progress))
end

function EffectAddBombToPlayerInventory:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local item = inventory:AddItem(ITEM_ID)
    if not item then return end

    local imgCode = ChaosUtils.GetImgCodeByItemTexture(item) or ""
    local itemName = item:getDisplayName() or ""
    local str = string.format("%s Item %s is now explosive", imgCode, itemName)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.red)

    -- ChaosTimedProgressAction.AddNewTimedAction(player, MAX_DURATION)
    ChaosSpecialAction.AddNewAction({ item = item, elapsedMs = 0 }, MAX_DURATION, AddBombToPlayerInventoryTick,
        ExplodeBomb, nil)
end

function EffectAddBombToPlayerInventory:OnEnd()
    ChaosEffectBase:OnEnd()
end
