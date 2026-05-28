---@class EffectTeleportIntoRandomBuilding : ChaosEffectBase
EffectTeleportIntoRandomBuilding = ChaosEffectBase:derive("EffectTeleportIntoRandomBuilding",
    "teleport_into_random_building")

local SEARCH_RADIUS = 90
local ZOMBIE_SAFE_RADIUS = 4.0
local BUILDING_ATTEMPTS = 20
local SQUARE_ATTEMPTS_PER_BUILDING = 40

---@param square IsoGridSquare | nil
---@return boolean
local function isSafeTeleportSquare(square)
    if not square then return false end
    if not square:isSolidFloor() then return false end
    if square:HasStairs() then return false end
    if not square:isFree(true) then return false end
    return true
end

---@param square IsoGridSquare
---@return boolean
local function hasZombieNearSquare(square)
    local hasZombie = false
    ChaosZombie.ForEachZombieInRange(square:getX(), square:getY(), ZOMBIE_SAFE_RADIUS, function()
        hasZombie = true
    end, true, square:getZ())
    return hasZombie
end

---@param building IsoBuilding
---@return IsoGridSquare | nil
local function getSafeRandomSquareInBuilding(building)
    if not building then return nil end

    for _ = 1, SQUARE_ATTEMPTS_PER_BUILDING do
        local room = building:getRandomRoom()
        if room then
            local candidate = room:getRandomFreeSquare()
            if isSafeTeleportSquare(candidate) and not hasZombieNearSquare(candidate) then
                return candidate
            end
        end
    end

    return nil
end

function EffectTeleportIntoRandomBuilding:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local px = playerSquare:getX()
    local py = playerSquare:getY()

    ---@type table<integer, boolean>
    local seenBuildingIds = {}
    ---@type IsoBuilding[]
    local buildings = {}

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return end
        local building = sq:getBuilding()
        if not building then return end
        local id = building:getID()
        if seenBuildingIds[id] then return end
        seenBuildingIds[id] = true
        buildings[#buildings + 1] = building
    end, 0, SEARCH_RADIUS, false, false, true, 0, 0)

    if #buildings == 0 then
        ChaosPlayer.SayLineByColor(player, ChaosLocalization.GetString("misc", "no_building_found"),
            ChaosPlayerChatColors.red)
        print("[EffectTeleportIntoRandomBuilding] No buildings found nearby")
        return
    end

    ---@type IsoGridSquare | nil
    local targetSquare = nil
    local attempts = math.min(#buildings, BUILDING_ATTEMPTS)
    for _ = 1, attempts do
        if #buildings == 0 then break end
        local idx = ChaosUtils.RandArrayIndex(buildings)
        local building = buildings[idx]
        if building then
            local candidate = getSafeRandomSquareInBuilding(building)
            if candidate then
                targetSquare = candidate
                break
            end
        end
        table.remove(buildings, idx)
    end

    if not targetSquare then
        ChaosPlayer.SayLineByColor(player, ChaosLocalization.GetString("misc", "no_building_found"),
            ChaosPlayerChatColors.red)
        print("[EffectTeleportIntoRandomBuilding] Found buildings but no free square inside")
        return
    end

    local tx = targetSquare:getX()
    local ty = targetSquare:getY()
    local tz = targetSquare:getZ()

    ChaosPlayer.TeleportPlayer(player, targetSquare)

    print(string.format("[EffectTeleportIntoRandomBuilding] Teleported to %d, %d, %d", tx, ty, tz))
end
