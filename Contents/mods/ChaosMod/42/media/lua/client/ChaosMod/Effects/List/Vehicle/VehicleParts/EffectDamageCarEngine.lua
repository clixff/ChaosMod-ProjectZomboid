EffectDamageCarEngine = ChaosEffectBase:derive("EffectDamageCarEngine", "damage_car_engine")

function EffectDamageCarEngine:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectDamageCarEngine] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local vehicle = ChaosUtils.GetPlayerVehicleOrLastUsedVehicle(player)
    if not vehicle then return end

    ---@type VehiclePart
    local part = vehicle:getPartById("Engine")

    if part then
        part:damage(35)
        vehicle:transmitEngine()
    end

    vehicle:updatePartStats()
end
