---@class EffectHidePlayerBooks : ChaosEffectBase
EffectHidePlayerBooks = ChaosEffectBase:derive("EffectHidePlayerBooks", "hide_player_books")

---@param container ItemContainer
---@param out InventoryItem[]
local function collectBooks(container, out)
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
                collectBooks(inner:getInventory(), out)
            elseif item:IsLiterature() then
                table.insert(out, item)
            end
        end
    end
end

function EffectHidePlayerBooks:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    ---@type InventoryItem[]
    local books = {}
    collectBooks(inventory, books)

    if #books == 0 then return end

    local sq = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 3, 20, 50, true, true, false)
    if not sq then return end

    print("[EffectHidePlayerBooks] X: " ..
        tostring(sq:getX()) .. " Y: " .. tostring(sq:getY()) .. " Z: " .. tostring(sq:getZ()))

    for _, book in ipairs(books) do
        local worn = player:getWornItems()
        if worn and worn:contains(book) then
            player:removeWornItem(book)
        end
        inventory:Remove(book)
        sq:AddWorldInventoryItem(book, 0.5, 0.5, 0)
    end

    local str = string.format(ChaosLocalization.GetString("misc", "books_hidden"), #books)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)
end
