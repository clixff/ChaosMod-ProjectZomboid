---@class EffectFlyingCars : ChaosEffectBase
---@field timerMs integer
---@field backward boolean
---@field playerWasInGodMode boolean
---@field playerWasInVehicle boolean
---@field playerDamageCooldownMs integer
EffectFlyingCars = ChaosEffectBase:derive("EffectFlyingCars", "flying_cars")

local TIMEOUT_MS = 5000
local PLAYER_DAMAGE_COOLDOWN_MS = 1000

function EffectFlyingCars:OnStart()
    ChaosEffectBase:OnStart()

    self.timerMs = TIMEOUT_MS
    self.backward = false
    self.playerWasInGodMode = false
    self.playerWasInVehicle = false
    self.playerDamageCooldownMs = 0
    local player = getPlayer()
    if player and player:getVehicle() then
        self.playerWasInGodMode = player:isGodMod()
        player:setGodMod(true, true)
        self.playerWasInVehicle = true
    end
end

---@param vehicle BaseVehicle
---@param player IsoPlayer
---@return boolean
local function hitPlayerByVehicle(vehicle, player)
    if not vehicle or not player then return false end

    local impactPos = Vector2.new()
    local hit = vehicle:testCollisionWithCharacter(player, 0.3, impactPos)
    if not hit then
        return false
    end

    local hitDir = Vector2.new(player:getX() - vehicle:getX(), player:getY() - vehicle:getY())
    if hitDir:getLength() > 0.001 then
        hitDir:normalize()
    else
        hitDir:set(0, 1)
    end

    local impactSpeed = math.abs(vehicle:getCurrentSpeedKmHour()) / 5.0
    local impactSpeed_1 = impactSpeed
    if impactSpeed < 4.0 then
        impactSpeed = 4.0
    end

    player:onHitByVehicle(vehicle, impactSpeed, hitDir, impactPos, true)


    -- SP bug workaround: force actual damage yourself
    local damage = impactSpeed * 0.5

    print("hitPlayerByVehicle: " .. tostring(impactSpeed) .. " -> " .. tostring(impactSpeed_1) .. " " .. tostring(damage))


    player:getBodyDamage():ReduceGeneralHealth(damage)
    player:setKnockedDown(true)

    return true
end

---@param deltaMs integer
function EffectFlyingCars:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    self.playerDamageCooldownMs = math.max(0, self.playerDamageCooldownMs - deltaMs)

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
        local veh = ChaosVehicle.spawnVehicleNearPlayer(ChaosVehicle.GetRandomVehicleName(), 10, 50, false, false)
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

            if self.playerDamageCooldownMs <= 0 and hitPlayerByVehicle(vehicle, player) then
                self.playerDamageCooldownMs = PLAYER_DAMAGE_COOLDOWN_MS
            end
        end
    end

    if self.playerWasInVehicle then
        if player:getVehicle() == nil then
            self.playerWasInVehicle = false
            player:setGodMod(self.playerWasInGodMode, true)
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
