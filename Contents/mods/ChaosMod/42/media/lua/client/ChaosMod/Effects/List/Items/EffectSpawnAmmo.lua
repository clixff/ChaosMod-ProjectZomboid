EffectSpawnAmmo = ChaosEffectBase:derive("EffectSpawnAmmo", "spawn_ammo")


local AMMO_ITEM_IDS = {
    "Base.3030Box",
    "Base.Bullets357Box",
    "Base.Bullets38Box",
    "Base.Bullets44Box",
    "Base.Bullets45Box",
    "Base.ShotgunShellsBox",
    "Base.556Box",
    "Base.308Box",
    "Base.Bullets9mmBox"
}

function EffectSpawnAmmo:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnAmmo] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    for _, ammoItemId in ipairs(AMMO_ITEM_IDS) do
        local x = ZombRandFloat(0.15, 0.85)
        local y = ZombRandFloat(0.15, 0.85)
        local z = 0.0
        square:AddWorldInventoryItem(ammoItemId, x, y, z)
    end
end
