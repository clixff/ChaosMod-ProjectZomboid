---@class EffectJumpingCars : ChaosEffectBase
---@field timerMs integer
EffectJumpingCars = ChaosEffectBase:derive("EffectJumpingCars", "jumping_cars")

local TIMEOUT_MS = 1500

function EffectJumpingCars:OnStart()
    ChaosEffectBase:OnStart()

    self.timerMs = TIMEOUT_MS
end

---@param deltaMs integer
function EffectJumpingCars:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local activate = false
    self.timerMs = self.timerMs + deltaMs
    if self.timerMs >= TIMEOUT_MS then
        self.timerMs = 0
        activate = true
    end

    local player = getPlayer()
    if not player then return end

    local playerVehicle = player:getVehicle()

    local vehicles = ChaosVehicle.GetVehiclesNearby(player:getSquare(), 40)

    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            vehicle:setPhysicsActive(true)
            if activate then
                local strength = 100000 * 150.0

                local impulse  = Vector3f.new(0, strength, 0)
                local relPos   = Vector3f.new(0, 0, 0)

                vehicle:addImpulse(impulse, relPos)
            end
        end
    end
end

function EffectJumpingCars:OnEnd()
    ChaosEffectBase:OnEnd()
end
