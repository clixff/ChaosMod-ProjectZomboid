EffectPlayerHasVehicleKeys = ChaosEffectBase:derive("EffectPlayerHasVehicleKeys", "player_has_vehicle_keys")
---@param character IsoGameCharacter
local function onEnterVehicle(character)
    if not character then return end

    local player = getPlayer()
    if not player then return end

    if player ~= character then
        print("[EffectPlayerHasVehicleKeys] Player is not the same as character")
        return
    end

    local vehicle = character:getVehicle()

    if not vehicle then
        print("[EffectPlayerHasVehicleKeys] No vehicle found")
        return
    end

    local newKey = vehicle:createVehicleKey()

    if not newKey then
        print("[EffectPlayerHasVehicleKeys] No new key found")
        return
    end

    local inventory = player:getInventory()
    if not inventory then
        print("[EffectPlayerHasVehicleKeys] No inventory found")
        return
    end

    inventory:AddItem(newKey)
end

function EffectPlayerHasVehicleKeys:OnStart()
    ChaosEffectBase:OnStart()
    Events.OnEnterVehicle.Add(onEnterVehicle)
end

function EffectPlayerHasVehicleKeys:OnEnd()
    ChaosEffectBase:OnEnd()
    Events.OnEnterVehicle.Remove(onEnterVehicle)
end
