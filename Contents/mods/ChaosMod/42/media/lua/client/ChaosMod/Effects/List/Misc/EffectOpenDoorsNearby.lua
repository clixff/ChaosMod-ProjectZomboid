EffectOpenDoorsNearby = ChaosEffectBase:derive("EffectOpenDoorsNearby", "open_doors_nearby")

local function forceOpenDoorIfClosed(door)
    if not door or not instanceof(door, "IsoDoor") then
        return false
    end
    if door:isBarricaded() then
        return false
    end
    door:setLocked(false)
    door:setLockedByKey(false)
    if not door:IsOpen() then
        door:ToggleDoorSilent()
        door:sync()
    end
    return door:IsOpen()
end

function EffectOpenDoorsNearby:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local radius = 35
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local cell = getCell()
    local countOpened = 0

    local Z = square:getZ()

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
                if instanceof(obj, "IsoDoor") then
                    if forceOpenDoorIfClosed(obj) then
                        countOpened = countOpened + 1
                    end
                end
            end)
        end
    end, 0, radius, false, false, true, Z - 1, Z + 3)

    local str = string.format(ChaosLocalization.GetString("misc", "opened_doors"), countOpened)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.green)
    print("[EffectOpenDoorsNearby] Opened " .. tostring(countOpened) .. " doors")
end
