EffectSetRandomOutfit = ChaosEffectBase:derive("EffectSetRandomOutfit", "set_random_outfit")

function EffectSetRandomOutfit:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSetRandomOutfit] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    ChaosPlayer.DropAllItemsOnGround(player, true)
    player:dressInRandomOutfit()

    player:resetModelNextFrame()
end
