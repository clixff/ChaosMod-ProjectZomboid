EffectSpawnRandomTire = ChaosEffectBase:derive("EffectSpawnRandomTire", "spawn_random_tire")

local items = {
    "Base.NormalTire1",
    "Base.NormalTire2",
    "Base.NormalTire3",
    "Base.ModernTire1",
    "Base.ModernTire2",
    "Base.ModernTire3",
    "Base.OldTire1",
    "Base.OldTire2",
    "Base.OldTire3"
}

function EffectSpawnRandomTire:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnRandomTire] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local randomIndex = math.floor(ZombRand(1, #items + 1))
    local randomItemId = items[randomIndex]
    if not randomItemId then return end

    square:AddWorldInventoryItem(randomItemId, 0.5, 0.5, 0.0)
end
