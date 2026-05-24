---@class EffectSpinPlayer : ChaosEffectBase
---@field heading number
---@field vehicleAngle table<integer, {x: number, y: number, z: number}>
EffectSpinPlayer = ChaosEffectBase:derive("EffectSpinPlayer", "spin_player")

local yawSpeedDeg = 360.0 * 2.0

function EffectSpinPlayer:OnStart()
    ChaosEffectBase:OnStart()
    self.heading = 0.0
    self.vehicleAngle = {}
end

---@param deltaMs integer
function EffectSpinPlayer:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    local deltaSec = deltaMs / 1000.0
    local vehicle = player:getVehicle()

    if vehicle then
        vehicle:setPhysicsActive(true)
        local id = vehicle:getId()
        local vehData = self.vehicleAngle[id]
        if vehData == nil then
            vehData = {
                x = vehicle:getAngleX(),
                y = vehicle:getAngleY(),
                z = vehicle:getAngleZ()
            }
            self.vehicleAngle[id] = vehData
        end

        vehData.y = vehData.y + yawSpeedDeg * deltaSec

        ---@diagnostic disable-next-line: param-type-mismatch
        vehicle:setAngles(vehData.x, vehData.y, vehData.z)
    else
        self.heading = (self.heading + yawSpeedDeg * deltaSec) % 360.0
        local rad = math.rad(self.heading)
        local fx = math.cos(rad)
        local fy = math.sin(rad)
        player:setForwardDirection(fx, fy)
    end
end

function EffectSpinPlayer:OnEnd()
    ChaosEffectBase:OnEnd()
    self.vehicleAngle = {}
end
