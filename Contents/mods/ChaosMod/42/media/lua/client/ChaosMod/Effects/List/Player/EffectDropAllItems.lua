EffectDropAllItems = ChaosEffectBase:derive("EffectDropAllItems", "drop_all_items")

function EffectDropAllItems:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    ChaosPlayer.DropAllItemsOnGround(player, true)
end
