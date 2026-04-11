---@class EffectSpinningVehicles : ChaosEffectBase
EffectSpinningVehicles = ChaosEffectBase:derive("EffectSpinningVehicles", "spinning_vehicles")

local yawSpeedDeg = 360.0 * 2.0
---@type table<integer, {x: number, y: number, z: number}>
local vehicleAngle = {}

function EffectSpinningVehicles:OnStart()
    ChaosEffectBase:OnStart()
    self.vehiclesList = {}
    print("[EffectSpinningVehicles] OnStart" .. tostring(self.effectId))
end

---@param deltaMs integer
function EffectSpinningVehicles:OnTick(deltaMs)
    local deltaSec = deltaMs / 1000.0
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, 50)

    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        local id = vehicle:getId()
        if vehicle then
            vehicle:setPhysicsActive(true)
            local vehData = vehicleAngle[id]
            if vehData == nil then
                vehicle:setPhysicsActive(true)
                vehicleAngle[id] = {
                    x = vehicle:getAngleX(),
                    y = vehicle:getAngleY(),
                    z = vehicle:getAngleZ()
                }
                vehData = vehicleAngle[id]
            end

            local ax = vehData.x
            local ay = vehData.y
            local az = vehData.z

            ay = ay + yawSpeedDeg * deltaSec

            vehicleAngle[id].y = ay

            print("New angle to add: " .. tostring(yawSpeedDeg * deltaSec))

            print("Set vehicle angle: " .. tostring(ax) .. ", " .. tostring(ay) .. ", " .. tostring(az))
            ---@diagnostic disable-next-line: param-type-mismatch
            vehicle:setAngles(ax, ay, az)
        end
    end
end

function EffectSpinningVehicles:OnEnd()
    ChaosEffectBase:OnEnd()

    for id, _ in pairs(vehicleAngle) do
        local vehicle = getVehicleById(id)
        if vehicle then
            -- vehicle:setPhysicsActive(false)
        end
    end
    vehicleAngle = {}
end
