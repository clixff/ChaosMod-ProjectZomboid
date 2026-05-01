EffectDisableLightsNearby = ChaosEffectBase:derive("EffectDisableLightsNearby", "disable_lights_nearby")

---@param square IsoGridSquare
---@return IsoLightSwitch | nil
local function getLightSwitchOnSquare(square)
    if not square then return nil end
    ---@type IsoLightSwitch | nil
    local lightSwitch = nil
    ChaosUtils.ForAllObjectsInSquare(square, function(obj)
        if instanceof(obj, "IsoLightSwitch") then
            lightSwitch = obj
            return true
        end
    end)
    return lightSwitch
end

function EffectDisableLightsNearby:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local radius = 40
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local cell = getCell()
    local countDisabled = 0


    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            local lightSwitch = getLightSwitchOnSquare(sq)
            if lightSwitch and lightSwitch:isActivated() then
                lightSwitch:setActive(false)
                countDisabled = countDisabled + 1
            end
        end
    end, 0, radius, false, false, true, z - 1, z + 2)


    print("[EffectDisableLightsNearby] Disabled " .. tostring(countDisabled) .. " lights")
end
