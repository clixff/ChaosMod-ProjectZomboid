EffectPlayerCantExitCar = ChaosEffectBase:derive("EffectPlayerCantExitCar", "player_cant_exit_car")

local orig_ISVehicleMenu_onExit = nil

function EffectPlayerCantExitCar:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectPlayerCantExitCar] OnStart " .. tostring(self.effectId))

    orig_ISVehicleMenu_onExit = ISVehicleMenu.onExit

    ISVehicleMenu.onExit = function(playerObj, seatFrom)
        return
    end
end

function EffectPlayerCantExitCar:OnEnd()
    ChaosEffectBase:OnEnd()
    print("[EffectPlayerCantExitCar] OnEnd " .. tostring(self.effectId))

    if orig_ISVehicleMenu_onExit then
        ISVehicleMenu.onExit = orig_ISVehicleMenu_onExit
        orig_ISVehicleMenu_onExit = nil
    end
end
