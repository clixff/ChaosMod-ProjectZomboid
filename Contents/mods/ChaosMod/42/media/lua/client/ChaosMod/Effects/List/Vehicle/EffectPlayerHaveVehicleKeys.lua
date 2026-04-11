EffectPlayerHaveVehicleKeys = ChaosEffectBase:derive("EffectPlayerHaveVehicleKeys", "player_have_vehicle_keys")
---@param character IsoGameCharacter
local function onEnterVehicle(character)
    if not character then return end

    local player = getPlayer()
    if not player then return end

    if player ~= character then
        print("[EffectPlayerHaveVehicleKeys] Player is not the same as character")
        return
    end

    local vehicle = character:getVehicle()

    if not vehicle then
        print("[EffectPlayerHaveVehicleKeys] No vehicle found")
        return
    end

    local newKey = vehicle:createVehicleKey()

    if not newKey then
        print("[EffectPlayerHaveVehicleKeys] No new key found")
        return
    end

    local inventory = player:getInventory()
    if not inventory then
        print("[EffectPlayerHaveVehicleKeys] No inventory found")
        return
    end

    inventory:AddItem(newKey)
end

function EffectPlayerHaveVehicleKeys:OnStart()
    ChaosEffectBase:OnStart()
    Events.OnEnterVehicle.Add(onEnterVehicle)
end

function EffectPlayerHaveVehicleKeys:OnEnd()
    ChaosEffectBase:OnEnd()
    Events.OnEnterVehicle.Remove(onEnterVehicle)
end
