EffectSpawnBarricadeKit = ChaosEffectBase:derive("EffectSpawnBarricadeKit", "spawn_barricade_kit")

function EffectSpawnBarricadeKit:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    print("[EffectSpawnBarricadeKit] OnStart " .. tostring(self.effectId))

    local itemsToSpawn = {
        { "Base.Hammer", 1 },
        { "Base.Plank",  3 },
        { "Base.Nails",  3 },
    }

    local sq = player:getSquare()
    if not sq then return end

    for _, item in ipairs(itemsToSpawn) do
        local itemName = item[1]
        local itemCount = item[2]

        for i = 1, itemCount do
            -- Offsets are 0..1 within the tile
            local ox = ZombRandFloat(0.15, 0.85)
            local oy = ZombRandFloat(0.15, 0.85)
            local oz = 0

            -- Spawn the item on the ground
            sq:AddWorldInventoryItem(itemName, ox, oy, oz)
        end
    end
end
