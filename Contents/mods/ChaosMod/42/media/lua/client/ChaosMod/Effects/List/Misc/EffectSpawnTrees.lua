---@class EffectSpawnTrees : ChaosEffectBase
EffectSpawnTrees = ChaosEffectBase:derive("EffectSpawnTrees", "spawn_trees")

local MIN_RADIUS = 3
local MAX_RADIUS = 12
local TREE_SPRITE = "e_americanlinden_1_3"
local TREE_SPAWN_CHANCE = 45

function EffectSpawnTrees:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local cell = getCell()
    if not cell then return end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()
    local spawned = 0

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if sq then
            if ZombRand(100) < TREE_SPAWN_CHANCE then
                local tree = IsoTree.new(sq, TREE_SPRITE)
                tree:addAttachedAnimSpriteByName("e_americanlinden_1_11")
                if tree then
                    tree:setSquare(sq)
                    tree:addToWorld()
                    sq:AddTileObject(tree)
                    spawned = spawned + 1
                end
            end
        end
    end, MIN_RADIUS, MAX_RADIUS, true, false, true, pz, pz)

    print("[EffectSpawnTrees] Spawned " .. tostring(spawned) .. " trees")
end
