EffectRemoveBarricadesNearby = ChaosEffectBase:derive("EffectRemoveBarricadesNearby", "remove_barricades_nearby")

---@param square IsoGridSquare
---@return integer
local function removeBarricadesOnSquare(square)
    if not square then return 0 end
    local toRemove = {}
    local objects = square:getSpecialObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if instanceof(obj, "IsoBarricade") then
            table.insert(toRemove, obj)
        end
    end
    for i = 1, #toRemove do
        square:transmitRemoveItemFromSquare(toRemove[i])
    end
    return #toRemove
end

function EffectRemoveBarricadesNearby:OnStart()
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
                countRemoved = countRemoved + removeBarricadesOnSquare(sq)
            end
        end
    end

    local str = string.format(ChaosLocalization.GetString("misc", "removed_barricades"), countRemoved)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)
    print("[EffectRemoveBarricadesNearby] Removed " .. tostring(countRemoved) .. " barricades")
end
