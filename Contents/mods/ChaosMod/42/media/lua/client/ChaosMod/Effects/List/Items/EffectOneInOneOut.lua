---@class EffectOneInOneOut : ChaosEffectBase
EffectOneInOneOut = ChaosEffectBase:derive("EffectOneInOneOut", "one_in_one_out")

function EffectOneInOneOut:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectOneInOneOut] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    ChaosUtils.RemoveRandomItem(player)

    local inventory = player:getInventory()
    if not inventory then return end

    local itemType = ChaosItems.GetRandomItemId()
    if not itemType then return end
    print("[EffectOneInOneOut] Giving item: " .. itemType)

    local newItem = inventory:AddItem(itemType)
    if newItem then
        ChaosPlayer.SayLineNewItem(player, newItem)
    end
end
