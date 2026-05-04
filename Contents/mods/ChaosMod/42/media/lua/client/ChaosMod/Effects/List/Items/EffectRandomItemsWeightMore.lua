---@class EffectRandomItemsWeightMore : ChaosEffectBase
EffectRandomItemsWeightMore = ChaosEffectBase:derive("EffectRandomItemsWeightMore", "random_items_weight_more")

---@param item InventoryItem
---@return boolean
local function isEligibleItem(item)
    if not item then return false end
    if instanceof(item, "HandWeapon") then return false end
    if instanceof(item, "DrainableComboItem") then return false end
    return true
end

function EffectRandomItemsWeightMore:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    ---@type InventoryItem[]
    local items = {}
    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, function(item)
        if isEligibleItem(item) then
            table.insert(items, item)
        end
    end)

    if #items == 0 then return end

    local count = math.min(3, #items)
    for _ = 1, count do
        local itemIndex = ChaosUtils.RandArrayIndex(items)
        local item = items[itemIndex]
        if item then
            local newWeight = item:getActualWeight() + 2.5
            item:setActualWeight(newWeight)
            item:setWeight(newWeight)
            item:setCustomWeight(true)

            local imgCode = ChaosUtils.GetImgCodeByItemTexture(item)
            local itemName = item:getDisplayName() or ""
            local str = string.format("%s %s: + 2.5 Kg", imgCode, itemName)
            ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)

            table.remove(items, itemIndex)
        end
    end
end
