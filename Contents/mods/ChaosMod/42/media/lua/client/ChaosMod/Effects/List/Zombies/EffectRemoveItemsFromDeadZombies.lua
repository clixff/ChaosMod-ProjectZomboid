EffectRemoveItemsFromDeadZombies = ChaosEffectBase:derive("EffectRemoveItemsFromDeadZombies",
    "remove_items_from_dead_zombies")

function EffectRemoveItemsFromDeadZombies:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()

    local radius = 40

    local minZ = z - 1
    local maxZ = z + 2
    local cell = getCell()

    local countCleaned = 0

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            local body = sq:getDeadBody()
            if body then
                local container = body:getContainer()
                if container then
                    container:removeAllItems()
                    countCleaned = countCleaned + 1
                end
            end
        end
    end, 0, radius, false, false, true, minZ, maxZ)


    print("[EffectRemoveItemsFromDeadZombies] Cleaned " .. tostring(countCleaned) .. " dead bodies")
end
