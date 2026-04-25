EffectSpawnBarbell = ChaosEffectBase:derive("EffectSpawnBarbell", "spawn_barbell")

function EffectSpawnBarbell:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnBarbell] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local sq = player:getSquare()
    if not sq then return end

    local item = instanceItem("Base.BarBell")
    if not item then return end

    sq:AddWorldInventoryItem(item, 0.5, 0.5, 0)

    ChaosPlayer.SayLineNewItem(player, item)
end
