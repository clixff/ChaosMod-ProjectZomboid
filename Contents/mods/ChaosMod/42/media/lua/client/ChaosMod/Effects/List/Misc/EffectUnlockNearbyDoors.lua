EffectUnlockNearbyDoors = ChaosEffectBase:derive("EffectUnlockNearbyDoors", "unlock_nearby_doors")

local function unlockDoor(door)
    if not door or not instanceof(door, "IsoDoor") then
        return false
    end
    door:setLocked(false)
    door:setLockedByKey(false)
    return true
end

function EffectUnlockNearbyDoors:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local radius = 35
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local cell = getCell()
    local countUnlocked = 0

    for dz = -1, 2 do
        for dx = -radius, radius do
            for dy = -radius, radius do
                local sq = cell:getGridSquare(x + dx, y + dy, z + dz)
                if sq then
                    local objects = sq:getObjects()
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if instanceof(obj, "IsoDoor") then
                            if unlockDoor(obj) then
                                countUnlocked = countUnlocked + 1
                            end
                        end
                    end
                end
            end
        end
    end

    local str = string.format(ChaosLocalization.GetString("misc", "unlocked_doors"), countUnlocked)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.green)
    print("[EffectUnlockNearbyDoors] Unlocked " .. tostring(countUnlocked) .. " doors")
end
