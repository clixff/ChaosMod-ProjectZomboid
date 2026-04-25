---@class EffectHideRandomItem : ChaosEffectBase
EffectHideRandomItem = ChaosEffectBase:derive("EffectHideRandomItem", "hide_random_item")

---@param container ItemContainer
---@param out InventoryItem[]
local function collectItems(container, out)
    if not container then return end
    if not container.getItems then return end
    local items = container:getItems()
    if not items then return end
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            if item:IsInventoryContainer() then
                ---@type InventoryContainer
                local inner = item
                collectItems(inner:getInventory(), out)
            else
                table.insert(out, item)
            end
        end
    end
end

function EffectHideRandomItem:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    ---@type InventoryItem[]
    local items = {}
    collectItems(inventory, items)

    if #items == 0 then return end

    local item = items[math.floor(ZombRand(1, #items + 1))]
    if not item then return end

    local sq = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 3, 20, 50, true, true, false)
    if not sq then return end

    print("[EffectHideRandomItem] X: " ..
        tostring(sq:getX()) .. " Y: " .. tostring(sq:getY()) .. " Z: " .. tostring(sq:getZ()))

    local worn = player:getWornItems()
    if worn and worn:contains(item) then
        player:removeWornItem(item)
    end

    inventory:Remove(item)
    sq:AddWorldInventoryItem(item, 0.5, 0.5, 0)

    local imgCode = ChaosUtils.GetImgCodeByItemTexture(item)
    local itemName = item:getDisplayName() or ""
    local str = string.format(ChaosLocalization.GetString("misc", "item_hidden"), imgCode, itemName)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)
end
