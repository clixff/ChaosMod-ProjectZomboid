EffectEnableStovesNearby = ChaosEffectBase:derive("EffectEnableStovesNearby", "enable_stoves_nearby")

local function enableStove(obj)
    if not obj or not instanceof(obj, "IsoStove") then
        return false
    end
    if not obj:Activated() then
        obj:Toggle()
    end
    return obj:Activated()
end

function EffectEnableStovesNearby:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local radius = 40
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local cell = getCell()
    local countEnabled = 0

    local Z = square:getZ()

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            local objects = sq:getObjects()
            for i = 0, objects:size() - 1 do
                if enableStove(objects:get(i)) then
                    countEnabled = countEnabled + 1
                end
            end
        end
    end, 0, radius, false, false, true, Z - 1, Z + 2)

    print("[EffectEnableStovesNearby] Enabled " .. tostring(countEnabled) .. " stoves")
end
