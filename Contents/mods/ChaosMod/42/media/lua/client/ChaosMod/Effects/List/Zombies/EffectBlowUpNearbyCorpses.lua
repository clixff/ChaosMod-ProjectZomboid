EffectBlowUpNearbyCorpses = ChaosEffectBase:derive("EffectBlowUpNearbyCorpses", "blow_up_nearby_corpses")

local SEARCH_RADIUS = 60

function EffectBlowUpNearbyCorpses:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    local minZ = z - 1
    local maxZ = z + 2

    local squaresToExplode = {}
    local seenSquares = {}

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if not sq then
            return false
        end

        local objects = sq:getStaticMovingObjects()
        if not objects then
            return false
        end

        for i = 0, objects:size() - 1 do
            local obj = objects:get(i)
            if instanceof(obj, "IsoDeadBody") then
                local key = string.format("%d:%d:%d", sq:getX(), sq:getY(), sq:getZ())
                if not seenSquares[key] then
                    seenSquares[key] = true
                    table.insert(squaresToExplode, sq)
                end
                break
            end
        end

        return false
    end, 0, SEARCH_RADIUS, false, false, true, minZ, maxZ)

    for _, corpseSquare in ipairs(squaresToExplode) do
        ChaosUtils.TriggerExplosionAt(corpseSquare)
    end

    print("[EffectBlowUpNearbyCorpses] Exploded corpse squares: " .. tostring(#squaresToExplode))
end
