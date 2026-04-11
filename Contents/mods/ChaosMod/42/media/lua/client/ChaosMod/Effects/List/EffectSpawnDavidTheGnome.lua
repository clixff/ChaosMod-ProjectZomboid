EffectSpawnDavidTheGnome = ChaosEffectBase:derive("EffectSpawnDavidTheGnome", "spawn_david_the_gnome")

function EffectSpawnDavidTheGnome:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnDavidTheGnome] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, square:getZ(), 1, 4, 50, true, true, true)
    if not randomSquare then return end

    local objectName = "vegetation_ornamental_01_49"

    ChaosProps.SpawnProp(randomSquare, objectName)
end
