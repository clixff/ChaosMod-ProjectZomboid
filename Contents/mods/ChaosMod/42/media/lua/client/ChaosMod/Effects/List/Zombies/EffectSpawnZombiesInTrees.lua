---@class EffectSpawnZombiesInTrees : ChaosEffectBase
EffectSpawnZombiesInTrees = ChaosEffectBase:derive("EffectSpawnZombiesInTrees", "spawn_zombies_in_trees")

local SEARCH_RANGE = 20
local MIN_DIST_TO_PLAYER = 6
local MAX_ZOMBIES = 5
local MIN_DIST_BETWEEN_SPAWNS = 5

function EffectSpawnZombiesInTrees:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()

    ---@type IsoGridSquare[]
    local treeSquares = {}

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return end
        if sq:getTree() then
            table.insert(treeSquares, sq)
        end
    end, MIN_DIST_TO_PLAYER, SEARCH_RANGE, false, false, true, pz, pz)

    ---@type IsoGridSquare[]
    local spawnSquares = {}
    local spawned = 0

    for _, sq in ipairs(treeSquares) do
        if spawned >= MAX_ZOMBIES then break end

        local sx = sq:getX()
        local sy = sq:getY()

        local tooClose = false
        for _, used in ipairs(spawnSquares) do
            if ChaosUtils.isInRange(sx, sy, used:getX(), used:getY(), MIN_DIST_BETWEEN_SPAWNS) then
                tooClose = true
                break
            end
        end

        if not tooClose then
            local zombies = ChaosZombie.SpawnZombieAt(sx, sy, sq:getZ(), 1, "Tourist")
            local zombie = zombies and zombies:getFirst() or nil
            if zombie then
                zombie:dressInRandomOutfit()
                ChaosZombie.MoveToSound(zombie, px, py, pz)
                table.insert(spawnSquares, sq)
                spawned = spawned + 1
            end
        end
    end
end

function EffectSpawnZombiesInTrees:OnEnd()
    ChaosEffectBase:OnEnd()
end
