---@class EffectExplodeNearbyElectronics : ChaosEffectBase
EffectExplodeNearbyElectronics = ChaosEffectBase:derive("EffectExplodeNearbyElectronics", "explode_nearby_electronics")

local RADIUS = 40
local EXPLOSION_RADIUS = 2
local EXPLODE_CHANCE = 90
local BATTERY_DAMAGE = 85
local MAX_DURATION = 2500

---@param data { entries: { square: IsoGridSquare, objects: IsoObject[] }[], vehicles: BaseVehicle[] }
local function ExplodeElectronics(data)
    local entries = data.entries or {}
    local vehicles = data.vehicles or {}

    local player = getPlayer()
    local px, py = 0.0, 0.0
    if player then
        px, py = player:getX(), player:getY()
    end

    ---@type { square: IsoGridSquare, objects: IsoObject[] }[]
    local toExplode = {}
    for i = 1, #entries do
        local entry = entries[i]
        if entry and entry.square and ChaosUtils.RandFloat(0, 100) < EXPLODE_CHANCE then
            toExplode[#toExplode + 1] = entry
        end
    end

    local nearestIdx = 0
    if player and #toExplode > 0 then
        local nearestDist = math.huge
        for i = 1, #toExplode do
            local sq = toExplode[i].square
            local d = ChaosUtils.distTo(px, py, sq:getX(), sq:getY())
            if d < nearestDist then
                nearestDist = d
                nearestIdx = i
            end
        end
    end

    for i = 1, #toExplode do
        local entry = toExplode[i]
        local objects = entry.objects or {}
        for j = 1, #objects do
            local obj = objects[j]
            if obj then
                pcall(function() obj:removeFromWorld() end)
                pcall(function() obj:removeFromSquare() end)
            end
        end
        ChaosUtils.TriggerExplosionAt(entry.square, EXPLOSION_RADIUS, true, i ~= nearestIdx)
    end

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        if vehicle then
            local vsq = vehicle:getSquare()
            if vsq then
                vsq:playSound("car/tire_explode")
            end
            local batteryPart = vehicle:getPartById("Battery")
            if batteryPart then
                batteryPart:damage(BATTERY_DAMAGE)
                vehicle:transmitPartItem(batteryPart)
            end
            vehicle:updatePartStats()
        end
    end

    print("[EffectExplodeNearbyElectronics] " .. tostring(#toExplode) .. " squares exploded, " ..
        tostring(#vehicles) .. " cars affected")
end

---@param deltaMs integer
---@param data { elapsedMs: integer }
local function ExplodeElectronicsTick(deltaMs, data)
    local bar = UIManager.getProgressBar(0)
    data.elapsedMs = data.elapsedMs + deltaMs
    local progress = data.elapsedMs / MAX_DURATION
    bar:setValue(progress)
end

function EffectExplodeNearbyElectronics:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local px, py, pz = playerSquare:getX(), playerSquare:getY(), playerSquare:getZ()

    ---@type { square: IsoGridSquare, objects: IsoObject[] }[]
    local entries = {}

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return end

        ---@type IsoObject[]
        local electronics = {}

        ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
            local kind = ChaosProps.GetElectronicKind(obj)
            if kind and kind ~= "light_switch" then
                electronics[#electronics + 1] = obj
            end
        end)

        if #electronics > 0 then
            entries[#entries + 1] = { square = sq, objects = electronics }
        end
    end, 0, RADIUS, false, false, true, -1, pz + 2)

    ---@type BaseVehicle[]
    local vehicles = {}
    local nearbyVehicles = ChaosVehicle.GetVehiclesNearby(playerSquare, RADIUS)
    if nearbyVehicles then
        for i = 0, nearbyVehicles:size() - 1 do
            local v = nearbyVehicles:get(i)
            if v then
                vehicles[#vehicles + 1] = v
            end
        end
    end

    ChaosSpecialAction.AddNewAction(
        { entries = entries, vehicles = vehicles, elapsedMs = 0 },
        MAX_DURATION, ExplodeElectronicsTick, ExplodeElectronics, nil)
end

function EffectExplodeNearbyElectronics:OnEnd()
    ChaosEffectBase:OnEnd()
end
