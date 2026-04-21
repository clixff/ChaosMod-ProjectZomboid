EffectSpawnCampfire = ChaosEffectBase:derive("EffectSpawnCampfire", "spawn_campfire")

function EffectSpawnCampfire:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 5, 50, true, true, false)
    if not square then return end

    ChaosProps.SpawnCampfire(square)
end
