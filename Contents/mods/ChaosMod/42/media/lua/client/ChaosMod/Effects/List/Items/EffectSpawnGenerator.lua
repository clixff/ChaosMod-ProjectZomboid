EffectSpawnGenerator = ChaosEffectBase:derive("EffectSpawnGenerator", "spawn_generator")

function EffectSpawnGenerator:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnGenerator] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    square:AddWorldInventoryItem("Base.Generator", 0.5, 0.5, 0.0)
end
