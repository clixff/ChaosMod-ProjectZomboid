EffectRemoveCurtainsNearby = ChaosEffectBase:derive("EffectRemoveCurtainsNearby", "remove_curtains_nearby")

local function removeCurtainsOnSquare(square)
    if not square then return 0 end
    local removed = 0
    local objects = square:getSpecialObjects()
    for i = objects:size() - 1, 0, -1 do
        local obj = objects:get(i)
        if instanceof(obj, "IsoCurtain") then
            obj:getSquare():transmitRemoveItemFromSquare(obj)
            removed = removed + 1
        end
    end
    return removed
end

function EffectRemoveCurtainsNearby:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local radius = 35
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local cell = getCell()
    local countRemoved = 0

    for dz = -1, 2 do
        for dx = -radius, radius do
            for dy = -radius, radius do
                local sq = cell:getGridSquare(x + dx, y + dy, z + dz)
                countRemoved = countRemoved + removeCurtainsOnSquare(sq)
            end
        end
    end

    local str = string.format(ChaosLocalization.GetString("misc", "removed_curtains"), countRemoved)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)
    print("[EffectRemoveCurtainsNearby] Removed " .. tostring(countRemoved) .. " curtains")
end
