EffectSpawnPackOfBeerCans = ChaosEffectBase:derive("EffectSpawnPackOfBeerCans", "spawn_pack_of_beer_cans")

function EffectSpawnPackOfBeerCans:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnPackOfBeerCans] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    square:AddWorldInventoryItem("Base.BeerCanPack", 0.5, 0.5, 0.0)
end
