EffectEnableLightsNearby = ChaosEffectBase:derive("EffectEnableLightsNearby", "enable_lights_nearby")

---@param square IsoGridSquare
---@return IsoLightSwitch | nil
local function getLightSwitchOnSquare(square)
    if not square then return nil end
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        local obj = objects:get(i)
        if instanceof(obj, "IsoLightSwitch") then
            return obj
        end
    end
    return nil
end

function EffectEnableLightsNearby:OnStart()
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
                    local lightSwitch = getLightSwitchOnSquare(sq)
                    if lightSwitch and not lightSwitch:isActivated() then
                        lightSwitch:setActive(true)
                        countEnabled = countEnabled + 1
                    end
                end
            end
        end
    end

    print("[EffectEnableLightsNearby] Enabled " .. tostring(countEnabled) .. " lights")
end
