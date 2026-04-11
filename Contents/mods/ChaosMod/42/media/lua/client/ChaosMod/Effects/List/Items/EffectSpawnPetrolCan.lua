EffectSpawnPetrolCan = ChaosEffectBase:derive("EffectSpawnPetrolCan", "spawn_petrol_can")

function EffectSpawnPetrolCan:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnPetrolCan] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    square:AddWorldInventoryItem("Base.PetrolCan", 0.5, 0.5, 0.0)
end
