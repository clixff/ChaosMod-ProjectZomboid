---@class EffectTeleportFromZombies : ChaosEffectBase
EffectTeleportFromZombies = ChaosEffectBase:derive("EffectTeleportFromZombies", "teleport_from_zombies")

local DANGER_RADIUS = 2.0
local SAFE_RADIUS = 5.0
local SEARCH_MAX_DISTANCE = 100

function EffectTeleportFromZombies:OnStart()
    ChaosEffectBase:OnStart()
end

---@param player IsoPlayer
local function tryTeleportPlayerAwayFromZombies(player)
    local square = player:getSquare()
    if not square then return end

    local px, py = square:getX(), square:getY()

    ---@type IsoGridSquare | nil
    local safeSq = nil
    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return false end
        local sx, sy = sq:getX(), sq:getY()
        local nearby = ChaosZombie.GetNearestZombies(sx, sy, SAFE_RADIUS, false, 0)
        if nearby:size() == 0 then
            safeSq = sq
            return true
        end
        return false
    end, 0, SEARCH_MAX_DISTANCE, true, true, true, 0, 0)

    if not safeSq then
        print("[EffectTeleportFromZombies] No safe square found at Z=0")
        return
    end

    ChaosPlayer.TeleportPlayer(player, safeSq)
    print(string.format("[EffectTeleportFromZombies] Teleported player to %d, %d, %d",
        safeSq:getX(), safeSq:getY(), safeSq:getZ()))
end

---@param deltaMs integer
function EffectTeleportFromZombies:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    local px, py, pz = player:getX(), player:getY(), player:getZ()

    local nearby = ChaosZombie.GetNearestZombies(px, py, DANGER_RADIUS, false, pz)
    if nearby:size() == 0 then return end

    tryTeleportPlayerAwayFromZombies(player)
end

function EffectTeleportFromZombies:OnEnd()
    ChaosEffectBase:OnEnd()
end
