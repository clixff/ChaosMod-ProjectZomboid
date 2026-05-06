---@class EffectHidePlayerClothes : ChaosEffectBase
EffectHidePlayerClothes = ChaosEffectBase:derive("EffectHidePlayerClothes", "hide_player_clothes")

---@param container ItemContainer
---@param out InventoryItem[]
local function collectClothes(container, out)
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
                collectClothes(inner:getInventory(), out)
            elseif item:IsClothing() then
                table.insert(out, item)
            end
        end
    end
end

function EffectHidePlayerClothes:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    ---@type InventoryItem[]
    local clothes = {}
    collectClothes(inventory, clothes)

    if #clothes == 0 then return end

    local sq = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 3, 20, 50, true, true, false)
    if not sq then return end

    print("[EffectHidePlayerClothes] X: " ..
        tostring(sq:getX()) .. " Y: " .. tostring(sq:getY()) .. " Z: " .. tostring(sq:getZ()))

    for _, clothing in ipairs(clothes) do
        local worn = player:getWornItems()
        if worn and worn:contains(clothing) then
            player:removeWornItem(clothing)
        end

        inventory:Remove(clothing)
        sq:AddWorldInventoryItem(clothing, 0.5, 0.5, 0)
    end

    player:onWornItemsChanged()
    player:resetModelNextFrame()
    triggerEvent("OnClothingUpdated", player)

    local str = string.format(ChaosLocalization.GetString("misc", "clothes_hidden"), #clothes)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)
end
