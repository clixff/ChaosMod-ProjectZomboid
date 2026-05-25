---@class EffectRemoveAllPositiveTraits : ChaosEffectBase
EffectRemoveAllPositiveTraits = ChaosEffectBase:derive("EffectRemoveAllPositiveTraits", "remove_all_positive_traits")

function EffectRemoveAllPositiveTraits:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local removed = ChaosTraits.RemoveAllPositiveTraits(player)
    if removed <= 0 then return end

    local text = string.format(ChaosLocalization.GetString("misc", "traits_removed_count"), removed)
    ChaosPlayer.SayLineByColor(player, text, ChaosPlayerChatColors.red)
end
