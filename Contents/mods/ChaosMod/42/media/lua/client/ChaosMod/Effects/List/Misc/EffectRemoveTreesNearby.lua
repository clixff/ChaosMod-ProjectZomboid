---@class EffectRemoveTreesNearby : ChaosEffectBase
EffectRemoveTreesNearby = ChaosEffectBase:derive("EffectRemoveTreesNearby", "remove_trees_nearby")

local RANGE = 60

function EffectRemoveTreesNearby:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemoveTreesNearby] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()
    local removed = 0

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return end

        local tree = sq:getTree()
        if tree then
            tree:removeFromWorld()
            tree:removeFromSquare()
            -- tree:toppleTree()
            removed = removed + 1
        end
    end, 0, RANGE, false, false, true, pz, pz)

    print("[EffectRemoveTreesNearby] Removed " .. tostring(removed) .. " trees")
end
