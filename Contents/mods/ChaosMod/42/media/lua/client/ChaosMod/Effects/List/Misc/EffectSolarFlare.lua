---@class EffectSolarFlare : ChaosEffectBase
EffectSolarFlare = ChaosEffectBase:derive("EffectSolarFlare", "solar_flare")

local FILTER_DURATION_MS = 7000
local ZOMBIE_FIRE_RADIUS = 50
local LIGHTS_RADIUS = 90
local VEHICLE_RADIUS = 60

local function ApplyFilter()
    local cm = ClimateManager.getInstance()
    if not cm then return end

    local globalLight = cm:getClimateColor(ClimateManager.COLOR_GLOBAL_LIGHT)
    if not globalLight then return end

    globalLight:setEnableOverride(true)
    local colorInfo = ClimateColorInfo.new()
    colorInfo:setExterior(0.12, 0.45, 1.0, 1.0)
    colorInfo:setInterior(0.12, 0.45, 1.0, 1.0)
    globalLight:setOverride(colorInfo, 1.0)

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_AMBIENT, true, 1.0)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_DAYLIGHT_STRENGTH, true, 1.0)
end

local function DisableFilter()
    local cm = ClimateManager.getInstance()
    if not cm then return end

    local globalLight = cm:getClimateColor(ClimateManager.COLOR_GLOBAL_LIGHT)
    if globalLight then
        globalLight:setEnableOverride(false)
    end

    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_AMBIENT, false, 0.0)
    ChaosUtils.SetClimateFloatOverride(cm, ClimateManager.FLOAT_DAYLIGHT_STRENGTH, false, 0.0)
end

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

---@param deltaMs integer
---@param data { px: integer, py: integer, pz: integer }
local function SolarFlareTick(deltaMs, data)
    ApplyFilter()
end

---@param data { px: integer, py: integer, pz: integer }
local function SolarFlareEnd(data)
    DisableFilter()

    ChaosZombie.ForEachZombieInRange(data.px, data.py, ZOMBIE_FIRE_RADIUS, function(zombie)
        if zombie and zombie:isAlive() then
            zombie:setOnFire(true)
        end
    end, true, nil)

    ChaosUtils.SquareRingSearchTile_2D(data.px, data.py, function(sq)
        if sq then
            local lightSwitch = getLightSwitchOnSquare(sq)
            if lightSwitch and lightSwitch:isActivated() then
                lightSwitch:setActive(false)
            end
        end
    end, 0, LIGHTS_RADIUS, false, false, true, data.pz - 1, data.pz + 2)

    local player = getPlayer()
    if player then
        local sq = player:getSquare()
        if sq then
            local vehicles = ChaosVehicle.GetVehiclesNearby(sq, VEHICLE_RADIUS)
            for i = 0, vehicles:size() - 1 do
                local vehicle = vehicles:get(i)
                if vehicle then
                    vehicle:setAlarmed(true)
                    vehicle:triggerAlarm()
                end
            end
        end
    end
end

---@param data { px: integer, py: integer, pz: integer }
local function SolarFlareCancel(data)
    DisableFilter()
end

function EffectSolarFlare:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local sq = player:getSquare()
    if not sq then return end

    ApplyFilter()

    ChaosSpecialAction.AddNewAction(
        { px = sq:getX(), py = sq:getY(), pz = sq:getZ() },
        FILTER_DURATION_MS,
        SolarFlareTick,
        SolarFlareEnd,
        SolarFlareCancel
    )
end

function EffectSolarFlare:OnEnd()
    ChaosEffectBase:OnEnd()
end
