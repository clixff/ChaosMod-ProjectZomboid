---@class EffectSpawnTrees : ChaosEffectBase
EffectSpawnTrees = ChaosEffectBase:derive("EffectSpawnTrees", "spawn_trees")

local MIN_RADIUS = 3
local MAX_RADIUS = 12
local TREE_SPRITE = "e_americanlinden_1_3"
local TREE_SPAWN_CHANCE = 35

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

    for dx = -MAX_RADIUS, MAX_RADIUS do
        for dy = -MAX_RADIUS, MAX_RADIUS do
            local x = px + dx
            local y = py + dy
            local isInMaxRadius = ChaosUtils.isInRange(px, py, x, y, MAX_RADIUS)
            local isOutsideMinRadius = not ChaosUtils.isInRange(px, py, x, y, MIN_RADIUS)

            if isInMaxRadius and isOutsideMinRadius and ZombRand(100) < TREE_SPAWN_CHANCE then
                local sq = cell:getGridSquare(x, y, pz)
                if sq and sq:isSolidFloor() and sq:isFree(false) then
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
        end
    end

    print("[EffectSpawnTrees] Spawned " .. tostring(spawned) .. " trees")
end
