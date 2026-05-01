EffectEnableNearbyTVs = ChaosEffectBase:derive("EffectEnableNearbyTVs", "enable_nearby_tvs")

local function enableTV(obj)
    if not obj or not instanceof(obj, "IsoTelevision") then
        return false
    end
    local data = obj:getDeviceData()
    if not data then
        return false
    end
    data:setIsTurnedOn(true)
    return data:getIsTurnedOn()
end

function EffectEnableNearbyTVs:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local radius = 40
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local cell = getCell()
    local countEnabled = 0

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
                if enableTV(obj) then
                    countEnabled = countEnabled + 1
                end
            end)
        end
    end, 0, radius, false, false, true, z - 1, z + 2)

    print("[EffectEnableNearbyTVs] Enabled " .. tostring(countEnabled) .. " TVs")
end
