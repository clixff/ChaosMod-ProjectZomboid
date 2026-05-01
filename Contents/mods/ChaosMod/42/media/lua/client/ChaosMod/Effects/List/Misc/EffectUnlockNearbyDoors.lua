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

    local Z = square:getZ()

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
                if instanceof(obj, "IsoDoor") then
                    if unlockDoor(obj) then
                        countUnlocked = countUnlocked + 1
                    end
                end
            end)
        end
    end, 0, radius, false, false, true, Z - 1, Z + 3)

    local str = string.format(ChaosLocalization.GetString("misc", "unlocked_doors"), countUnlocked)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.green)
    print("[EffectUnlockNearbyDoors] Unlocked " .. tostring(countUnlocked) .. " doors")
end
