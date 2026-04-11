---@class EffectRemoveRandomItem : ChaosEffectBase
---@field allItemsTable table<integer, { item:InventoryItem }>
EffectRemoveRandomItem = ChaosEffectBase:derive("EffectRemoveRandomItem", "remove_random_item")



---@param container ItemContainer
---@param arrayItems table<integer, { item:InventoryItem }>
local function findRandomItemNestedInContainer(container, arrayItems)
    if not container then return end
    if not container.getItems then
        return
    end
    local items = container:getItems()
    if not items then
        return
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local fullType = item:getFullType()

            if item:IsInventoryContainer() then
                ---@type InventoryContainer
                local innerContainer = item
                if innerContainer then
                    findRandomItemNestedInContainer(innerContainer:getInventory(), arrayItems)
                end
            else
                table.insert(arrayItems, { item = item })
            end
        end
    end
end

function EffectRemoveRandomItem:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemoveRandomItem] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    self.allItemsTable = {}
    findRandomItemNestedInContainer(inventory, self.allItemsTable)

    if self.allItemsTable and #self.allItemsTable > 0 then
        local randomIndex = math.floor(ZombRand(1, #self.allItemsTable + 1))
        local randomItem = self.allItemsTable[randomIndex]
        if randomItem then
            local worn = player:getWornItems()

            if worn and worn:contains(randomItem.item) then
                player:removeWornItem(randomItem.item)
            end

            local itemDisplayName = randomItem.item:getDisplayName()

            local textureIcon = randomItem.item:getIcon()
            local textureIconName = textureIcon:getName()

            -- player:SayDebug(1, "Removed " .. itemDisplayName)
            player:setHaloNote(string.format("[img=%s] Removed %s", textureIconName, itemDisplayName), 255.0, 0.0, 0.0,
                800.0)
        end
    end
end
