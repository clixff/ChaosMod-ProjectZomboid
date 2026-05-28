---@class EffectFillGroundWithRandomItems : ChaosEffectBase
EffectFillGroundWithRandomItems = ChaosEffectBase:derive("EffectFillGroundWithRandomItems",
    "fill_ground_with_random_items")

local RANGE = 8

function EffectFillGroundWithRandomItems:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px, py, pz = square:getX(), square:getY(), square:getZ()

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return end

        local itemId = ChaosItems.GetRandomItemId()
        if not itemId then return end

        local offX = ChaosUtils.RandFloat(0.15, 0.85)
        local offY = ChaosUtils.RandFloat(0.15, 0.85)
        sq:AddWorldInventoryItem(itemId, offX, offY, 0.0)
    end, 0, RANGE, false, false, true, pz, pz)
end

function EffectFillGroundWithRandomItems:OnEnd()
    ChaosEffectBase:OnEnd()
end
