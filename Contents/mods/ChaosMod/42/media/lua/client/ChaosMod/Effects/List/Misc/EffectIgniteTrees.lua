---@class EffectIgniteTrees : ChaosEffectBase
EffectIgniteTrees = ChaosEffectBase:derive("EffectIgniteTrees", "ignite_trees")

local SEARCH_RANGE = 30
local PLAYER_SECURE_RADIUS = 3.0
local IGNITE_CHANCE = 0.33

function EffectIgniteTrees:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()
    local cell = getCell()

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return end
        if not sq:getTree() then return end
        if ChaosUtils.isInRange(sq:getX(), sq:getY(), px, py, PLAYER_SECURE_RADIUS) then return end

        if ChaosUtils.RandFloat(0, 1) <= IGNITE_CHANCE then
            IsoFireManager.StartFire(cell, sq, true, 100, 3000)
        end
    end, 0, SEARCH_RANGE, false, false, true, 0, 0)
end

function EffectIgniteTrees:OnEnd()
    ChaosEffectBase:OnEnd()
end
