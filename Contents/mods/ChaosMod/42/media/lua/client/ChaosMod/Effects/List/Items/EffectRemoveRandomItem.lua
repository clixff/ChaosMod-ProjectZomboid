---@class EffectRemoveRandomItem : ChaosEffectBase
EffectRemoveRandomItem = ChaosEffectBase:derive("EffectRemoveRandomItem", "remove_random_item")

function EffectRemoveRandomItem:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemoveRandomItem] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end
    ChaosUtils.RemoveRandomItem(player)
end
