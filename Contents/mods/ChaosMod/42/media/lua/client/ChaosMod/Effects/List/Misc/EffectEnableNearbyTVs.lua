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

    for dz = -1, 2 do
        for dx = -radius, radius do
            for dy = -radius, radius do
                local sq = cell:getGridSquare(x + dx, y + dy, z + dz)
                if sq then
                    local objects = sq:getObjects()
                    for i = 0, objects:size() - 1 do
                        if enableTV(objects:get(i)) then
                            countEnabled = countEnabled + 1
                        end
                    end
                end
            end
        end
    end

    print("[EffectEnableNearbyTVs] Enabled " .. tostring(countEnabled) .. " TVs")
end
