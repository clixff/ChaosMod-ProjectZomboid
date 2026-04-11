EffectDisableVehicleEngine = ChaosEffectBase:derive("EffectDisableVehicleEngine", "disable_vehicle_engine")

function EffectDisableVehicleEngine:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectDisableVehicleEngine] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end
end

function EffectDisableVehicleEngine:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local vehicle = ChaosUtils.GetPlayerVehicleOrLastUsedVehicle(player)
    if not vehicle then return end

    if vehicle:isEngineRunning() then
        vehicle:shutOff()
    end
end
