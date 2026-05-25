---@class EffectStealShoesFromEveryZombie : ChaosEffectBase
EffectStealShoesFromEveryZombie = ChaosEffectBase:derive("EffectStealShoesFromEveryZombie", "steal_shoes_from_every_zombie")

---@param visuals ItemVisuals
---@param removeIndex integer
---@param removeVisual ItemVisual
local function removeItemVisual(visuals, removeIndex, removeVisual)
    -- In Lua, Java ArrayList:remove(number) can resolve to remove(Object) instead of
    -- remove(int), so rebuild the list as a reliable way to mutate IsoZombie.itemVisuals.
    local keep = {}
    for j = 0, visuals:size() - 1 do
        local visual = visuals:get(j)
        if j ~= removeIndex and visual ~= removeVisual then
            table.insert(keep, visual)
        end
    end

    visuals:clear()
    for _, visual in ipairs(keep) do
        visuals:add(visual)
    end
end

---@param zombie IsoZombie
---@param player IsoPlayer
---@return InventoryItem | nil
local function takeShoesFromAliveZombie(zombie, player)
    if not zombie or not player then return nil end

    if zombie:isUsingWornItems() then
        local shoes = zombie:getWornItem(ItemBodyLocation.SHOES)
        if shoes then
            zombie:removeWornItem(shoes)
            player:getInventory():AddItem(shoes)
            zombie:resetModelNextFrame()
            zombie:onWornItemsChanged()
            return shoes
        end
        return nil
    end

    local visuals = zombie:getItemVisuals()
    if not visuals then return nil end

    for i = visuals:size() - 1, 0, -1 do
        local visual = visuals:get(i)
        local scriptItem = visual and visual:getScriptItem()

        if scriptItem and scriptItem:isBodyLocation(ItemBodyLocation.SHOES) then
            local shoes = instanceItem(visual:getItemType())
            if shoes then
                if shoes:getVisual() then
                    shoes:getVisual():copyFrom(visual)
                    shoes:synchWithVisual()
                end

                if shoes:getVisual() then
                    local cond = shoes:getConditionMax() - shoes:getVisual():getHolesNumber() * 3
                    shoes:setConditionNoSound(math.max(0, cond))
                end

                removeItemVisual(visuals, i, visual)

                player:getInventory():AddItem(shoes)

                zombie:resetModelNextFrame()
                zombie:onWornItemsChanged()

                return shoes
            end
        end
    end

    return nil
end

---@param body IsoDeadBody
---@param player IsoPlayer
---@return InventoryItem | nil
local function takeShoesFromDeadBody(body, player)
    if not body or not player then return nil end

    local wornItems = body:getWornItems()
    if not wornItems then return nil end

    local shoes = wornItems:getItem(ItemBodyLocation.SHOES)
    if not shoes then return nil end

    local corpseInv = body:getContainer()
    if not corpseInv then return nil end

    corpseInv:Remove(shoes)

    player:getInventory():AddItem(shoes)

    body:checkClothing(shoes)
    body:invalidateCorpse()

    return shoes
end

function EffectStealShoesFromEveryZombie:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local radius = 45

    local stolenCount = 0

    ChaosZombie.ForEachZombieInRange(x, y, radius, function(zombie)
        if not zombie or not zombie:isAlive() then return end
        local shoes = takeShoesFromAliveZombie(zombie, player)
        if shoes then
            stolenCount = stolenCount + 1
        end
    end, false, nil)

    local minZ = z - 1
    local maxZ = z + 2

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            local body = sq:getDeadBody()
            if body then
                local shoes = takeShoesFromDeadBody(body, player)
                if shoes then
                    stolenCount = stolenCount + 1
                end
            end
        end
    end, 0, radius, false, false, true, minZ, maxZ)

    local str = string.format(ChaosLocalization.GetString("misc", "stolen_shoes"), stolenCount)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.green)
    print("[EffectStealShoesFromEveryZombie] Stolen " .. tostring(stolenCount) .. " shoes")
end

function EffectStealShoesFromEveryZombie:OnEnd()
    ChaosEffectBase:OnEnd()
end
