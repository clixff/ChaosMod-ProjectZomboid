---@class EffectSpawnExplosionChicken : ChaosEffectBase
---@field chicken IsoAnimal?
EffectSpawnExplosionChicken = ChaosEffectBase:derive("EffectSpawnExplosionChicken", "spawn_explosion_chicken")

function EffectSpawnExplosionChicken:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()

    self.chicken = ChaosAnimals.SpawnAnimal(x, y, z, "hen", "rhodeisland")
    print("[EffectSpawnExplosionChicken] Spawned chicken")
end

function EffectSpawnExplosionChicken:OnEnd()
    ChaosEffectBase:OnEnd()
    if not self.chicken then return end

    if not self.chicken:isAlive() then return end

    local square = self.chicken:getSquare()
    if not square then return end

    ChaosUtils.TriggerExplosionAt(square, 5)
    print("[EffectSpawnExplosionChicken] Chicken exploded")
end
