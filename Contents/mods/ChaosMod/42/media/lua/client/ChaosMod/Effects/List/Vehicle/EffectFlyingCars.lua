---@class EffectFlyingCars : ChaosEffectBase
---@field timerMs integer
---@field backward boolean
---@field playerWasInGodMode boolean
EffectFlyingCars = ChaosEffectBase:derive("EffectFlyingCars", "flying_cars")

local TIMEOUT_MS = 5000

function EffectFlyingCars:OnStart()
    ChaosEffectBase:OnStart()

    self.timerMs = TIMEOUT_MS
    self.backward = false
    self.playerWasInGodMode = false
    local player = getPlayer()
    if player and player:getVehicle() then
        self.playerWasInGodMode = player:isGodMod()
        player:setGodMod(true, true)
    end
end

---@param deltaMs integer
function EffectFlyingCars:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local activate = false
    self.timerMs = self.timerMs + deltaMs
    if self.timerMs >= TIMEOUT_MS then
        self.timerMs = 0
        activate = true
        self.backward = not self.backward
    end


    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()

    if activate then
        local veh = ChaosVehicle.spawnVehicleNearPlayer(ChaosVehicle.GetRandomVehicleName(), 20, 50, false, false)
        if veh then
            ChaosVehicle.SetRandomVehicleColors(veh)
        end
    end

    local playerVehicle = player:getVehicle()


    local vehicles = ChaosVehicle.GetVehiclesNearby(player:getSquare(), 40)

    for i = 0, vehicles:size() - 1 do
        local vehicle = vehicles:get(i)
        if vehicle then
            vehicle:setPhysicsActive(true)
            local forward = Vector3f.new(0, 0, 0)
            vehicle:getForwardVector(forward)

            local strength = 200000.0 * 5
            if self.backward then
                strength = strength * -1
            end

            if vehicle == playerVehicle then
                strength = strength * 0.5
            end

            local impulse = Vector3f.new(forward:x() * strength, forward:y() * strength, forward:z() * strength)
            local relPos  = Vector3f.new(0, 0, 0)

            local x       = impulse:x()
            local y       = impulse:y()
            local z       = impulse:z()


            vehicle:addImpulse(impulse, relPos)
        end
    end
end

function EffectFlyingCars:OnEnd()
    ChaosEffectBase:OnEnd()
    local player = getPlayer()
    if player and player:getVehicle() then
        player:setGodMod(self.playerWasInGodMode, true)
    end
end
