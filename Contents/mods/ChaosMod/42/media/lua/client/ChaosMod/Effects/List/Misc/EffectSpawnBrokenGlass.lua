---@class EffectSpawnBrokenGlass : ChaosEffectBase
EffectSpawnBrokenGlass = ChaosEffectBase:derive("EffectSpawnBrokenGlass", "spawn_broken_glass")

local MIN_RADIUS = 3
local MAX_RADIUS = 30
local SPAWN_CHANCE = 30

function EffectSpawnBrokenGlass:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()
    local spawned = 0

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if sq and not sq:getBrokenGlass() and ZombRand(100) < SPAWN_CHANCE then
            sq:addBrokenGlass()
            spawned = spawned + 1
        end
    end, MIN_RADIUS, MAX_RADIUS, true, false, true, pz, pz)

    print("[EffectSpawnBrokenGlass] Spawned broken glass on " .. tostring(spawned) .. " squares")
end
