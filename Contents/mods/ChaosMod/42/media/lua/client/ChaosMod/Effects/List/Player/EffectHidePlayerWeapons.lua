---@class EffectHidePlayerWeapons : ChaosEffectBase
EffectHidePlayerWeapons = ChaosEffectBase:derive("EffectHidePlayerWeapons", "hide_player_weapons")

---@param container ItemContainer
---@param out InventoryItem[]
local function collectWeapons(container, out)
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
                collectWeapons(inner:getInventory(), out)
            elseif item:IsWeapon() then
                table.insert(out, item)
            end
        end
    end
end

function EffectHidePlayerWeapons:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    ---@type InventoryItem[]
    local weapons = {}
    collectWeapons(inventory, weapons)

    if #weapons == 0 then return end

    local sq = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 3, 20, 50, true, true, false)
    if not sq then return end

    print("[EffectHidePlayerWeapons] X: " ..
        tostring(sq:getX()) .. " Y: " .. tostring(sq:getY()) .. " Z: " .. tostring(sq:getZ()))

    for _, weapon in ipairs(weapons) do
        player:removeFromHands(weapon)
        inventory:Remove(weapon)
        sq:AddWorldInventoryItem(weapon, 0.5, 0.5, 0)
    end

    local str = string.format(ChaosLocalization.GetString("misc", "weapons_hidden"), #weapons)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)
end
