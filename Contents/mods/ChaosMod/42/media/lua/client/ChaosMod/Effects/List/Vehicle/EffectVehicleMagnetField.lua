---@class EffectVehicleMagnetField : ChaosEffectBase
---@field innerRadius number
---@field totalRadius number
EffectVehicleMagnetField = ChaosEffectBase:derive("EffectVehicleMagnetField", "vehicle_magnet_field")

local INNER_RADIUS       = 5.0
local TOTAL_RADIUS       = 50.0
local STRENGTH           = 100000 * 2.0

function EffectVehicleMagnetField:OnStart()
    ChaosEffectBase:OnStart()

    self.innerRadius = INNER_RADIUS
    self.totalRadius = TOTAL_RADIUS

    local player = getPlayer()
    if not player then return end
    ChaosVehicle.ExitVehicle(player)
end

---@param deltaMs integer
function EffectVehicleMagnetField:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = player:getX()
    local py = player:getY()
    local pz = player:getZ()

    local vehicles = ChaosVehicle.GetVehiclesNearby(square, self.totalRadius)

    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            local vx = vehicle:getX()
            local vy = vehicle:getY()

            local dx = px - vx
            local dy = py - vy
            -- local dz = pz - vehicle:getY() -- physics Y (height) for vehicle, world Z for player
            local dist = math.sqrt(dx * dx + dy * dy)

            print("dist: " .. tostring(dist))

            if dist > 0 then
                local nx = dx / dist
                local ny = dy / dist
                -- local nz = dz / dist

                print("nx: " .. tostring(nx) .. ", ny: " .. tostring(ny))

                local direction = (dist <= self.innerRadius) and -1.0 or 1.0

                vehicle:setPhysicsActive(true)

                local impulse = Vector3f.new(nx * STRENGTH * direction, 0,
                    ny * STRENGTH * direction)
                local relPos  = Vector3f.new(0, 0, 0)

                print("impulse: " ..
                    tostring(impulse:x()) .. ", " .. tostring(impulse:y()) .. ", " .. tostring(impulse:z()))
                vehicle:addImpulse(impulse, relPos)
            end
        end
    end
end

function EffectVehicleMagnetField:OnEnd()
    ChaosEffectBase:OnEnd()
end
