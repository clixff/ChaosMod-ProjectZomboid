EffectExplodeNearestZombie = ChaosEffectBase:derive("EffectExplodeNearestZombie", "explode_nearest_zombie")

function EffectExplodeNearestZombie:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local zombie = ChaosZombie.GetNearestZombie(player:getX(), player:getY(), true)
    if not zombie then return end

    local square = zombie:getSquare()
    if not square then return end

    ChaosUtils.TriggerExplosionAt(square, 5)
end
