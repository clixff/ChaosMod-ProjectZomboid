EffectDropItemInHand = ChaosEffectBase:derive("EffectDropItemInHand", "drop_item_in_hand")

function EffectDropItemInHand:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectDropItemInHand] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local primary = player:getPrimaryHandItem()
    local secondary = player:getSecondaryHandItem()

    if not primary and not secondary then
        ChaosPlayer.SayLine(player, ChaosLocalization.GetString("misc", "nothing_in_hands"), 1.0, 0.5, 0.0)
        return
    end

    player:dropHandItems()

    if primary then
        local name = primary:getDisplayName()
        local imgCode = ChaosUtils.GetImgCodeByItemTexture(primary)
        local str = string.format(ChaosLocalization.GetString("misc", "dropped_item"), imgCode, name)
        ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.removedItem)
    end
end
